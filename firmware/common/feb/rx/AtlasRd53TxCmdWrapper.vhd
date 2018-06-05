-------------------------------------------------------------------------------
-- File       : AtlasRd53TxCmdWrapper.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-05-31
-- Last update: 2018-06-04
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
      TPD_G : time := 1 ns);
   port (
      -- AXI Stream Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Timing Interface (clk160MHz domain)
      clk160MHz       : in  sl;
      rst160MHz       : in  sl;
      ttc             : in  AtlasRd53TimingTrigType;
      -- Read Back Register Interface (clk160MHz domain)
      rdReg           : in  AxiStreamMasterType;
      -- Command Serial Interface (clk160MHz domain)
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
      rdValid       : sl;
      regId         : slv(3 downto 0);
      regAddr       : slv(8 downto 0);
      regData       : slv(15 downto 0);
      ramWr         : sl;
      ramAddr       : slv(9 downto 0);
      ramDin        : slv(15 downto 0);
      rdRegSlave    : AxiStreamSlaveType;
      axiWriteSlave : AxiLiteWriteSlaveType;
      axiReadSlave  : AxiLiteReadSlaveType;
      rdLatecy      : natural range 0 to 3;
      state         : StateType;
   end record;

   constant REG_INIT_C : RegType := (
      wrValid       => '0',
      rdValid       => '0',
      regId         => (others => '0'),
      regAddr       => (others => '0'),
      regData       => (others => '0'),
      ramWr         => '0',
      ramAddr       => (others => '0'),
      ramDin        => (others => '0'),
      rdRegSlave    => AXI_STREAM_SLAVE_INIT_C,
      axiWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
      axiReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      rdLatecy      => 0,
      state         => IDLE_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal axiWriteMaster : AxiLiteWriteMasterType;
   signal axiWriteSlave  : AxiLiteWriteSlaveType;
   signal axiReadMaster  : AxiLiteReadMasterType;
   signal axiReadSlave   : AxiLiteReadSlaveType;

   signal rdRegMaster : AxiStreamMasterType;
   signal rdRegSlave  : AxiStreamSlaveType;

   signal ramDout : slv(15 downto 0);

   signal wrReady   : sl;
   signal wrValid   : sl;
   signal wrRdy     : sl;
   signal wrRegId   : slv(3 downto 0);
   signal wrRegAddr : slv(8 downto 0);
   signal wrRegData : slv(15 downto 0);

   signal rdReady : sl;
   signal cmd     : sl;
   signal cmdReg  : sl;

begin

   ------------------------------------------
   -- Synchronize to Application Clock Domain
   ------------------------------------------
   U_AxiLiteAsync : entity work.AxiLiteAsync
      generic map (
         TPD_G           => TPD_G,
         COMMON_CLK_G    => false,
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
         wrValid    => wrValid,
         wrReady    => wrRdy,
         wrRegId    => wrRegId,
         wrRegAddr  => wrRegAddr,
         wrRegData  => wrRegData,
         -- Read Register Interface
         rdValid    => r.rdValid,
         rdReady    => rdReady,
         rdRegId    => r.regId,
         rdRegAddr  => r.regAddr,
         -- Serial Output Interface
         cmdOut     => cmd);

   U_ODDR : ODDR
      generic map(
         DDR_CLK_EDGE => "OPPOSITE_EDGE",  -- "OPPOSITE_EDGE" or "SAME_EDGE" 
         INIT         => '0',  -- Initial value for Q port ('1' or '0')
         SRTYPE       => "SYNC")        -- Reset Type ("ASYNC" or "SYNC")
      port map (
         D1 => cmd,                     -- 1-bit data input (positive edge)
         D2 => cmd,                     -- 1-bit data input (negative edge)
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

   ----------------------------------
   -- Command Write Transaction Queue
   ----------------------------------
   U_WrFifo : entity work.FifoSync
      generic map (
         TPD_G        => TPD_G,
         BRAM_EN_G    => true,
         FWFT_EN_G    => true,
         DATA_WIDTH_G => 29,
         ADDR_WIDTH_G => 10)
      port map (
         clk                => clk160MHz,
         rst                => rst160MHz,
         -- Write interface
         wr_en              => r.wrValid,
         almost_full        => wrReady,
         din(28 downto 25)  => r.regId,
         din(24 downto 16)  => r.regAddr,
         din(15 downto 0)   => r.regData,
         -- Read interface
         valid              => wrValid,
         rd_en              => wrRdy,
         dout(28 downto 25) => wrRegId,
         dout(24 downto 16) => wrRegAddr,
         dout(15 downto 0)  => wrRegData);

   comb : process (axiReadMaster, axiWriteMaster, r, ramDout, rdReady,
                   rdRegMaster, rst160MHz, wrReady) is
      variable v          : RegType;
      variable axiStatus  : AxiLiteStatusType;
      variable decAddrInt : integer;
   begin
      -- Latch the current value
      v := r;

      -- Reset the strobes
      v.ramWr             := '0';
      v.rdRegSlave.tReady := '0';
      if (wrReady = '1') then
         v.wrValid := '0';
      end if;
      if (rdReady = '1') then
         v.rdValid := '0';
      end if;

      -- Determine the transaction type
      axiSlaveWaitTxn(axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave, axiStatus);

      -- Check for write transaction
      if (axiStatus.writeEnable = '1') and (r.wrValid = '0') and (r.rdValid = '0') then
         -- Check for standard memory mapped access
         if (axiWriteMaster.awaddr(15) = '0') then
            -- Update the data/address fields
            v.regId   := axiWriteMaster.awaddr(14 downto 11);
            v.regAddr := axiWriteMaster.awaddr(10 downto 2);
            v.regData := axiWriteMaster.wdata(15 downto 0);
         -- Encode the address into the data field
         else
            -- Update the data/address fields
            v.regId   := axiWriteMaster.wdata(28 downto 25);
            v.regAddr := axiWriteMaster.wdata(24 downto 16);
            v.regData := axiWriteMaster.wdata(15 downto 0);
         end if;
         -- Check for R/nW op-code
         if(axiWriteMaster.wdata(31) = '0') then
            v.rdValid := '1';
         else
            v.wrValid := '1';
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
      rdRegSlave <= v.rdRegSlave;

      -- Reset
      if (rst160MHz = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Registered Outputs
      axiReadSlave  <= r.axiReadSlave;
      axiWriteSlave <= r.axiWriteSlave;

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
         BRAM_EN_G           => true,
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
         TPD_G        => TPD_G,
         BRAM_EN_G    => true,
         DOB_REG_G    => true,
         DATA_WIDTH_G => 16,
         ADDR_WIDTH_G => 10)
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