-------------------------------------------------------------------------------
-- File       : AtlasRd53TxCmd.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-05-25
-- Last update: 2018-05-31
-------------------------------------------------------------------------------
-- Description: Module to generate CMD serial stream to RD53 ASIC
-- 
-- Note: 96-bit of WrReg data mode not supported
--
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

entity AtlasRd53TxCmd is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Clock and Reset
      clk160MHz  : in  sl;
      rst160MHz  : in  sl;
      -- Timing/Trigger Interface
      trig       : in  sl;
      ecr        : in  sl;
      bcr        : in  sl;
      -- Global Pulse Interface
      gPulse     : in  sl;
      gPulseId   : in  slv(3 downto 0);
      gPulseData : in  slv(3 downto 0);
      -- Calibration Interface
      cal        : in  sl;
      calId      : in  slv(3 downto 0);
      calDat     : in  slv(15 downto 0);
      -- Write Register Interface
      wrValid    : in  sl;
      wrReady    : out sl;
      wrRegId    : in  slv(3 downto 0);
      wrRegAddr  : in  slv(8 downto 0);
      wrRegData  : in  slv(15 downto 0);
      -- Read Register Interface
      rdValid    : in  sl;
      rdReady    : out sl;
      rdRegId    : in  slv(3 downto 0);
      rdRegAddr  : in  slv(8 downto 0);
      -- Serial Output Interface
      cmdOut     : out sl);
end AtlasRd53TxCmd;

architecture rtl of AtlasRd53TxCmd is

   constant ECR_C        : slv(15 downto 0) := b"0101_1010_0101_1010";
   constant BCR_C        : slv(15 downto 0) := b"0101_1001_0101_1001";
   constant GLOB_PULSE_C : slv(15 downto 0) := b"0101_1100_0101_1100";
   constant CAL_C        : slv(15 downto 0) := b"0110_0011_0110_0011";
   constant WR_REG_C     : slv(15 downto 0) := b"0110_0110_0110_0110";
   constant RD_REG_C     : slv(15 downto 0) := b"0110_0101_0110_0101";
   constant NOP_C        : slv(15 downto 0) := b"0110_1001_0110_1001";
   constant SYNC_C       : slv(15 downto 0) := b"1000_0001_0111_1110";
   constant FORCE_SYNC_C : slv(4 downto 0)  := toSlv(31, 5);  -- It is recommended that at lest one sync frame be inserted at least every 32 frames.

   constant TRIG_ROM_C : Slv8Array(0 to 15) := (
      0  => b"0000_0000",  -- Undefined (index zero required for inferring ROM)
      1  => b"0010_1011",               -- 000T
      2  => b"0010_1101",               -- 00T0
      3  => b"0010_1110",               -- 00TT
      4  => b"0011_0011",               -- 0T00
      5  => b"0011_0101",               -- 0T0T
      6  => b"0011_0110",               -- 0TT0
      7  => b"0011_1001",               -- 0TTT
      8  => b"0011_1010",               -- T000
      9  => b"0011_1100",               -- T00T
      10 => b"0100_1011",               -- T0T0
      11 => b"0100_1101",               -- T0TT
      12 => b"0100_1110",               -- TT00
      13 => b"0101_0011",               -- TT0T
      14 => b"0101_0101",               -- TTT0
      15 => b"0101_0110");              -- TTTT

   constant DATA_ROM_C : Slv8Array(0 to 31) := (
      0  => b"0110_1010",
      1  => b"0110_1100",
      2  => b"0111_0001",
      3  => b"0111_0010",
      4  => b"0111_0100",
      5  => b"1000_1011",
      6  => b"1000_1101",
      7  => b"1000_1110",
      8  => b"1001_0011",
      9  => b"1001_0101",
      10 => b"1001_0110",
      11 => b"1001_1001",
      12 => b"1001_1010",
      13 => b"1001_1100",
      14 => b"1010_0011",
      15 => b"1010_0101",
      16 => b"1010_0110",
      17 => b"1010_1001",
      18 => b"1010_1010",
      19 => b"1010_1100",
      20 => b"1011_0001",
      21 => b"1011_0010",
      22 => b"1011_0100",
      23 => b"1100_0011",
      24 => b"1100_0101",
      25 => b"1100_0110",
      26 => b"1100_1001",
      27 => b"1100_1010",
      28 => b"1100_1100",
      29 => b"1101_0001",
      30 => b"1101_0010",
      31 => b"1101_0100");

   attribute rom_style                 : string;
   attribute rom_style of TRIG_ROM_C   : constant is "distributed";
   attribute rom_style of DATA_ROM_C   : constant is "distributed";
   attribute rom_extract               : string;
   attribute rom_extract of TRIG_ROM_C : constant is "TRUE";
   attribute rom_extract of DATA_ROM_C : constant is "TRUE";
   attribute syn_keep                  : string;
   attribute syn_keep of TRIG_ROM_C    : constant is "TRUE";
   attribute syn_keep of DATA_ROM_C    : constant is "TRUE";

   type StateType is (
      INIT_S,
      RDY_S,
      SEND_S);

   type RegType is record
      cmd      : sl;
      ecr      : sl;
      bcr      : sl;
      wrReady  : sl;
      rdReady  : sl;
      shiftReg : slv(15 downto 0);
      shiftCnt : slv(3 downto 0);
      syncCntL : slv(4 downto 0);
      init     : slv(7 downto 0);
      trigDet  : slv(3 downto 0);
      trigTag  : slv(4 downto 0);
      data     : Slv5Array(5 downto 0);
      index    : natural range 0 to 6;
      state    : StateType;
   end record RegType;
   constant REG_INIT_C : RegType := (
      cmd      => '0',
      ecr      => '0',
      bcr      => '0',
      wrReady  => '0',
      rdReady  => '0',
      shiftReg => SYNC_C,
      shiftCnt => (others => '0'),
      syncCntL => (others => '0'),
      init     => x"FF",
      trigDet  => (others => '0'),
      trigTag  => (others => '0'),
      data     => (others => (others => '0')),
      index    => 0,
      state    => INIT_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   comb : process (bcr, cal, calDat, calId, ecr, gPulse, gPulseData, gPulseId,
                   r, rdValid, rst160MHz, trig, wrRegAddr, wrRegData, wrRegId,
                   wrValid) is
      variable v        : RegType;
      variable serPhase : natural;
   begin
      -- Latch the current value
      v := r;

      -- Reset the strobes
      v.wrReady := '0';
      v.rdReady := '0';

      -- Update the shift register
      v.shiftReg := r.shiftReg(14 downto 0) & '0';

      -- Increment the counter
      v.shiftCnt := r.shiftCnt + 1;

      -- Calculate the serialization phase
      serPhase := conv_integer(r.shiftCnt(3 downto 2));

      -- Check for trigger
      if (trig = '1') then
         -- Update the trigger detection mask
         v.trigDet(serPhase) := '1';
      end if;

      -- Check for ECR
      if (ecr = '1') then
         v.ecr := '1';
      end if;

      -- Check for BCR
      if (bcr = '1') then
         v.bcr := '1';
      end if;

      -- Check if last bit in shift registers sent
      if (r.shiftCnt = x"F") then

         -- Default shift reg update value
         v.shiftReg := SYNC_C;

         -- State Machine
         case r.state is
            ----------------------------------------------------------------------
            when INIT_S =>
               -- Decrement the counter
               v.init := r.init -1;
               -- Check initialization completed
               if (r.init = 0) then
                  -- Next state
                  v.state := RDY_S;
               end if;
            ----------------------------------------------------------------------
            when RDY_S =>
               -- Check for triggers
               if (v.trigDet /= 0) then
                  -- Update shift reg value
                  v.shiftReg(15 downto 8) := TRIG_ROM_C(conv_integer(v.trigDet));  -- Going into the chip, the command bits go in first and the tag goes in second.
                  v.shiftReg(7 downto 0)  := DATA_ROM_C(conv_integer(r.trigTag));  -- Going into the chip, the command bits go in first and the tag goes in second.
                  -- Increment the counter
                  v.trigTag               := r.trigTag + 1;

               -- Check for ECR
               elsif (v.ecr = '1') then
                  -- Update shift reg value
                  v.shiftReg := ECR_C;

               -- Check for BCR
               elsif (v.bcr = '1') then
                  -- Update shift reg value
                  v.shiftReg := BCR_C;

               -- Check for global pulse
               elsif (gPulse = '1') then
                  -- Update shift reg value
                  v.shiftReg := GLOB_PULSE_C;
                  -- Setup for data transfer
                  v.data(5)  := (gPulseId & '0');
                  v.data(4)  := (gPulseData & '0');
                  v.index    := 4;
                  -- Next state
                  v.state    := SEND_S;

               -- Check for calibration
               elsif (cal = '1') then
                  -- Update shift reg value
                  v.shiftReg := CAL_C;
                  -- Setup for data transfer
                  v.data(5)  := (calId & calDat(15));
                  v.data(4)  := calDat(14 downto 10);
                  v.data(3)  := calDat(9 downto 5);
                  v.data(2)  := calDat(4 downto 0);
                  v.index    := 2;
                  -- Next state
                  v.state    := SEND_S;

               -- Check if need to insert SYNC frame
               elsif (r.syncCntL = FORCE_SYNC_C) then
                  null;

               -- Check for Write Register Transaction
               elsif (wrValid = '1') then
                  -- Accept the data
                  v.wrReady  := '1';
                  -- Update shift reg value
                  v.shiftReg := WR_REG_C;
                  -- Setup for data transfer
                  v.data(5)  := (wrRegId & '0');
                  v.data(4)  := wrRegAddr(8 downto 4);
                  v.data(3)  := (wrRegAddr(3 downto 0) & wrRegData(15));
                  v.data(2)  := wrRegData(14 downto 10);
                  v.data(1)  := wrRegData(9 downto 5);
                  v.data(0)  := wrRegData(4 downto 0);
                  v.index    := 0;
                  -- Next state
                  v.state    := SEND_S;

               -- Check for Read Register Transaction
               elsif (rdValid = '1') then
                  -- Accept the data
                  v.rdReady  := '1';
                  -- Update shift reg value
                  v.shiftReg := RD_REG_C;
                  -- Setup for data transfer
                  v.data(5)  := (wrRegId & '0');
                  v.data(4)  := wrRegAddr(8 downto 4);
                  v.data(3)  := (wrRegAddr(3 downto 0) & '0');
                  v.data(2)  := "00000";
                  v.index    := 2;
                  -- Next state
                  v.state    := SEND_S;

               end if;
            ----------------------------------------------------------------------
            when SEND_S =>
               -- Check for triggers
               if (v.trigDet /= 0) then
                  -- Update shift reg value
                  v.shiftReg(15 downto 8) := TRIG_ROM_C(conv_integer(v.trigDet));  -- Going into the chip, the command bits go in first and the tag goes in second.
                  v.shiftReg(7 downto 0)  := DATA_ROM_C(conv_integer(r.trigTag));  -- Going into the chip, the command bits go in first and the tag goes in second.
                  -- Increment the counter
                  v.trigTag               := r.trigTag + 1;
               else
                  -- Update shift reg value
                  v.shiftReg(15 downto 8) := DATA_ROM_C(conv_integer(r.data(r.index+1)));
                  v.shiftReg(7 downto 0)  := DATA_ROM_C(conv_integer(r.data(r.index+0)));
                  -- Check for last 16-bit frame
                  if (r.index = 4) then
                     -- Next state
                     v.state := RDY_S;
                  else
                     -- Increment the counter by 2
                     v.index := r.index + 2;
                  end if;
               end if;
         ----------------------------------------------------------------------
         end case;

         -- Check if sync command being sent 
         if (v.shiftReg = SYNC_C) then
            -- Reset the counter
            v.syncCntL := (others => '0');
         -- Increment the counter 
         elsif (r.syncCntL /= FORCE_SYNC_C) then
            v.syncCntL := r.syncCntL + 1;
         end if;

         -- Reset the masks
         v.trigDet := x"0";
         v.ecr     := '0';
         v.bcr     := '0';

      end if;

      -- Combinatorial Outputs
      wrReady <= v.rdReady;
      rdReady <= v.rdReady;

      -- Reset
      if (rst160MHz = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Registered Outputs
      cmdOut <= r.shiftReg(15);

   end process comb;

   seq : process (clk160MHz) is
   begin
      if rising_edge(clk160MHz) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
