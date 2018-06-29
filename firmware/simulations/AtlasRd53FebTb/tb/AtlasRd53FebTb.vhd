-------------------------------------------------------------------------------
-- File       : AtlasRd53FebTb.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-06-18
-- Last update: 2018-06-27
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
use work.BuildInfoPkg.all;

entity AtlasRd53FebTb is end AtlasRd53FebTb;

architecture testbed of AtlasRd53FebTb is

   component Rd53aWrapper
      port (
         ------------------------
         -- Power-on Resets (POR)
         ------------------------
         POR_EXT_CAP_PAD : in  sl;
         -------------------------------------------------------------
         -- Clock Data Recovery (CDR) input command/data stream [SLVS]
         -------------------------------------------------------------
         CMD_P_PAD       : in  sl;
         CMD_N_PAD       : in  sl;
         -----------------------------------------------------
         -- 4x general-purpose SLVS outputs, including Hit-ORs
         -----------------------------------------------------
         GPLVDS0_P_PAD   : out sl;
         GPLVDS0_N_PAD   : out sl;
         GPLVDS1_P_PAD   : out sl;
         GPLVDS1_N_PAD   : out sl;
         GPLVDS2_P_PAD   : out sl;
         GPLVDS2_N_PAD   : out sl;
         GPLVDS3_P_PAD   : out sl;
         GPLVDS3_N_PAD   : out sl;
         ------------------------------------------------
         -- 4x serial output data links @ 1.28 Gb/s [CML]
         ------------------------------------------------
         GTX0_P_PAD      : out sl;
         GTX0_N_PAD      : out sl;
         GTX1_P_PAD      : out sl;
         GTX1_N_PAD      : out sl;
         GTX2_P_PAD      : out sl;
         GTX2_N_PAD      : out sl;
         GTX3_P_PAD      : out sl;
         GTX3_N_PAD      : out sl);
   end component;

   signal clk160MHzP : sl := '0';
   signal clk160MHzN : sl := '1';

   signal pgpClkP : sl := '0';
   signal pgpClkN : sl := '1';

   signal dPortDataP : Slv4Array(3 downto 0) := (others => x"0");
   signal dPortDataN : Slv4Array(3 downto 0) := (others => x"F");
   signal dPortHitP  : Slv4Array(3 downto 0) := (others => x"0");
   signal dPortHitN  : Slv4Array(3 downto 0) := (others => x"F");
   signal dPortCmdP  : slv(3 downto 0)       := (others => '0');
   signal dPortCmdN  : slv(3 downto 0)       := (others => '1');
   signal dPortAuxP  : slv(3 downto 0)       := (others => '0');
   signal dPortAuxN  : slv(3 downto 0)       := (others => '1');
   signal dPortRstL  : slv(3 downto 0)       := (others => '0');

begin

   -------------------
   -- Reference Clocks
   -------------------
   U_Clk160 : entity work.ClkRst
      generic map (
         CLK_PERIOD_G      => 6.256 ns,  -- 159.8 MHz
         RST_START_DELAY_G => 0 ns,  -- Wait this long into simulation before asserting reset
         RST_HOLD_TIME_G   => 1000 ns)  -- Hold reset for this long)
      port map (
         clkP => clk160MHzP,
         clkN => clk160MHzN);

   U_ClkPgp : entity work.ClkRst
      generic map (
         CLK_PERIOD_G      => 3.2 ns,   -- 312.5 MHz
         RST_START_DELAY_G => 0 ns,  -- Wait this long into simulation before asserting reset
         RST_HOLD_TIME_G   => 1000 ns)  -- Hold reset for this long)
      port map (
         clkP => pgpClkP,
         clkN => pgpClkN);

   ---------------------------------------------------
   -- Only simulating 1 of the 4 DPORT pair interfaces
   ---------------------------------------------------
   GEN_VEC : for i in 0 downto 0 generate
      U_ASIC : Rd53aWrapper
         port map (
            ------------------------
            -- Power-on Resets (POR)
            ------------------------
            POR_EXT_CAP_PAD => dPortRstL(i),
            -------------------------------------------------------------
            -- Clock Data Recovery (CDR) input command/data stream [SLVS]
            -------------------------------------------------------------
            CMD_P_PAD       => dPortCmdP(i),
            CMD_N_PAD       => dPortCmdN(i),
            -----------------------------------------------------
            -- 4x general-purpose SLVS outputs, including Hit-ORs
            -----------------------------------------------------
            GPLVDS0_P_PAD   => dPortHitP(i)(0),
            GPLVDS0_N_PAD   => dPortHitN(i)(0),
            GPLVDS1_P_PAD   => dPortHitP(i)(1),
            GPLVDS1_N_PAD   => dPortHitN(i)(1),
            GPLVDS2_P_PAD   => dPortHitP(i)(2),
            GPLVDS2_N_PAD   => dPortHitN(i)(2),
            GPLVDS3_P_PAD   => dPortHitP(i)(3),
            GPLVDS3_N_PAD   => dPortHitN(i)(3),
            ------------------------------------------------
            -- 4x serial output data links @ 1.28 Gb/s [CML]
            ------------------------------------------------
            GTX0_P_PAD      => dPortDataP(i)(0),
            GTX0_N_PAD      => dPortDataN(i)(0),
            GTX1_P_PAD      => dPortDataP(i)(1),
            GTX1_N_PAD      => dPortDataN(i)(1),
            GTX2_P_PAD      => dPortDataP(i)(2),
            GTX2_N_PAD      => dPortDataN(i)(2),
            GTX3_P_PAD      => dPortDataP(i)(3),
            GTX3_N_PAD      => dPortDataN(i)(3));
   end generate GEN_VEC;

   U_Feb : entity work.AtlasRd53Core
      generic map (
         TPD_G        => 1 ns,
         SIMULATION_G => true,
         BUILD_INFO_G => BUILD_INFO_C)
      port map (
         -- RD53 ASIC Serial Ports
         dPortDataP    => dPortDataP,
         dPortDataN    => dPortDataN,
         dPortHitP     => dPortHitP,
         dPortHitN     => dPortHitN,
         dPortCmdP     => dPortCmdP,
         dPortCmdN     => dPortCmdN,
         dPortAuxP     => dPortAuxP,
         dPortAuxN     => dPortAuxN,
         dPortRstL     => dPortRstL,
         -- NTC SPI Ports
         dPortNtcCsL   => open,
         dPortNtcSck   => open,
         dPortNtcSdo   => (others => '0'),
         -- Trigger and hits Ports
         trigInL       => '1',
         hitInL        => '1',
         hitOut        => open,
         -- TLU Ports
         tluTrgClkP    => open,
         tluTrgClkN    => open,
         tluBsyP       => open,
         tluBsyN       => open,
         tluIntP       => '0',
         tluIntN       => '1',
         tluRstP       => '0',
         tluRstN       => '1',
         -- Reference Clock
         intClk160MHzP => clk160MHzP,
         intClk160MHzN => clk160MHzN,
         extClk160MHzP => (others => '0'),
         extClk160MHzN => (others => '1'),
         -- QSFP Ports
         qsfpScl       => open,
         qsfpSda       => open,
         qsfpLpMode    => open,
         qsfpRst       => open,
         qsfpSel       => open,
         qsfpIntL      => '1',
         qsfpPrstL     => '1',
         -- PGP Ports
         pgpClkP       => pgpClkP,
         pgpClkN       => pgpClkN,
         pgpRxP        => (others => '0'),
         pgpRxN        => (others => '1'),
         pgpTxP        => open,
         pgpTxN        => open,
         -- Boot Memory Ports
         bootCsL       => open,
         bootMosi      => open,
         bootMiso      => '1',
         -- Misc Ports
         led           => open,
         pwrSyncSclk   => open,
         pwrSyncFclk   => open,
         pwrScl        => open,
         pwrSda        => open,
         tempAlertL    => '1',
         vPIn          => 'Z',
         vNIn          => 'Z');

end testbed;
