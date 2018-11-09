-------------------------------------------------------------------------------
-- File       : AtlasRd53Pkg.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: ATLAS RD43 VHDL Package
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
use work.AxiStreamPkg.all;
use work.SsiPkg.all;

package AtlasRd53Pkg is

   type AtlasRD53ConfigType is record
      enLocalEmu  : sl;
      enAuxClk    : sl;
      batchSize   : slv(15 downto 0);
      timerConfig : slv(15 downto 0);
      asicRst     : sl;
      pllRst      : sl;
      refSelect   : slv(1 downto 0);
   end record;
   constant RD53_FEB_CONFIG_INIT_C : AtlasRD53ConfigType := (
      enLocalEmu  => '0',
      enAuxClk    => '0',
      batchSize   => (others => '0'),
      timerConfig => (others => '0'),
      asicRst     => '0',
      pllRst      => '0',
      refSelect   => "00");

   type AtlasRD53StatusType is record
      iDelayCtrlRdy : sl;
      pllLocked     : sl;
      refClk160MHz  : sl;
   end record;
   constant RD53_FEB_STATUS_INIT_C : AtlasRD53StatusType := (
      iDelayCtrlRdy => '0',
      pllLocked     => '0',
      refClk160MHz  => '0');

end package;
