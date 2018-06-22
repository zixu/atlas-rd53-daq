-------------------------------------------------------------------------------
-- File       : AtlasRd53Clk.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-18
-- Last update: 2018-06-21
-------------------------------------------------------------------------------
-- Description: PLL Wrapper and 160 MHz clock MUX
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

use work.StdRtlPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AtlasRd53Clk is
   generic (
      TPD_G        : time    := 1 ns;
      SIMULATION_G : boolean := false);
   port (
      -- Reference Clocks Ports
      intClk160MHzP : in  sl;
      intClk160MHzN : in  sl;
      extClk160MHzP : in  slv(1 downto 0);
      extClk160MHzN : in  slv(1 downto 0);
      -- Misc Ports
      pwrSyncSclk   : out sl;
      pwrSyncFclk   : out sl;
      -- Configuration/Status interface
      refSelect     : in  slv(1 downto 0);
      pllRst        : in  sl;
      refClk160MHz  : out sl;
      pllLocked     : out sl;
      -- Timing Clocks Interface
      clk640MHz     : out sl;
      clk160MHz     : out sl;
      clk80MHz      : out sl;
      clk40MHz      : out sl;
      -- Timing Resets Interface
      rst640MHz     : out sl;
      rst160MHz     : out sl;
      rst80MHz      : out sl;
      rst40MHz      : out sl);
end AtlasRd53Clk;

architecture mapping of AtlasRd53Clk is

   signal intClk160MHz    : sl;
   signal extClk160MHzRaw : slv(1 downto 0);
   signal extClk160MHz    : sl;
   signal refClk          : sl;

begin

   refClk160MHz <= refClk;

   U_intClk160MHzRaw : IBUFDS
      port map (
         I  => intClk160MHzP,
         IB => intClk160MHzN,
         O  => intClk160MHz);

   U_extClk160MHz_0 : IBUFDS
      port map (
         I  => extClk160MHzP(0),
         IB => extClk160MHzN(0),
         O  => extClk160MHzRaw(0));

   U_extClk160MHz_1 : IBUFDS
      port map (
         I  => extClk160MHzP(1),
         IB => extClk160MHzN(1),
         O  => extClk160MHzRaw(1));

   U_BUFGMUX_0 : BUFGMUX
      port map (
         O  => extClk160MHz,            -- 1-bit output: Clock output
         I0 => extClk160MHzRaw(0),      -- 1-bit input: Clock input (S=0)
         I1 => extClk160MHzRaw(1),      -- 1-bit input: Clock input (S=1)
         S  => refSelect(0));           -- 1-bit input: Clock select   

   U_BUFGMUX_1 : BUFGMUX
      port map (
         O  => refClk,                  -- 1-bit output: Clock output
         I0 => intClk160MHz,            -- 1-bit input: Clock input (S=0)
         I1 => extClk160MHz,            -- 1-bit input: Clock input (S=1)
         S  => refSelect(1));  -- 1-bit input: Clock select            

   U_PLL : entity work.ClockManager7
      generic map(
         TPD_G            => TPD_G,
         SIMULATION_G     => SIMULATION_G,
         TYPE_G           => "PLL",
         BANDWIDTH_G      => "HIGH",
         INPUT_BUFG_G     => false,
         FB_BUFG_G        => true,
         NUM_CLOCKS_G     => 4,
         CLKIN_PERIOD_G   => 6.25,      -- 160 MHz
         DIVCLK_DIVIDE_G  => 1,         -- 160 MHz = 160 MHz/1
         CLKFBOUT_MULT_G  => 8,         -- 1.28 GHz = 160 MHz x 8
         CLKOUT0_DIVIDE_G => 2,         -- 640 MHz = 1.28 GHz/2
         CLKOUT1_DIVIDE_G => 8,         -- 160 MHz = 1.28 GHz/8
         CLKOUT2_DIVIDE_G => 16,        -- 80 MHz = 1.28 GHz/16
         CLKOUT3_DIVIDE_G => 32)        -- 40 MHz = 1.28 GHz/32
      port map(
         clkIn     => refClk,
         rstIn     => pllRst,
         -- Clock Outputs
         clkOut(0) => clk640MHz,
         clkOut(1) => clk160MHz,
         clkOut(2) => clk80MHz,
         clkOut(3) => clk40MHz,
         -- Reset Outputs
         rstOut(0) => rst640MHz,
         rstOut(1) => rst160MHz,
         rstOut(2) => rst80MHz,
         rstOut(3) => rst40MHz,
         -- Status         
         locked    => pllLocked);

   -- Not synchronizing the DC/DC to system clock
   pwrSyncSclk <= '0';
   pwrSyncFclk <= '0';

end mapping;
