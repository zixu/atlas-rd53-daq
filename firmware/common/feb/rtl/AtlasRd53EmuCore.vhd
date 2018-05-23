-------------------------------------------------------------------------------
-- File       : AtlasRd53EmuCore.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-08
-- Last update: 2018-05-23
-------------------------------------------------------------------------------
-- Description: Top-Level module using four lanes of 10 Gbps PGPv3 communication
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
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AtlasRd53Pkg.all;

library unisim;
use unisim.vcomponents.all;

entity AtlasRd53EmuCore is
   generic (
      TPD_G        : time   := 1 ns;
      BUILD_INFO_G : BuildInfoType;
      PGP3_RATE_G  : string := "6.25Gbps");  -- or "10.3125Gbps"      
   port (
      -- RD53 ASIC Emulation Ports
      dPortDataP    : out   Slv4Array(3 downto 0);
      dPortDataN    : out   Slv4Array(3 downto 0);
      dPortHitP     : out   Slv4Array(3 downto 0);
      dPortHitN     : out   Slv4Array(3 downto 0);
      dPortCmdP     : in    slv(3 downto 0);
      dPortCmdN     : in    slv(3 downto 0);
      dPortAuxP     : in    slv(3 downto 0);
      dPortAuxN     : in    slv(3 downto 0);
      dPortRst      : out   slv(3 downto 0);
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
end AtlasRd53EmuCore;

architecture mapping of AtlasRd53EmuCore is

   constant NUM_AXIL_MASTERS_C : natural := 5;

   constant SYS_INDEX_C    : natural := 0;
   constant DPORT0_INDEX_C : natural := 1;
   constant DPORT1_INDEX_C : natural := 2;
   constant DPORT2_INDEX_C : natural := 3;
   constant DPORT3_INDEX_C : natural := 4;

   constant XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := (
      SYS_INDEX_C     => (
         baseAddr     => x"0000_0000",
         addrBits     => 24,
         connectivity => x"FFFF"),
      DPORT0_INDEX_C  => (
         baseAddr     => x"0100_0000",
         addrBits     => 24,
         connectivity => x"FFFF"),
      DPORT1_INDEX_C  => (
         baseAddr     => x"0200_0000",
         addrBits     => 24,
         connectivity => x"FFFF"),
      DPORT2_INDEX_C  => (
         baseAddr     => x"0300_0000",
         addrBits     => 24,
         connectivity => x"FFFF"),
      DPORT3_INDEX_C  => (
         baseAddr     => x"0400_0000",
         addrBits     => 24,
         connectivity => x"FFFF"));

   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType;
   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType;

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);

   signal rxLinkUp : slv(3 downto 0);
   signal txLinkUp : slv(3 downto 0);   
   signal pllLocked : slv(3 downto 0);

   signal axilClk : sl;
   signal axilRst : sl;
   
   signal refClk300MHz : sl;
   signal refRst300MHz : sl;   

   signal status : AtlasRd53StatusType := RD53_FEB_STATUS_INIT_C;
   signal config : AtlasRd53ConfigType := RD53_FEB_CONFIG_INIT_C;

begin

   led <= pllLocked;

   --------------------------------
   -- Unused ports for the emulator
   --------------------------------
   GEN_FEB : for i in 3 downto 0 generate
      GEN_CH : for j in 3 downto 0 generate
         U_dPortHit : OBUFDS
            port map (
               I  => '0',
               O  => dPortHitP(i)(j),
               OB => dPortHitN(i)(j));
      end generate GEN_CH;
   end generate GEN_FEB;

   U_tluInt : IBUFDS
      port map (
         I  => tluIntP,
         IB => tluIntN,
         O  => open);

   U_tluRst : IBUFDS
      port map (
         I  => tluRstP,
         IB => tluRstN,
         O  => open);

   U_tluTrgClk : OBUFDS
      port map (
         I  => '0',
         O  => tluTrgClkP,
         OB => tluTrgClkN);

   U_tluBsy : OBUFDS
      port map (
         I  => '0',
         O  => tluBsyP,
         OB => tluBsyN);

   hitOut <= '0';

   ---------------
   -- PGPv3 Module
   ---------------         
   U_Pgp : entity work.AtlasRd53Pgp3
      generic map (
         TPD_G       => TPD_G,
         PGP3_RATE_G => PGP3_RATE_G)
      port map (
         -- AXI-Lite Interfaces (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave,
         -- Stable Reference IDELAY Clock and Reset
         refClk300MHz    => refClk300MHz,
         refRst300MHz    => refRst300MHz,
         -- Link Status
         rxLinkUp        => rxLinkUp,
         txLinkUp        => txLinkUp,
         -- PGP Ports
         pgpClkP         => pgpClkP,
         pgpClkN         => pgpClkN,
         pgpRxP          => pgpRxP,
         pgpRxN          => pgpRxN,
         pgpTxP          => pgpTxP,
         pgpTxN          => pgpTxN);

   --------------------------
   -- AXI-Lite: Crossbar Core
   --------------------------  
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => XBAR_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   -------------------       
   -- System Registers
   -------------------       
   U_System : entity work.AtlasRd53Sys
      generic map (
         TPD_G           => TPD_G,
         AXI_BASE_ADDR_G => XBAR_CONFIG_C(SYS_INDEX_C).baseAddr,
         BUILD_INFO_G    => BUILD_INFO_G)
      port map (
         -- Configuration/Status interface
         status          => status,
         config          => config,
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(SYS_INDEX_C),
         axilReadSlave   => axilReadSlaves(SYS_INDEX_C),
         axilWriteMaster => axilWriteMasters(SYS_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(SYS_INDEX_C),
         -- NTC SPI Ports
         dPortNtcCsL     => dPortNtcCsL,
         dPortNtcSck     => dPortNtcSck,
         dPortNtcSdo     => dPortNtcSdo,
         -- QSFP Ports
         qsfpScl         => qsfpScl,
         qsfpSda         => qsfpSda,
         qsfpLpMode      => qsfpLpMode,
         qsfpRst         => qsfpRst,
         qsfpSel         => qsfpSel,
         qsfpIntL        => qsfpIntL,
         qsfpPrstL       => qsfpPrstL,
         -- Boot Memory Ports
         bootCsL         => bootCsL,
         bootMosi        => bootMosi,
         bootMiso        => bootMiso,
         -- Misc Ports
         pwrScl          => pwrScl,
         pwrSda          => pwrSda,
         tempAlertL      => tempAlertL,
         vPIn            => vPIn,
         vNIn            => vNIn);

   ------------------
   -- DPort Emulation 
   ------------------
   GEN_EMU : for i in 3 downto 0 generate
      U_Dport : entity work.AtlasRd53EmuDport
         generic map (
            TPD_G           => TPD_G,
            LINK_INDEX_G    => i,
            AXI_BASE_ADDR_G => XBAR_CONFIG_C(DPORT0_INDEX_C+i).baseAddr)
         port map (
            -- AXI-Lite Interface (axilClk domain)
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => axilReadMasters(DPORT0_INDEX_C+i),
            axilReadSlave   => axilReadSlaves(DPORT0_INDEX_C+i),
            axilWriteMaster => axilWriteMasters(DPORT0_INDEX_C+i),
            axilWriteSlave  => axilWriteSlaves(DPORT0_INDEX_C+i),
            -- Status
            pllLocked       => pllLocked(i),
            trigOut         => open,
            fifoFull        => open,
            ttFull          => open,
            ttEmpty         => open,
            -- RD53 Ports
            dPortDataP      => dPortDataP(i),
            dPortDataN      => dPortDataN(i),
            dPortCmdP       => dPortCmdP(i),
            dPortCmdN       => dPortCmdN(i),
            dPortAuxP       => dPortAuxP(i),
            dPortAuxN       => dPortAuxN(i),
            dPortRst        => dPortRst(i));
   end generate GEN_EMU;

end mapping;
