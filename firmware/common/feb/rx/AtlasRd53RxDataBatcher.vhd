-------------------------------------------------------------------------------
-- File       : AtlasRd53RxDataBatcher.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-05-25
-- Last update: 2018-05-25
-------------------------------------------------------------------------------
-- Description: Data Batcher Module
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
use work.SsiPkg.all;
use work.Pgp3Pkg.all;

entity AtlasRd53RxDataBatcher is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Clock and Reset
      axilClk     : in  sl;
      axilRst     : in  sl;
      -- Configuration/Status Interface
      batchSize   : in  slv(15 downto 0);
      timerConfig : in  slv(15 downto 0);
      timedOut    : out sl;
      -- AXI Streaming Interface
      sDataMaster : in  AxiStreamMasterType;
      sDataSlave  : out AxiStreamSlaveType;
      mDataMaster : out AxiStreamMasterType;
      mDataSlave  : in  AxiStreamSlaveType);
end AtlasRd53RxDataBatcher;

architecture rtl of AtlasRd53RxDataBatcher is

   type StateType is (
      IDLE_S,
      MOVE_S);

   type RegType is record
      timedOut     : sl;
      batchSize    : slv(15 downto 0);
      timerConfig  : slv(15 downto 0);
      timer        : slv(15 downto 0);
      wordCnt      : slv(15 downto 0);
      sDataSlave   : AxiStreamSlaveType;
      mDataMasters : AxiStreamMasterArray(1 downto 0);
      state        : StateType;
   end record RegType;
   constant REG_INIT_C : RegType := (
      timedOut     => '0',
      batchSize    => (others => '0'),
      timerConfig  => (others => '0'),
      timer        => (others => '0'),
      wordCnt      => x"0001",
      sDataSlave   => AXI_STREAM_SLAVE_INIT_C,
      mDataMasters => (others => AXI_STREAM_MASTER_INIT_C),
      state        => IDLE_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   comb : process (axilRst, batchSize, mDataSlave, r, sDataMaster, timerConfig) is
      variable v : RegType;
      variable i : natural;
   begin
      -- Latch the current value
      v := r;

      -- Reset the flags
      v.timedOut   := '0';
      v.sDataSlave := AXI_STREAM_SLAVE_INIT_C;
      if mDataSlave.tReady = '1' then
         v.mDataMasters(1).tValid := '0';
         v.mDataMasters(0).tValid := '0';
      end if;

      -- State Machine
      case r.state is
         ----------------------------------------------------------------------
         when IDLE_S =>
            -- Reset the timer
            v.timer       := (others => '0');
            -- Pre-set the counter
            v.wordCnt     := x"0001";
            -- Save the configuration values
            v.batchSize   := batchSize;
            v.timerConfig := timerConfig;
            -- Advance the output pipeline
            if (v.mDataMasters(0).tValid = '0') and (r.mDataMasters(1).tValid = '1') then
               v.mDataMasters(0) := r.mDataMasters(1);
            end if;
            -- Check if ready to move data
            if (sDataMaster.tValid = '1') and (v.mDataMasters(1).tValid = '0') then
               -- Accept the data
               v.sDataSlave.tready      := '1';
               -- Move the data
               v.mDataMasters(1).tValid := '1';
               v.mDataMasters(1).tData  := sDataMaster.tData;
               v.mDataMasters(1).tLast  := '0';
               v.mDataMasters(1).tUser  := (others => '0');
               -- Set Start of Frame (SOF) flag
               ssiSetUserSof(PGP3_AXIS_CONFIG_C, v.mDataMasters(1), '1');
               -- Check for min. batch size
               if (batchSize = 0) then
                  -- Set the End of Frame (EOF) flag
                  v.mDataMasters(1).tLast := '1';
               else
                  -- Next state
                  v.state := MOVE_S;
               end if;
            end if;
         ----------------------------------------------------------------------
         when MOVE_S =>
            -- Increment the timer
            if (r.timer /= r.timerConfig) then
               v.timer := r.timer + 1;
            end if;
            -- Keep the caches copy
            v.mDataMasters(1).tvalid := r.mDataMasters(1).tvalid;
            -- Check if ready to move data
            if (sDataMaster.tValid = '1') and (v.mDataMasters(0).tValid = '0') then
               -- Accept the data 
               v.sDataSlave.tready      := '1';
               -- Advance the pipeline
               v.mDataMasters(1).tValid := '1';
               v.mDataMasters(1).tData  := sDataMaster.tData;
               v.mDataMasters(1).tUser  := (others => '0');
               v.mDataMasters(0)        := r.mDataMasters(1);
               -- Increment the word counter
               v.wordCnt                := r.wordCnt + 1;
               -- Check for last transfer
               if (r.wordCnt = r.batchSize) or (r.timer = r.timerConfig) then
                  -- Set the End of Frame (EOF) flag
                  v.mDataMasters(1).tLast := '1';
                  -- Check for timeout
                  if (r.timer = r.timerConfig) then
                     -- Set the debug flag
                     v.timedOut := '1';
                  end if;
                  -- Next state
                  v.state := IDLE_S;
               end if;
            -- Check for timeout
            elsif (r.timer = r.timerConfig) and (v.mDataMasters(0).tValid = '0') then
               -- Set the debug flag
               v.timedOut               := '1';
               -- Push the cached value into the output
               v.mDataMasters(1).tvalid := '0';
               v.mDataMasters(0)        := r.mDataMasters(1);
               -- Set the End of Frame (EOF) flag to the output
               v.mDataMasters(0).tLast  := '1';
               -- Next state
               v.state                  := IDLE_S;
            end if;
      ----------------------------------------------------------------------
      end case;

      -- Outputs
      sDataSlave  <= v.sDataSlave;
      mDataMaster <= r.mDataMasters(0);
      timedOut    <= r.timedOut;

      -- Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (axilClk) is
   begin
      if rising_edge(axilClk) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
