-------------------------------------------------------------------------------
-- File       : AtlasRd53Core.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-08
-- Last update: 2018-07-30
-------------------------------------------------------------------------------
-- Description: AD53 readout core module
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

entity AtlasRd53Core is
   generic (
      TPD_G        : time             := 1 ns;
      BUILD_INFO_G : BuildInfoType;
      SIMULATION_G : boolean          := false;
      SYNTH_MODE_G : string           := "inferred";
      COM_TYPE_G   : string           := "PGPv3";
      ETH_10G_G    : boolean          := false;
      DHCP_G       : boolean          := true;
      IP_ADDR_G    : slv(31 downto 0) := x"0A01A8C0";  -- 192.168.1.10 (before DHCP)      
      PGP3_RATE_G  : string           := "6.25Gbps");  -- or "10.3125Gbps"      
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
      dPortRst      : out   slv(3 downto 0);
      dPortRstL     : out   slv(3 downto 0);
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
end AtlasRd53Core;

architecture mapping of AtlasRd53Core is

   constant NUM_AXIL_MASTERS_C : natural := 6;

   constant SYS_INDEX_C    : natural := 0;
   constant DPORT0_INDEX_C : natural := 1;
   constant DPORT1_INDEX_C : natural := 2;
   constant DPORT2_INDEX_C : natural := 3;
   constant DPORT3_INDEX_C : natural := 4;
   constant TLU_INDEX_C    : natural := 5;

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
         connectivity => x"FFFF"),
      TLU_INDEX_C     => (
         baseAddr     => x"0500_0000",
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

   signal txDataMasters : AxiStreamMasterArray(3 downto 0);
   signal txDataSlaves  : AxiStreamSlaveArray(3 downto 0);

   signal txConfigMasters : AxiStreamMasterArray(3 downto 0);
   signal txConfigSlaves  : AxiStreamSlaveArray(3 downto 0);
   signal rxConfigMasters : AxiStreamMasterArray(3 downto 0);
   signal rxConfigSlaves  : AxiStreamSlaveArray(3 downto 0);

   signal rxLinkUp : slv(3 downto 0);
   signal txLinkUp : slv(3 downto 0);

   signal axilClk : sl;
   signal axilRst : sl;

   signal clk640MHz : sl;
   signal clk160MHz : sl;
   signal clk80MHz  : sl;
   signal clk40MHz  : sl;
   signal rst640MHz : sl;
   signal rst160MHz : sl;
   signal rst80MHz  : sl;
   signal rst40MHz  : sl;
   signal ttc       : AtlasRd53TimingTrigType;

   signal refClk300MHz : sl;
   signal refRst300MHz : sl;

   signal status : AtlasRd53StatusType := RD53_FEB_STATUS_INIT_C;
   signal config : AtlasRd53ConfigType := RD53_FEB_CONFIG_INIT_C;

   attribute IODELAY_GROUP                 : string;
   attribute IODELAY_GROUP of U_IDELAYCTRL : label is "xapp_idelay";

   attribute KEEP_HIERARCHY                 : string;
   attribute KEEP_HIERARCHY of U_IDELAYCTRL : label is "TRUE";

begin

   led       <= rxLinkUp;
   dPortRst  <= (others => axilRst);
   dPortRstL <= (others => not(axilRst));

   U_IDELAYCTRL : IDELAYCTRL
      port map (
         RDY    => status.iDelayCtrlRdy,
         REFCLK => refClk300MHz,
         RST    => refRst300MHz);

   ----------------------
   -- Timing Clock Module
   ----------------------
   U_Clk : entity work.AtlasRd53Clk
      generic map(
         TPD_G        => TPD_G,
         SIMULATION_G => SIMULATION_G)
      port map(
         -- Reference Clock Ports
         intClk160MHzP => intClk160MHzP,
         intClk160MHzN => intClk160MHzN,
         extClk160MHzP => extClk160MHzP,
         extClk160MHzN => extClk160MHzN,
         -- Misc Ports
         pwrSyncSclk   => pwrSyncSclk,
         pwrSyncFclk   => pwrSyncFclk,
         -- Configuration/Status interface
         refSelect     => config.refSelect,
         pllRst        => config.pllRst,
         refClk160MHz  => status.refClk160MHz,
         pllLocked     => status.pllLocked,
         -- Timing Clocks Interface
         clk640MHz     => clk640MHz,
         clk160MHz     => clk160MHz,
         clk80MHz      => clk80MHz,
         clk40MHz      => clk40MHz,
         -- Timing Resets Interface
         rst640MHz     => rst640MHz,
         rst160MHz     => rst160MHz,
         rst80MHz      => rst80MHz,
         rst40MHz      => rst40MHz);

   ---------------
   -- PGPv3 Module
   ---------------         
   GEN_PGP : if (COM_TYPE_G = "PGPv3") generate
      U_Pgp : entity work.AtlasRd53Pgp3
         generic map (
            TPD_G        => TPD_G,
            SIMULATION_G => SIMULATION_G,
            SYNTH_MODE_G => SYNTH_MODE_G,
            PGP3_RATE_G  => PGP3_RATE_G)
         port map (
            -- AXI-Lite Interfaces (axilClk domain)
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => axilReadMaster,
            axilReadSlave   => axilReadSlave,
            axilWriteMaster => axilWriteMaster,
            axilWriteSlave  => axilWriteSlave,
            -- Streaming RD53 Config Interface (clk160MHz domain)
            clk160MHz       => clk160MHz,
            rst160MHz       => rst160MHz,
            sConfigMasters  => txConfigMasters,
            sConfigSlaves   => txConfigSlaves,
            mConfigMasters  => rxConfigMasters,
            mConfigSlaves   => rxConfigSlaves,
            -- Streaming RD43 Data Interface (axilClk domain)
            sDataMasters    => txDataMasters,
            sDataSlaves     => txDataSlaves,
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
   end generate;

   ---------------
   -- PGPv3 Module
   ---------------         
   GEN_ETH : if (COM_TYPE_G = "ETH") generate
      U_ETH : entity work.AtlasRd53Eth
         generic map (
            TPD_G        => TPD_G,
            SIMULATION_G => SIMULATION_G,
            SYNTH_MODE_G => SYNTH_MODE_G,
            ETH_10G_G    => ETH_10G_G,
            DHCP_G       => DHCP_G,
            IP_ADDR_G    => IP_ADDR_G)
         port map (
            -- AXI-Lite Interfaces (axilClk domain)
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => axilReadMaster,
            axilReadSlave   => axilReadSlave,
            axilWriteMaster => axilWriteMaster,
            axilWriteSlave  => axilWriteSlave,
            -- Streaming RD53 Config Interface (clk160MHz domain)
            clk160MHz       => clk160MHz,
            rst160MHz       => rst160MHz,
            sConfigMasters  => txConfigMasters,
            sConfigSlaves   => txConfigSlaves,
            mConfigMasters  => rxConfigMasters,
            mConfigSlaves   => rxConfigSlaves,
            -- Streaming RD43 Data Interface (axilClk domain)
            sDataMasters    => txDataMasters,
            sDataSlaves     => txDataSlaves,
            -- Stable Reference IDELAY Clock and Reset
            refClk300MHz    => refClk300MHz,
            refRst300MHz    => refRst300MHz,
            -- Link Status
            rxLinkUp        => rxLinkUp,
            txLinkUp        => txLinkUp,
            -- PGP Ports
            ethClkP         => pgpClkP,
            ethClkN         => pgpClkN,
            ethRxP          => pgpRxP,
            ethRxN          => pgpRxN,
            ethTxP          => pgpTxP,
            ethTxN          => pgpTxN);
   end generate;

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
         SIMULATION_G    => SIMULATION_G,
         SYNTH_MODE_G    => SYNTH_MODE_G,
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

   ----------------
   -- DPort Modules
   ----------------
   GEN_VEC : for i in 3 downto 0 generate
      U_RxPhy : entity work.AtlasRd53RxPhyCore
         generic map (
            TPD_G           => TPD_G,
            SYNTH_MODE_G    => SYNTH_MODE_G,
            AXI_BASE_ADDR_G => XBAR_CONFIG_C(DPORT0_INDEX_C+i).baseAddr)
         port map (
            -- Misc. Interfaces
            enLocalEmu      => config.enLocalEmu,
            enAuxClk        => config.enAuxClk,
            asicRst         => config.asicRst,
            batchSize       => config.batchSize,
            timerConfig     => config.timerConfig,
            iDelayCtrlRdy   => status.iDelayCtrlRdy,
            -- AXI-Lite Interface (axilClk domain)
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => axilReadMasters(DPORT0_INDEX_C+i),
            axilReadSlave   => axilReadSlaves(DPORT0_INDEX_C+i),
            axilWriteMaster => axilWriteMasters(DPORT0_INDEX_C+i),
            axilWriteSlave  => axilWriteSlaves(DPORT0_INDEX_C+i),
            -- Streaming RD43 Config Interface (clk160MHz domain)
            sConfigMaster   => rxConfigMasters(i),
            sConfigSlave    => rxConfigSlaves(i),
            mConfigMaster   => txConfigMasters(i),
            mConfigSlave    => txConfigSlaves(i),
            -- Streaming RD43 Data Interface (axilClk domain)
            mDataMaster     => txDataMasters(i),
            mDataSlave      => txDataSlaves(i),
            -- Timing/Trigger Interface
            clk640MHz       => clk640MHz,
            clk160MHz       => clk160MHz,
            clk80MHz        => clk80MHz,
            clk40MHz        => clk40MHz,
            rst640MHz       => rst640MHz,
            rst160MHz       => rst160MHz,
            rst80MHz        => rst80MHz,
            rst40MHz        => rst40MHz,
            ttc             => ttc,
            refClk300MHz    => refClk300MHz,
            -- RD53 Ports
            dPortDataP      => dPortDataP(i),
            dPortDataN      => dPortDataN(i),
            dPortCmdP       => dPortCmdP(i),
            dPortCmdN       => dPortCmdN(i),
            dPortAuxP       => dPortAuxP(i),
            dPortAuxN       => dPortAuxN(i));
   end generate GEN_VEC;

   ---------------------
   -- Hit/Trigger Module
   ---------------------
   U_HitTrig : entity work.AtlasRd53HitTrig
      generic map(
         TPD_G           => TPD_G,
         AXI_BASE_ADDR_G => XBAR_CONFIG_C(TLU_INDEX_C).baseAddr)
      port map(
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(TLU_INDEX_C),
         axilReadSlave   => axilReadSlaves(TLU_INDEX_C),
         axilWriteMaster => axilWriteMasters(TLU_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(TLU_INDEX_C),
         -- Timing/Trigger Interface
         clk640MHz       => clk640MHz,
         clk160MHz       => clk160MHz,
         clk80MHz        => clk80MHz,
         clk40MHz        => clk40MHz,
         rst640MHz       => rst640MHz,
         rst160MHz       => rst160MHz,
         rst80MHz        => rst80MHz,
         rst40MHz        => rst40MHz,
         ttc             => ttc,
         -- Trigger and hits Ports
         dPortHitP       => dPortHitP,
         dPortHitN       => dPortHitN,
         trigInL         => trigInL,
         hitInL          => hitInL,
         hitOut          => hitOut,
         -- TLU Ports
         tluTrgClkP      => tluTrgClkP,
         tluTrgClkN      => tluTrgClkN,
         tluBsyP         => tluBsyP,
         tluBsyN         => tluBsyN,
         tluIntP         => tluIntP,
         tluIntN         => tluIntN,
         tluRstP         => tluRstP,
         tluRstN         => tluRstN);

end mapping;
