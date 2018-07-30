-------------------------------------------------------------------------------
-- File       : AtlasRd53Eth.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-08
-- Last update: 2018-07-30
-------------------------------------------------------------------------------
-- Description: Wrapper for PGPv3 communication
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
use work.SsiPkg.all;
use work.Pgp3Pkg.all;
use work.EthMacPkg.all;
use work.AtlasRd53Pkg.all;

library unisim;
use unisim.vcomponents.all;

entity AtlasRd53Eth is
   generic (
      TPD_G        : time             := 1 ns;
      SIMULATION_G : boolean          := false;
      SYNTH_MODE_G : string           := "inferred";
      ETH_10G_G    : boolean          := false;
      DHCP_G       : boolean          := true;
      IP_ADDR_G    : slv(31 downto 0) := x"0A01A8C0");  -- 192.168.1.10 (before DHCP)
   port (
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : out sl;
      axilRst         : out sl;
      axilReadMaster  : out AxiLiteReadMasterType;
      axilReadSlave   : in  AxiLiteReadSlaveType;
      axilWriteMaster : out AxiLiteWriteMasterType;
      axilWriteSlave  : in  AxiLiteWriteSlaveType;
      -- Streaming RD53 Config Interface (clk160MHz domain)
      clk160MHz       : in  sl;
      rst160MHz       : in  sl;
      sConfigMasters  : in  AxiStreamMasterArray(3 downto 0);
      sConfigSlaves   : out AxiStreamSlaveArray(3 downto 0);
      mConfigMasters  : out AxiStreamMasterArray(3 downto 0);
      mConfigSlaves   : in  AxiStreamSlaveArray(3 downto 0);
      -- Streaming RD43 Data Interface (axilClk domain)
      sDataMasters    : in  AxiStreamMasterArray(3 downto 0);
      sDataSlaves     : out AxiStreamSlaveArray(3 downto 0);
      -- Stable Reference IDELAY Clock and Reset
      refClk300MHz    : out sl;
      refRst300MHz    : out sl;
      -- Link Status
      rxLinkUp        : out slv(3 downto 0) := x"0";
      txLinkUp        : out slv(3 downto 0) := x"0";
      -- ETH Ports
      ethClkP         : in  sl;
      ethClkN         : in  sl;
      ethRxP          : in  slv(3 downto 0);
      ethRxN          : in  slv(3 downto 0);
      ethTxP          : out slv(3 downto 0);
      ethTxN          : out slv(3 downto 0));
end AtlasRd53Eth;

architecture mapping of AtlasRd53Eth is

   constant CLK_FREQUENCY_C : real := ite(ETH_10G_G, 156.25E+6, 125.0E+6);

   constant SERVER_SIZE_C  : positive                                := 1;
   constant SERVER_PORTS_C : PositiveArray(SERVER_SIZE_C-1 downto 0) := (0 => 8192);

   signal ibMacMaster : AxiStreamMasterType;
   signal ibMacSlave  : AxiStreamSlaveType;
   signal obMacMaster : AxiStreamMasterType;
   signal obMacSlave  : AxiStreamSlaveType;

   signal obServerMasters : AxiStreamMasterArray(SERVER_SIZE_C-1 downto 0);
   signal obServerSlaves  : AxiStreamSlaveArray(SERVER_SIZE_C-1 downto 0);
   signal ibServerMasters : AxiStreamMasterArray(SERVER_SIZE_C-1 downto 0);
   signal ibServerSlaves  : AxiStreamSlaveArray(SERVER_SIZE_C-1 downto 0);

   constant APP_STREAMS_C     : positive                                       := 9;
   constant APP_AXIS_CONFIG_C : AxiStreamConfigArray(APP_STREAMS_C-1 downto 0) := (others => PGP3_AXIS_CONFIG_C);

   signal ethTxMasters : AxiStreamMasterArray(APP_STREAMS_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal ethTxSlaves  : AxiStreamSlaveArray(APP_STREAMS_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal ethRxMasters : AxiStreamMasterArray(APP_STREAMS_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal ethRxSlaves  : AxiStreamSlaveArray(APP_STREAMS_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

   signal ethClk   : sl;
   signal ethRst   : sl;
   signal phyReady : sl;

   signal sysClk : sl;
   signal sysRst : sl;

   signal efuse      : slv(31 downto 0);
   signal localMac   : slv(47 downto 0);
   signal rssiStatus : slv(6 downto 0);

begin

   axilClk     <= sysClk;
   axilRst     <= sysRst;
   txLinkUp(0) <= phyReady;
   rxLinkUp(0) <= rssiStatus(0);

   U_MMCM : entity work.ClockManager7
      generic map(
         TPD_G              => TPD_G,
         SIMULATION_G       => SIMULATION_G,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => false,
         FB_BUFG_G          => false,
         RST_IN_POLARITY_G  => '1',
         NUM_CLOCKS_G       => 2,
         -- MMCM attributes
         BANDWIDTH_G        => "OPTIMIZED",
         CLKIN_PERIOD_G     => ite(ETH_10G_G, 6.4, 8.0),
         DIVCLK_DIVIDE_G    => 1,
         CLKFBOUT_MULT_F_G  => ite(ETH_10G_G, 6.0, 7.5),
         CLKOUT0_DIVIDE_F_G => 3.125,   -- 300 MHz = 937.5 MHz/3.125
         CLKOUT1_DIVIDE_G   => 6)       -- 156.25 MHz = 937.5 MHz/6       
      port map(
         clkIn     => ethClk,
         rstIn     => ethRst,
         clkOut(0) => refClk300MHz,
         clkOut(1) => sysClk,
         rstOut(0) => refRst300MHz,
         rstOut(1) => sysRst);

   U_EFuse : EFUSE_USR
      port map (
         EFUSEUSR => efuse);

   localMac(23 downto 0)  <= x"56_00_08";  -- 08:00:56:XX:XX:XX (big endian SLV)   
   localMac(47 downto 24) <= efuse(31 downto 8);

   GEN_1G : if (ETH_10G_G = false) generate
      U_Eth : entity work.GigEthGtx7Wrapper
         generic map (
            TPD_G              => TPD_G,
            -- DMA/MAC Configurations
            NUM_LANE_G         => 1,
            -- QUAD PLL Configurations
            USE_GTREFCLK_G     => false,
            CLKIN_PERIOD_G     => 3.2,   -- 312.5 MHz
            DIVCLK_DIVIDE_G    => 10,    -- 31.25 MHz = (312.5 MHz/10)
            CLKFBOUT_MULT_F_G  => 32.0,  -- 1 GHz = (32 x 31.25 MHz)
            CLKOUT0_DIVIDE_F_G => 8.0,   -- 125 MHz = (1.0 GHz/8)         
            -- AXI Streaming Configurations
            AXIS_CONFIG_G      => (others => EMAC_AXIS_CONFIG_C))
         port map (
            -- Local Configurations
            localMac(0)     => localMac,
            -- Streaming DMA Interface 
            dmaClk(0)       => ethClk,
            dmaRst(0)       => ethRst,
            dmaIbMasters(0) => obMacMaster,
            dmaIbSlaves(0)  => obMacSlave,
            dmaObMasters(0) => ibMacMaster,
            dmaObSlaves(0)  => ibMacSlave,
            -- Misc. Signals
            extRst          => '0',
            phyClk          => ethClk,
            phyRst          => ethRst,
            phyReady(0)     => phyReady,
            -- MGT Clock Port
            gtClkP          => ethClkP,
            gtClkN          => ethClkN,
            -- MGT Ports
            gtTxP(0)        => ethTxP(0),
            gtTxN(0)        => ethTxN(0),
            gtRxP(0)        => ethRxP(0),
            gtRxN(0)        => ethRxN(0));
   end generate;

   GEN_10G : if (ETH_10G_G = true) generate
      U_Eth : entity work.TenGigEthGtx7Wrapper
         generic map (
            TPD_G         => TPD_G,
            REFCLK_DIV2_G => true,      -- TRUE: gtClkP/N = 312.5 MHz
            AXIS_CONFIG_G => (others => EMAC_AXIS_CONFIG_C))
         port map (
            -- Local Configurations
            localMac(0)     => localMac,
            -- Streaming DMA Interface 
            dmaClk(0)       => ethClk,
            dmaRst(0)       => ethRst,
            dmaIbMasters(0) => obMacMaster,
            dmaIbSlaves(0)  => obMacSlave,
            dmaObMasters(0) => ibMacMaster,
            dmaObSlaves(0)  => ibMacSlave,
            -- Misc. Signals
            extRst          => '0',
            phyClk          => ethClk,
            phyRst          => ethRst,
            phyReady(0)     => phyReady,
            -- MGT Clock Port (156.25 MHz)
            gtClkP          => ethClkP,
            gtClkN          => ethClkN,
            -- MGT Ports
            gtTxP(0)        => ethTxP(0),
            gtTxN(0)        => ethTxN(0),
            gtRxP(0)        => ethRxP(0),
            gtRxN(0)        => ethRxN(0));
   end generate;

   U_Gtxe2ChannelDummy : entity work.Gtxe2ChannelDummy
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 3)
      port map (
         refClk => sysClk,
         gtRxP  => ethRxP(3 downto 1),
         gtRxN  => ethRxN(3 downto 1),
         gtTxP  => ethTxP(3 downto 1),
         gtTxN  => ethTxN(3 downto 1));

   ----------------------
   -- IPv4/ARP/UDP Engine
   ----------------------
   U_UDP : entity work.UdpEngineWrapper
      generic map (
         -- Simulation Generics
         TPD_G          => TPD_G,
         -- UDP Server Generics
         SERVER_EN_G    => true,
         SERVER_SIZE_G  => SERVER_SIZE_C,
         SERVER_PORTS_G => SERVER_PORTS_C,
         -- UDP Client Generics
         CLIENT_EN_G    => false,
         -- General IPv4/ARP/DHCP Generics
         DHCP_G         => DHCP_G,
         CLK_FREQ_G     => CLK_FREQUENCY_C,
         COMM_TIMEOUT_G => 30)
      port map (
         -- Local Configurations
         localMac        => localMac,
         localIp         => IP_ADDR_G,
         -- Interface to Ethernet Media Access Controller (MAC)
         obMacMaster     => obMacMaster,
         obMacSlave      => obMacSlave,
         ibMacMaster     => ibMacMaster,
         ibMacSlave      => ibMacSlave,
         -- Interface to UDP Server engine(s)
         obServerMasters => obServerMasters,
         obServerSlaves  => obServerSlaves,
         ibServerMasters => ibServerMasters,
         ibServerSlaves  => ibServerSlaves,
         -- Clock and Reset
         clk             => ethClk,
         rst             => ethRst);

   ------------------------------------------
   -- Software's RSSI Server Interface @ 8192
   ------------------------------------------
   U_RssiServer : entity work.RssiCoreWrapper
      generic map (
         TPD_G               => TPD_G,
         APP_ILEAVE_EN_G     => true,    -- Interleaved RSSI (PackVer = 2)
         MAX_SEG_SIZE_G      => 1024,
         SEGMENT_ADDR_SIZE_G => 7,
         APP_STREAMS_G       => APP_STREAMS_C,
         APP_STREAM_ROUTES_G => (
            0                => X"00",   -- SRPv3
            1                => X"01",   -- Config[0]
            2                => X"02",   -- Config[1]
            3                => X"03",   -- Config[2]
            4                => X"04",   -- Config[3]
            5                => X"05",   -- Data[0]
            6                => X"06",   -- Data[1]
            7                => X"07",   -- Data[2]
            8                => X"08"),  -- Data[3]            
         CLK_FREQUENCY_G     => CLK_FREQUENCY_C,
         TIMEOUT_UNIT_G      => 1.0E-3,  -- In units of seconds
         SERVER_G            => true,
         RETRANSMIT_ENABLE_G => true,
         BYPASS_CHUNKER_G    => false,
         WINDOW_ADDR_SIZE_G  => 3,
         PIPE_STAGES_G       => 1,
         APP_AXIS_CONFIG_G   => APP_AXIS_CONFIG_C,
         TSP_AXIS_CONFIG_G   => EMAC_AXIS_CONFIG_C,
         INIT_SEQ_N_G        => 16#80#)
      port map (
         clk_i             => ethClk,
         rst_i             => ethRst,
         openRq_i          => '1',
         statusReg_o       => rssiStatus,
         -- Application Layer Interface
         sAppAxisMasters_i => ethTxMasters,
         sAppAxisSlaves_o  => ethTxSlaves,
         mAppAxisMasters_o => ethRxMasters,
         mAppAxisSlaves_i  => ethRxSlaves,
         -- Transport Layer Interface
         sTspAxisMaster_i  => obServerMasters(0),
         sTspAxisSlave_o   => obServerSlaves(0),
         mTspAxisMaster_o  => ibServerMasters(0),
         mTspAxisSlave_i   => ibServerSlaves(0));

   U_Lane0_Vc0 : entity work.SrpV3AxiLite
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         SYNTH_MODE_G        => SYNTH_MODE_G,
         GEN_SYNC_FIFO_G     => false,
         AXI_STREAM_CONFIG_G => PGP3_AXIS_CONFIG_C)
      port map (
         -- Streaming Slave (Rx) Interface (sAxisClk domain) 
         sAxisClk         => ethClk,
         sAxisRst         => ethRst,
         sAxisMaster      => ethRxMasters(0),
         sAxisSlave       => ethRxSlaves(0),
         -- Streaming Master (Tx) Data Interface (mAxisClk domain)
         mAxisClk         => ethClk,
         mAxisRst         => ethRst,
         mAxisMaster      => ethTxMasters(0),
         mAxisSlave       => ethTxSlaves(0),
         -- Master AXI-Lite Interface (axilClk domain)
         axilClk          => sysClk,
         axilRst          => sysRst,
         mAxilReadMaster  => axilReadMaster,
         mAxilReadSlave   => axilReadSlave,
         mAxilWriteMaster => axilWriteMaster,
         mAxilWriteSlave  => axilWriteSlave);

   PGP_LANE : for i in 3 downto 0 generate

      U_Lane0_Vc4_Vc1 : entity work.AtlasRd53Pgp3AxisFifo
         generic map (
            TPD_G               => TPD_G,
            SYNTH_MODE_G        => SYNTH_MODE_G,
            SIMULATION_G        => true,  -- Always using AXIS Slave
            SLAVE_AXI_CONFIG_G  => ssiAxiStreamConfig(4),
            MASTER_AXI_CONFIG_G => ssiAxiStreamConfig(4))
         port map (
            -- System Interface (axilClk domain)
            sysClk      => clk160MHz,
            sysRst      => rst160MHz,
            sAxisMaster => sConfigMasters(i),
            sAxisSlave  => sConfigSlaves(i),
            mAxisMaster => mConfigMasters(i),
            mAxisSlave  => mConfigSlaves(i),
            -- PGP Interface (pgpClk domain)
            pgpClk      => ethClk,
            pgpRst      => ethRst,
            pgpRxMaster => ethRxMasters(1+i),
            pgpRxSlave  => ethRxSlaves(1+i),
            pgpTxMaster => ethTxMasters(1+i),
            pgpTxSlave  => ethTxSlaves(1+i));

      U_Lane0_Vc8_Vc5 : entity work.AtlasRd53Pgp3AxisFifo
         generic map (
            TPD_G        => TPD_G,
            SYNTH_MODE_G => SYNTH_MODE_G,
            SIMULATION_G => true,       -- Using AXIS Slave
            RX_G         => false)
         port map (
            -- System Interface (axilClk domain)
            sysClk      => sysClk,
            sysRst      => sysRst,
            sAxisMaster => sDataMasters(i),
            sAxisSlave  => sDataSlaves(i),
            -- PGP Interface (pgpClk domain)
            pgpClk      => ethClk,
            pgpRst      => ethRst,
            pgpTxMaster => ethTxMasters(5+i),
            pgpTxSlave  => ethTxSlaves(5+i));

   end generate PGP_LANE;

end mapping;
