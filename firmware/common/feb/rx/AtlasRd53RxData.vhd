-------------------------------------------------------------------------------
-- File       : AtlasRd53RxData.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-18
-- Last update: 2018-05-25
-------------------------------------------------------------------------------
-- Description: Converts RX data into AXI Stream
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

library unisim;
use unisim.vcomponents.all;

entity AtlasRd53RxData is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- RX Interface (clk80MHz domain)
      clk80MHz    : in  sl;
      rst80MHz    : in  sl;
      rx          : in  AtlasRD53DataType;
      -- Outbound Reg only Interface (axilClk domain)
      axilClk     : in  sl;
      axilRst     : in  sl;
      dataDrop    : out slv(3 downto 0);
      mDataMaster : out AxiStreamMasterType;
      mDataSlave  : in  AxiStreamSlaveType);
end AtlasRd53RxData;

architecture rtl of AtlasRd53RxData is

   type RegType is record
      dataDrop  : slv(3 downto 0);
      txMasters : AxiStreamMasterArray(3 downto 0);
   end record RegType;
   constant REG_INIT_C : RegType := (
      dataDrop  => (others => '0'),
      txMasters => (others => AXI_STREAM_MASTER_INIT_C));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal txSlaves : AxiStreamSlaveArray(3 downto 0);

   signal mDataMasters : AxiStreamMasterArray(3 downto 0);
   signal mDataSlaves  : AxiStreamSlaveArray(3 downto 0);

begin

   comb : process (r, rst80MHz, rx, txSlaves) is
      variable v : RegType;
      variable i : natural;
   begin
      -- Latch the current value
      v := r;

      for i in 3 downto 0 loop

         -- Reset the flags
         v.dataDrop(i) := '0';
         if (txSlaves(i).tReady = '1') then
            v.txMasters(i).tValid := '0';
         end if;

         --  Check for valid
         if (rx.valid = '1') then
            -- Check for Aurora data 
            if (rx.sync(i) = "01") or ((rx.sync(i) = "10") and (rx.data(i)(63 downto 32) = x"1E04_0000")) then
               -- Check if ready to move data
               if (v.txMasters(i).tValid = '0') then
                  -- Move the data
                  v.txMasters(i).tValid             := '1';
                  v.txMasters(i).tData(63 downto 0) := rx.data(i);
                  -- Set the End of Frame (EOF) flag
                  v.txMasters(i).tLast              := '1';
                  -- Set Start of Frame (SOF) flag
                  ssiSetUserSof(PGP3_AXIS_CONFIG_C, v.txMasters(i), '1');
                  -- Check if 64-bit transfer
                  if (rx.sync(i) = "01") then
                     -- Set the TKEEP for 64-bit transfer
                     v.txMasters(i).tKeep := x"00FF";
                  else
                     -- Set the TKEEP for 32-bit transfer
                     v.txMasters(i).tKeep := x"000F";
                  end if;
               else
                  -- Debug flag (should never toggle unless back pressure)
                  v.dataDrop(i) := '1';
               end if;
            end if;
         end if;

      end loop;

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

   GEN_LANE : for i in 3 downto 0 generate

      U_dataDrop : entity work.SynchronizerOneShot
         generic map (
            TPD_G => TPD_G)
         port map (
            clk     => axilClk,
            dataIn  => r.dataDrop(i),
            dataOut => dataDrop(i));

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
            SLAVE_AXI_CONFIG_G  => PGP3_AXIS_CONFIG_C,     -- 64-bit interface
            MASTER_AXI_CONFIG_G => BATCHER_AXIS_CONFIG_C)  -- 32-bit interface
         port map (
            -- Slave Port
            sAxisClk    => clk80MHz,
            sAxisRst    => rst80MHz,
            sAxisMaster => r.txMasters(i),
            sAxisSlave  => txSlaves(i),
            -- Master Port
            mAxisClk    => axilClk,
            mAxisRst    => axilRst,
            mAxisMaster => mDataMasters(i),
            mAxisSlave  => mDataSlaves(i));

   end generate GEN_LANE;

   --------------
   -- MUX Module
   --------------               
   U_Mux : entity work.AxiStreamMux
      generic map (
         TPD_G         => TPD_G,
         NUM_SLAVES_G  => 4,
         MODE_G        => "INDEXED",
         PIPE_STAGES_G => 1)
      port map (
         -- Clock and reset
         axisClk      => axilClk,
         axisRst      => axilRst,
         -- Slaves
         sAxisMasters => mDataMasters,
         sAxisSlaves  => mDataSlaves,
         -- Master
         mAxisMaster  => mDataMaster,
         mAxisSlave   => mDataSlave);

end rtl;
