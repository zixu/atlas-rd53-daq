-------------------------------------------------------------------------------
-- File       : AtlasRd53EmuTrigTiming.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-18
-- Last update: 2018-08-21
-------------------------------------------------------------------------------
-- Description: Hit/Trig Module
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
use work.AtlasRd53Pkg.all;

entity AtlasRd53EmuTrigTiming is
   generic (
      TPD_G        : time     := 1 ns;
      ADDR_WIDTH_G : positive := 10);
   port (
      -- Clock and reset
      clk             : in  sl;
      rst             : in  sl;
      -- AXI-Lite Interface
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- RAM Interface
      ramAddr         : out slv(ADDR_WIDTH_G-1 downto 0);
      ramData         : in  Slv32Array(1 downto 0);
      -- Timing/Trigger Interface
      ttc             : out AtlasRd53TimingTrigType);
end AtlasRd53EmuTrigTiming;

architecture mapping of AtlasRd53EmuTrigTiming is

   type StateType is (
      IDLE_S,
      RUN_S);

   type RegType is record
      oneShot        : sl;
      start          : sl;
      stop           : sl;
      continuous     : sl;
      ramAddr        : slv(ADDR_WIDTH_G-1 downto 0);
      maxAddr        : slv(ADDR_WIDTH_G-1 downto 0);
      iteration      : slv(15 downto 0);
      loopCnt        : slv(15 downto 0);
      ttc            : AtlasRd53TimingTrigType;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
      state          : StateType;
   end record;

   constant REG_INIT_C : RegType := (
      oneShot        => '0',
      start          => '0',
      stop           => '0',
      continuous     => '0',
      ramAddr        => (others => '0'),
      maxAddr        => (others => '0'),
      iteration      => (others => '0'),
      loopCnt        => (others => '0'),
      ttc            => RD53_FEB_TIMING_TRIG_INIT_C,
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
      state          => IDLE_S);
      
   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;      

begin

   comb : process (axilReadMaster, axilWriteMaster, r, ramData, rst) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Reset the strobes
      v.oneShot := '0';
      v.start   := '0';
      v.stop    := '0';

      -- Determine the transaction type
      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegister(axilEp, x"00", 0, v.oneShot);
      axiSlaveRegister(axilEp, x"04", 0, v.continuous);
      axiSlaveRegister(axilEp, x"08", 0, v.maxAddr);
      axiSlaveRegister(axilEp, x"0C", 0, v.iteration);

      -- Closeout the transaction
      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      -- Check for start conditions
      if (r.continuous = '0') and (v.continuous = '1') then
         v.start := '1';
      end if;

      -- Check for stop conditions
      if (r.continuous = '1') and (v.continuous = '0') then
         v.stop := '1';
      end if;

      ----------------------------------------
      -- Map the RAM bus to timing/trigger bus
      ----------------------------------------
      -- Timing/Trigger Interface
      v.ttc.trig       := ramData(1)(11);
      v.ttc.ecr        := ramData(1)(10);
      v.ttc.bcr        := ramData(1)(9);
      -- Global Pulse Interface
      v.ttc.gPulse     := ramData(1)(8);
      v.ttc.gPulseId   := ramData(1)(7 downto 4);
      v.ttc.gPulseData := ramData(1)(3 downto 0);
      -- Calibration Interface
      v.ttc.cal        := ramData(0)(20);
      v.ttc.calId      := ramData(0)(19 downto 16);
      v.ttc.calDat     := ramData(0)(15 downto 0);

      -- State Machine
      case (r.state) is
         ----------------------------------------------------------------------   
         when IDLE_S =>
            -- Reset the buses
            v.ttc     := RD53_FEB_TIMING_TRIG_INIT_C;
            v.ramAddr := (others => '0');
            v.loopCnt := (others => '0');
            -- Check for start
            if (r.start = '1') or (r.oneShot = '1') then
               -- Next state
               v.state := RUN_S;
            end if;
         ----------------------------------------------------------------------
         when RUN_S =>
            -- Check max ram address
            if (r.ramAddr = r.maxAddr) then
               -- Reset the address bus 
               v.ramAddr := (others => '0');
               -- Check if not continuous mode
               if (r.continuous = '0') then
                  -- Check if max one-shot iteration count
                  if (r.loopCnt = r.iteration) then
                     -- Reset the address bus 
                     v.loopCnt := (others => '0');
                     -- Next state
                     v.state   := IDLE_S;
                  else
                     -- Increment the counter
                     v.loopCnt := r.loopCnt + 1;
                  end if;
               end if;
            else
               -- Increment the counter
               v.ramAddr := r.ramAddr + 1;
            end if;
            -- Check for stop
            if r.stop = '1' then
               -- Next state
               v.state := IDLE_S;
            end if;
      ----------------------------------------------------------------------
      end case;

      -- Combinatorial Outputs
      ramAddr <= v.ramAddr;

      -- Synchronous Reset
      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Registered Outputs
      axilWriteSlave <= r.axilWriteSlave;
      axilReadSlave  <= r.axilReadSlave;
      ttc            <= r.ttc;

   end process comb;

   seq : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end mapping;
