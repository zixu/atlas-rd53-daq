-------------------------------------------------------------------------------
-- File       : AtlasRd53TxCmdWrapper.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-05-31
-- Last update: 2018-07-30
-------------------------------------------------------------------------------
-- Description: Wrapper for AtlasRd53TxCmd
-------------------------------------------------------------------------------
-- This file is part of 'ATLAS RD53 DEV'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'ATLAS RD53 DEV', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.Pgp3Pkg.all;
use work.AtlasRd53Pkg.all;

library unisim;
use unisim.vcomponents.all;

entity AtlasRd53TxCmdWrapper is
   generic (
      TPD_G        : time   := 1 ns;
      SYNTH_MODE_G : string := "inferred");
   port (
      -- AXI Stream Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Streaming RD53 Config Interface (clk160MHz domain)
      sConfigMaster   : in  AxiStreamMasterType;
      sConfigSlave    : out AxiStreamSlaveType;
      mConfigMaster   : out AxiStreamMasterType;
      mConfigSlave    : in  AxiStreamSlaveType;
      -- Timing Interface (clk160MHz domain)
      clk160MHz       : in  sl;
      rst160MHz       : in  sl;
      ttc             : in  AtlasRd53TimingTrigType;
      -- Read Back Register Interface (clk160MHz domain)
      rdReg           : in  AxiStreamMasterType;
      -- Command Serial Interface (clk160MHz domain)
      invCmd          : in  sl;
      cmdOut          : out sl;         -- Copy of CMD for local emulation
      cmdOutP         : out sl;
      cmdOutN         : out sl);
end entity AtlasRd53TxCmdWrapper;

architecture rtl of AtlasRd53TxCmdWrapper is

   type StateType is (
      IDLE_S,
      DOUBLE_WD_S);

   type RegType is record
      wrValid       : sl;
      wrRegId       : slv(3 downto 0);
      wrRegAddr     : slv(8 downto 0);
      wrRegData     : slv(15 downto 0);
      rdValid       : sl;
      rdRegId       : slv(3 downto 0);
      rdRegAddr     : slv(8 downto 0);
      ramWr         : sl;
      ramAddr       : slv(9 downto 0);
      ramDin        : slv(15 downto 0);
      mConfigMaster : AxiStreamMasterType;
      sConfigSlave  : AxiStreamSlaveType;
      rdRegSlave    : AxiStreamSlaveType;
      axiWriteSlave : AxiLiteWriteSlaveType;
      axiReadSlave  : AxiLiteReadSlaveType;
      rdLatecy      : natural range 0 to 3;
      state         : StateType;
   end record;

   constant REG_INIT_C : RegType := (
      wrValid       => '0',
      wrRegId       => (others => '0'),
      wrRegAddr     => (others => '0'),
      wrRegData     => (others => '0'),
      rdValid       => '0',
      rdRegId       => (others => '0'),
      rdRegAddr     => (others => '0'),
      ramWr         => '0',
      ramAddr       => (others => '0'),
      ramDin        => (others => '0'),
      mConfigMaster => AXI_STREAM_MASTER_INIT_C,
      sConfigSlave  => AXI_STREAM_SLAVE_INIT_C,
      rdRegSlave    => AXI_STREAM_SLAVE_INIT_C,
      axiWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
      axiReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      rdLatecy      => 0,
      state         => IDLE_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal axiWriteMaster : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
   signal axiWriteSlave  : AxiLiteWriteSlaveType  := AXI_LITE_WRITE_SLAVE_INIT_C;
   signal axiReadMaster  : AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
   signal axiReadSlave   : AxiLiteReadSlaveType   := AXI_LITE_READ_SLAVE_INIT_C;

   signal rdRegMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal rdRegSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;

   signal ramDout : slv(15 downto 0);

   signal wrReady : sl;
   signal rdReady : sl;

   signal cmd     : sl;
   signal cmdMask : sl;
   signal cmdReg  : sl;

begin

   ------------------------------------------
   -- Synchronize to Application Clock Domain
   ------------------------------------------
   U_AxiLiteAsync : entity work.AxiLiteAsync
      generic map (
         TPD_G           => TPD_G,
         COMMON_CLK_G    => false,
         SYNTH_MODE_G    => SYNTH_MODE_G,
         NUM_ADDR_BITS_G => 16)
      port map (
         -- Slave Interface
         sAxiClk         => axilClk,
         sAxiClkRst      => axilRst,
         sAxiReadMaster  => axilReadMaster,
         sAxiReadSlave   => axilReadSlave,
         sAxiWriteMaster => axilWriteMaster,
         sAxiWriteSlave  => axilWriteSlave,
         -- Master Interface
         mAxiClk         => clk160MHz,
         mAxiClkRst      => rst160MHz,
         mAxiReadMaster  => axiReadMaster,
         mAxiReadSlave   => axiReadSlave,
         mAxiWriteMaster => axiWriteMaster,
         mAxiWriteSlave  => axiWriteSlave);

   ---------------------
   -- CMD Serializer FSM
   ---------------------
   U_Cmd : entity work.AtlasRd53TxCmd
      generic map (
         TPD_G => TPD_G)
      port map (
         -- Clock and Reset
         clk160MHz  => clk160MHz,
         rst160MHz  => rst160MHz,
         -- Timing/Trigger Interface
         trig       => ttc.trig,
         ecr        => ttc.ecr,
         bcr        => ttc.bcr,
         -- Global Pulse Interface
         gPulse     => ttc.gPulse,
         gPulseId   => ttc.gPulseId,
         gPulseData => ttc.gPulseData,
         -- Calibration Interface
         cal        => ttc.cal,
         calId      => ttc.calId,
         calDat     => ttc.calDat,
         -- Write Register Interface
         wrValid    => r.wrValid,
         wrReady    => wrReady,
         wrRegId    => r.wrRegId,
         wrRegAddr  => r.wrRegAddr,
         wrRegData  => r.wrRegData,
         -- Read Register Interface
         rdValid    => r.rdValid,
         rdReady    => rdReady,
         rdRegId    => r.rdRegId,
         rdRegAddr  => r.rdRegAddr,
         -- Serial Output Interface
         cmdOut     => cmd);

   cmdOut <= cmd;

   cmdMask <= cmd xor invCmd;

   U_ODDR : ODDR
      generic map(
         DDR_CLK_EDGE => "OPPOSITE_EDGE",  -- "OPPOSITE_EDGE" or "SAME_EDGE" 
         INIT         => '0',  -- Initial value for Q port ('1' or '0')
         SRTYPE       => "SYNC")        -- Reset Type ("ASYNC" or "SYNC")
      port map (
         D1 => cmdMask,                 -- 1-bit data input (positive edge)
         D2 => cmdMask,                 -- 1-bit data input (negative edge)
         Q  => cmdReg,                  -- 1-bit DDR output
         C  => clk160MHz,               -- 1-bit clock input
         CE => '1',                     -- 1-bit clock enable input
         R  => rst160MHz,               -- 1-bit reset
         S  => '0');                    -- 1-bit set

   U_dPortCmd : OBUFDS
      port map (
         I  => cmdReg,
         O  => cmdOutP,
         OB => cmdOutN);

   comb : process (axiReadMaster, axiWriteMaster, mConfigSlave, r, ramDout,
                   rdReady, rdRegMaster, rst160MHz, sConfigMaster, wrReady) is
      variable v          : RegType;
      variable axiStatus  : AxiLiteStatusType;
      variable decAddrInt : integer;
   begin
      -- Latch the current value
      v := r;

      -- Reset the strobes
      v.ramWr               := '0';
      v.rdRegSlave.tReady   := '0';
      v.sConfigSlave.tReady := '0';
      if (wrReady = '1') then
         v.wrValid := '0';
      end if;
      if (rdReady = '1') then
         v.rdValid := '0';
      end if;
      if (mConfigSlave.tReady = '1') then
         v.mConfigMaster.tValid := '0';
      end if;

      -- Check for AXI stream transaction
      if (sConfigMaster.tValid = '1') and (v.mConfigMaster.tValid = '0') and (v.wrValid = '0') then
         -- Accept the data 
         v.sConfigSlave.tReady := '1';
         -- Write data to the CMD sequencer 
         v.wrValid             := '1';
         v.wrRegId             := sConfigMaster.tData(28 downto 25);
         v.wrRegAddr           := sConfigMaster.tData(24 downto 16);
         v.wrRegData           := sConfigMaster.tData(15 downto 0);
         -- Echo back the data
         v.mConfigMaster       := sConfigMaster;
      end if;

      -- Determine the transaction type
      axiSlaveWaitTxn(axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave, axiStatus);

      -- Check for write transaction
      if (axiStatus.writeEnable = '1') and (v.wrValid = '0') and (v.rdValid = '0') then
         -- Check for R/nW op-code
         if(axiWriteMaster.wdata(31) = '0') then
            v.wrValid   := '1';
            v.wrRegId   := axiWriteMaster.awaddr(14 downto 11);
            v.wrRegAddr := axiWriteMaster.awaddr(10 downto 2);
            v.wrRegData := axiWriteMaster.wdata(15 downto 0);
         else
            v.rdValid   := '1';
            v.rdRegId   := axiWriteMaster.awaddr(14 downto 11);
            v.rdRegAddr := axiWriteMaster.awaddr(10 downto 2);
         end if;
         -- Send Write bus response
         axiSlaveWriteResponse(v.axiWriteSlave, AXI_RESP_OK_C);
      end if;

      -- Check for read transaction
      v.axiReadSlave.rdata := x"0000" & ramDout;
      if (axiStatus.readEnable = '1') then
         -- Wait for the read transaction
         if (r.rdLatecy = 2) then       -- read in 3 cycles for registered BRAM
            -- Send the read response
            axiSlaveReadResponse(v.axiReadSlave, AXI_RESP_OK_C);
         else
            -- Increment the counter
            v.rdLatecy := r.rdLatecy + 1;
         end if;
      else
         v.rdLatecy := 0;
      end if;

      -- State Machine
      case (r.state) is
         ----------------------------------------------------------------------   
         when IDLE_S =>
            -- Check for data
            if (rdRegMaster.tValid = '1') then
               -- Accept the data by default
               v.rdRegSlave.tReady := '1';
               -- Check if first frame is AutoRead, second is from a read register command
               if (rdRegMaster.tData(63 downto 56) = x"55") then
                  -- Write the data to RAM
                  v.ramWr   := '1';
                  v.ramAddr := rdRegMaster.tData(51 downto 42);
                  v.ramDin  := rdRegMaster.tData(41 downto 26);
               -- Check if first is from a read register command, second frame is AutoRead
               elsif (rdRegMaster.tData(63 downto 56) = x"99") then
                  -- Write the data to RAM
                  v.ramWr   := '1';
                  v.ramAddr := rdRegMaster.tData(25 downto 16);
                  v.ramDin  := rdRegMaster.tData(15 downto 0);
               -- Check if both register fields are from read register commands
               elsif (rdRegMaster.tData(63 downto 56) = x"D2") then
                  -- Write the data to RAM
                  v.ramWr             := '1';
                  v.ramAddr           := rdRegMaster.tData(25 downto 16);
                  v.ramDin            := rdRegMaster.tData(15 downto 0);
                  -- Hold off accepting data until next state
                  v.rdRegSlave.tReady := '0';
                  -- Next state
                  v.state             := DOUBLE_WD_S;
               end if;
            end if;
         ----------------------------------------------------------------------
         when DOUBLE_WD_S =>
            -- Accept the data
            v.rdRegSlave.tReady := '1';
            -- Write the data to RAM
            v.ramWr             := '1';
            v.ramAddr           := rdRegMaster.tData(51 downto 42);
            v.ramDin            := rdRegMaster.tData(41 downto 26);
            -- Next state
            v.state             := IDLE_S;
      ----------------------------------------------------------------------
      end case;

      -- Combinatorial Outputs
      rdRegSlave   <= v.rdRegSlave;
      sConfigSlave <= v.sConfigSlave;

      -- Reset
      if (rst160MHz = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Registered Outputs
      axiReadSlave  <= r.axiReadSlave;
      axiWriteSlave <= r.axiWriteSlave;
      mConfigMaster <= r.mConfigMaster;

   end process comb;

   seq : process (clk160MHz) is
   begin
      if (rising_edge(clk160MHz)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_SyncAxis : entity work.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => false,
         VALID_THOLD_G       => 1,
         -- FIFO configurations
         SYNTH_MODE_G        => SYNTH_MODE_G,
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => true,
         FIFO_ADDR_WIDTH_G   => 9,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => PGP3_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => PGP3_AXIS_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => clk160MHz,
         sAxisRst    => rst160MHz,
         sAxisMaster => rdReg,
         -- Master Port
         mAxisClk    => clk160MHz,
         mAxisRst    => rst160MHz,
         mAxisMaster => rdRegMaster,
         mAxisSlave  => rdRegSlave);

   U_RdBackRam : entity work.SimpleDualPortRam
      generic map (
         TPD_G         => TPD_G,
         MEMORY_TYPE_G => "block",
         DOB_REG_G     => true,
         DATA_WIDTH_G  => 16,
         ADDR_WIDTH_G  => 10)
      port map (
         -- Port A     
         clka  => clk160MHz,
         wea   => r.ramWr,
         addra => r.ramAddr,
         dina  => r.ramDin,
         -- Port B
         clkb  => clk160MHz,
         addrb => axiReadMaster.araddr(11 downto 2),
         doutb => ramDout);

end rtl;
