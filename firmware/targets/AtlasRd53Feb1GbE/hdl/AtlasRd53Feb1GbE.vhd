-------------------------------------------------------------------------------
-- File       : AtlasRd53Feb1GbE.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-08
-- Last update: 2018-07-30
-------------------------------------------------------------------------------
-- Description: Top-Level module using 1 GbE communication
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

entity AtlasRd53Feb1GbE is
   generic (
      TPD_G        : time   := 1 ns;
      -- SYNTH_MODE_G : string := "xpm";
      SYNTH_MODE_G : string := "inferred";
      BUILD_INFO_G : BuildInfoType);
   port (
      -- RD53 ASIC Serial Ports
      dPortDataP    : in    Slv4Array(3 downto 0);
      dPortDataN    : in    Slv4Array(3 downto 0);
      dPortHitP     : in    Slv4Array(3 downto 0);
      dPortHitN     : in    Slv4Array(3 downto 0);
      dPortCmdP     : out   slv(3 downto 0);
      dPortCmdN     : out   slv(3 downto 0);
      dPortAuxP     : out   slv(3 downto 0);
      dPortAuxN     : out   slv(3 downto 0);
      dPortRst      : out   slv(3 downto 0);  -- Inverted in HW on FPGA board before dport connector
      -- NTC SPI Ports
      dPortNtcCsL   : out   slv(3 downto 0);
      dPortNtcSck   : out   slv(3 downto 0);
      dPortNtcSdo   : in    slv(3 downto 0);
      -- Trigger and hits Ports
      trigInL       : in    sl;
      hitInL        : in    sl;
      hitOut        : out   sl;
      -- TLU Ports
      tluTrgClkP    : out   sl;
      tluTrgClkN    : out   sl;
      tluBsyP       : out   sl;
      tluBsyN       : out   sl;
      tluIntP       : in    sl;
      tluIntN       : in    sl;
      tluRstP       : in    sl;
      tluRstN       : in    sl;
      -- Reference Clock
      intClk160MHzP : in    sl;
      intClk160MHzN : in    sl;
      extClk160MHzP : in    slv(1 downto 0);
      extClk160MHzN : in    slv(1 downto 0);
      -- QSFP Ports
      qsfpScl       : inout sl;
      qsfpSda       : inout sl;
      qsfpLpMode    : out   sl;
      qsfpRst       : out   sl;
      qsfpSel       : out   sl;
      qsfpIntL      : in    sl;
      qsfpPrstL     : in    sl;
      -- PGP Ports
      pgpClkP       : in    sl;
      pgpClkN       : in    sl;
      pgpRxP        : in    slv(3 downto 0);
      pgpRxN        : in    slv(3 downto 0);
      pgpTxP        : out   slv(3 downto 0);
      pgpTxN        : out   slv(3 downto 0);
      -- Boot Memory Ports
      bootCsL       : out   sl;
      bootMosi      : out   sl;
      bootMiso      : in    sl;
      -- Misc Ports
      led           : out   slv(3 downto 0);
      pwrSyncSclk   : out   sl;
      pwrSyncFclk   : out   sl;
      pwrScl        : inout sl;
      pwrSda        : inout sl;
      tempAlertL    : in    sl;
      vPIn          : in    sl;
      vNIn          : in    sl);
end AtlasRd53Feb1GbE;

architecture top_level of AtlasRd53Feb1GbE is

begin

   U_Core : entity work.AtlasRd53Core
      generic map (
         TPD_G        => TPD_G,
         BUILD_INFO_G => BUILD_INFO_G,
         SYNTH_MODE_G => SYNTH_MODE_G,
         COM_TYPE_G   => "ETH",
         ETH_10G_G    => false,          -- 1 GbE 
         DHCP_G       => true,
         IP_ADDR_G    => x"0A01A8C0")  -- 192.168.1.10 (before DHCP)            
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
         dPortRst      => dPortRst,
         dPortNtcCsL   => dPortNtcCsL,
         dPortNtcSck   => dPortNtcSck,
         dPortNtcSdo   => dPortNtcSdo,
         -- Trigger and hits Ports
         trigInL       => trigInL,
         hitInL        => hitInL,
         hitOut        => hitOut,
         -- TLU Ports
         tluTrgClkP    => tluTrgClkP,
         tluTrgClkN    => tluTrgClkN,
         tluBsyP       => tluBsyP,
         tluBsyN       => tluBsyN,
         tluIntP       => tluIntP,
         tluIntN       => tluIntN,
         tluRstP       => tluRstP,
         tluRstN       => tluRstN,
         -- Reference Clock
         intClk160MHzP => intClk160MHzP,
         intClk160MHzN => intClk160MHzN,
         extClk160MHzP => extClk160MHzP,
         extClk160MHzN => extClk160MHzN,
         -- QSFP Ports
         qsfpScl       => qsfpScl,
         qsfpSda       => qsfpSda,
         qsfpLpMode    => qsfpLpMode,
         qsfpRst       => qsfpRst,
         qsfpSel       => qsfpSel,
         qsfpIntL      => qsfpIntL,
         qsfpPrstL     => qsfpPrstL,
         -- PGP Ports
         pgpClkP       => pgpClkP,
         pgpClkN       => pgpClkN,
         pgpRxP        => pgpRxP,
         pgpRxN        => pgpRxN,
         pgpTxP        => pgpTxP,
         pgpTxN        => pgpTxN,
         -- Boot Memory Ports
         bootCsL       => bootCsL,
         bootMosi      => bootMosi,
         bootMiso      => bootMiso,
         -- Misc Ports
         led           => led,
         pwrSyncSclk   => pwrSyncSclk,
         pwrSyncFclk   => pwrSyncFclk,
         pwrScl        => pwrScl,
         pwrSda        => pwrSda,
         tempAlertL    => tempAlertL,
         vPIn          => vPIn,
         vNIn          => vNIn);

end top_level;
