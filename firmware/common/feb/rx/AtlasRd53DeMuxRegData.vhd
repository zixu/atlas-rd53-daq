-------------------------------------------------------------------------------
-- File       : AtlasRd53DeMuxRegData.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-05-24
-- Last update: 2018-05-25
-------------------------------------------------------------------------------
-- Description: Demux the auto-reg, RdReg and data paths 
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
use work.AxiStreamPkg.all;
use work.Pgp3Pkg.all;
use work.SsiPkg.all;
use work.AtlasRd53Pkg.all;

entity AtlasRd53DeMuxRegData is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- RX Interface (clk80MHz domain)
      clk80MHz    : in  sl;
      rst80MHz    : in  sl;
      rxIn        : in  AtlasRD53DataType;  -- Reg/Data
      rxOut       : out AtlasRD53DataType;  -- Data only
      -- Outbound Reg only Interface (axilClk domain)
      axilClk     : in  sl;
      axilRst     : in  sl;
      autoReadReg : out Slv32Array(3 downto 0);
      cmdDrop     : out sl;
      mCmdMaster  : out AxiStreamMasterType;
      mCmdSlave   : in  AxiStreamSlaveType);
end AtlasRd53DeMuxRegData;

architecture mapping of AtlasRd53DeMuxRegData is

   type RegType is record
      rxOut       : AtlasRD53DataType;
      cmdDrop     : sl;
      autoReadReg : Slv32Array(3 downto 0);
      txMaster    : AxiStreamMasterType;
   end record RegType;
   constant REG_INIT_C : RegType := (
      rxOut       => RD53_FEB_DATA_INIT_C,
      cmdDrop     => '0',
      autoReadReg => (others => (others => '0')),
      txMaster    => AXI_STREAM_MASTER_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal txSlave : AxiStreamSlaveType;

begin

   comb : process (r, rst80MHz, rxIn, txSlave) is
      variable v      : RegType;
      variable i      : natural;
      variable opCode : Slv8Array(3 downto 0);

      procedure fwdRdReg is
      begin
         -- Check if ready to move data
         if (v.txMaster.tValid = '0') then
            -- Move the data
            v.txMaster.tValid             := '1';
            v.txMaster.tData(63 downto 0) := rxIn.data(0);  -- only lane[0] has RdReg command read back
            -- Set the End of Frame (EOF) flag
            v.txMaster.tLast              := '1';
            -- Set Start of Frame (SOF) flag
            ssiSetUserSof(PGP3_AXIS_CONFIG_C, v.txMaster, '1');
         else
            -- Debug flag (should never toggle unless back pressure)
            v.cmdDrop := '1';
         end if;
      end procedure fwdRdReg;

   begin
      -- Latch the current value
      v := r;

      -- Reset the flags
      v.cmdDrop := '0';
      if (txSlave.tReady = '1') then
         v.txMaster.tValid := '0';
      end if;

      -- Update the metadata field
      for i in 3 downto 0 loop
         opCode(i) := rxIn.data(i)(63 downto 56);
      end loop;

      -- Register the bus
      v.rxOut := rxIn;

      --  Check for valid
      if (rxIn.valid = '1') then
         -- Loop through the lanes
         for i in 3 downto 0 loop
            -- check for not Aurora data 
            if (rxIn.sync(i) = "10") then
               -- Both register fields are of type AutoRead
               if (opCode(i) = x"B4") then
                  v.autoReadReg(i)(15 downto 0)  := rxIn.data(i)(15 downto 0);
                  v.autoReadReg(i)(31 downto 16) := rxIn.data(i)(41 downto 26);
               -- First frame is AutoRead, second is from a read register command
               elsif (opCode(i) = x"55") then
                  v.autoReadReg(i)(15 downto 0) := rxIn.data(i)(15 downto 0);
                  -- Check if lane[0] (see note below)
                  if (i = 0) then
                     fwdRdReg;
                  end if;
               -- First is from a read register command, second frame is AutoRead
               elsif (opCode(i) = x"99") then
                  v.autoReadReg(i)(31 downto 16) := rxIn.data(i)(41 downto 26);
                  -- Check if lane[0] (see note below)
                  if (i = 0) then
                     fwdRdReg;
                  end if;
               -- Both register fields are from read register commands
               elsif (opCode(i) = x"D2") then
                  -- Check if lane[0] (see note below)
                  if (i = 0) then
                     fwdRdReg;
                  end if;
               end if;
            end if;
         end loop;
      ------------------------------------------------------
      --                 Note                             --
      ------------------------------------------------------
      -- "Lanes 1 to 3 are unaffected by the RdReg command 
      -- and only output their assigned auto-fill registers"
      -- So we only check lane[0] for RdReg command read back
      ------------------------------------------------------
      end if;

      -- Outputs
      rxOut <= r.rxOut;

      -- Reset
      if (rst80MHz = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (clk80MHz) is
   begin
      if rising_edge(clk80MHz) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_cmdDrop : entity work.SynchronizerOneShot
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => axilClk,
         dataIn  => r.cmdDrop,
         dataOut => cmdDrop);

   GEN_LANE : for i in 3 downto 0 generate

      U_autoReadReg : entity work.SynchronizerFifo
         generic map (
            TPD_G        => TPD_G,
            DATA_WIDTH_G => 32)
         port map (
            wr_clk => clk80MHz,
            din    => r.autoReadReg(i),
            rd_clk => axilClk,
            dout   => autoReadReg(i));

   end generate GEN_LANE;

   U_RdRegFifo : entity work.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 1,
         -- FIFO configurations
         BRAM_EN_G           => true,
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 9,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => PGP3_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => PGP3_AXIS_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => clk80MHz,
         sAxisRst    => rst80MHz,
         sAxisMaster => r.txMaster,
         sAxisSlave  => txSlave,
         -- Master Port
         mAxisClk    => axilClk,
         mAxisRst    => axilRst,
         mAxisMaster => mCmdMaster,
         mAxisSlave  => mCmdSlave);

end mapping;
