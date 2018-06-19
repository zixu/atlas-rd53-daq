-------------------------------------------------------------------------------
-- File       : Rd53aTb.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-06-18
-- Last update: 2018-06-18
-------------------------------------------------------------------------------
-- Description: Simulation Testbed for testing the Rd53a module
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.Pgp3Pkg.all;

entity Rd53aTb is end Rd53aTb;

architecture testbed of Rd53aTb is

   constant CLK_PERIOD_C : time := 6.25 ns;
   constant TPD_G        : time := CLK_PERIOD_C/4;

   signal clk160MHzP : sl := '0';
   signal clk160MHzN : sl := '1';

   signal dPortDataP  : Slv4Array(3 downto 0) := (others => x"0");
   signal dPortDataN  : Slv4Array(3 downto 0) := (others => x"F");
   signal dPortHitP   : Slv4Array(3 downto 0) := (others => x"0");
   signal dPortHitN   : Slv4Array(3 downto 0) := (others => x"F");
   signal dPortCmdP   : slv(3 downto 0)       := (others => '0');
   signal dPortCmdN   : slv(3 downto 0)       := (others => '1');
   signal dPortAuxP   : slv(3 downto 0)       := (others => '0');
   signal dPortAuxN   : slv(3 downto 0)       := (others => '1');
   signal dPortRst    : slv(3 downto 0)       := (others => '1');
   signal dPortRstL   : slv(3 downto 0)       := (others => '0');
   signal dPortNtcCsL : slv(3 downto 0)       := (others => '1');
   signal dPortNtcSck : slv(3 downto 0)       := (others => '1');
   signal dPortNtcSdo : slv(3 downto 0)       := (others => '1');

begin

   U_ClkRst : entity work.ClkRst
      generic map (
         CLK_PERIOD_G      => 6.25 ns,
         RST_START_DELAY_G => 0 ns,  -- Wait this long into simulation before asserting reset
         RST_HOLD_TIME_G   => 1000 ns)  -- Hold reset for this long)
      port map (
         clkP => clk160MHzP,
         clkN => clk160MHzN);

   U_ASIC : entity work.Rd53aWrapper
      port map (
         ------------------------
         -- Power-on Resets (POR)
         ------------------------
         POR_EXT_CAP_PAD => dPortRstL(0),
         -------------------------------------------------------------
         -- Clock Data Recovery (CDR) input command/data stream [SLVS]
         -------------------------------------------------------------
         CMD_P_PAD       => clk160MHzP,
         CMD_N_PAD       => clk160MHzN,
         -----------------------------------------------------
         -- 4x general-purpose SLVS outputs, including Hit-ORs
         -----------------------------------------------------
         GPLVDS0_P_PAD   => dPortHitP(0)(0),
         GPLVDS0_N_PAD   => dPortHitN(0)(0),
         GPLVDS1_P_PAD   => dPortHitP(0)(1),
         GPLVDS1_N_PAD   => dPortHitN(0)(1),
         GPLVDS2_P_PAD   => dPortHitP(0)(2),
         GPLVDS2_N_PAD   => dPortHitN(0)(2),
         GPLVDS3_P_PAD   => dPortHitP(0)(3),
         GPLVDS3_N_PAD   => dPortHitN(0)(3),
         ------------------------------------------------
         -- 4x serial output data links @ 1.28 Gb/s [CML]
         ------------------------------------------------
         GTX0_P_PAD      => dPortDataP(0)(0),
         GTX0_N_PAD      => dPortDataN(0)(0),
         GTX1_P_PAD      => dPortDataP(0)(1),
         GTX1_N_PAD      => dPortDataN(0)(1),
         GTX2_P_PAD      => dPortDataP(0)(2),
         GTX2_N_PAD      => dPortDataN(0)(2),
         GTX3_P_PAD      => dPortDataP(0)(3),
         GTX3_N_PAD      => dPortDataN(0)(3));

   dPortRstL <= not(dPortRst);

end testbed;
