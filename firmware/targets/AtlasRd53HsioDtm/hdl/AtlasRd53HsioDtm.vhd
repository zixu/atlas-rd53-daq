-------------------------------------------------------------------------------
-- File       : AtlasRd53HsioDtm.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-05-01
-- Last update: 2018-06-13
-------------------------------------------------------------------------------
-- Description: 
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
use work.RceG3Pkg.all;

entity AtlasRd53HsioDtm is
   generic (
      TPD_G          : time   := 1 ns;
      DEBUG_DMA_CH_G : string := "loopback";
      -- DEBUG_DMA_CH_G : string  := "PGPv3";
      BUILD_INFO_G   : BuildInfoType);
   port (
      -- Debug
      led          : out   slv(1 downto 0) := "00";
      -- I2C
      i2cSda       : inout sl;
      i2cScl       : inout sl;
      -- Clock Select
      clkSelA      : out   sl;
      clkSelB      : out   sl;
      -- Base Ethernet
      ethRxCtrl    : in    slv(1 downto 0);
      ethRxClk     : in    slv(1 downto 0);
      ethRxDataA   : in    Slv(1 downto 0);
      ethRxDataB   : in    Slv(1 downto 0);
      ethRxDataC   : in    Slv(1 downto 0);
      ethRxDataD   : in    Slv(1 downto 0);
      ethTxCtrl    : out   slv(1 downto 0);
      ethTxClk     : out   slv(1 downto 0);
      ethTxDataA   : out   Slv(1 downto 0);
      ethTxDataB   : out   Slv(1 downto 0);
      ethTxDataC   : out   Slv(1 downto 0);
      ethTxDataD   : out   Slv(1 downto 0);
      ethMdc       : out   Slv(1 downto 0);
      ethMio       : inout Slv(1 downto 0);
      ethResetL    : out   Slv(1 downto 0);

      busyOutP    : out sl;
      busyOutM    : out sl;
      lolInP      : in sl;
      lolInM      : in sl;
      sdInP       : in sl;
      sdInM       : in sl;
      idpmFbP: in slv(3 downto 0);
      idpmFbM: in slv(3 downto 0);
      odpmFbP: out slv(3 downto 0);
      odpmFbM: out slv(3 downto 0);

      -- IPMI
      dtmToIpmiP   : out   slv(1 downto 0);
      dtmToIpmiM   : out   slv(1 downto 0);
      -- Reference Clock
      locRefClk1P  : in    sl;
      locRefClk1M  : in    sl;
      -- SFP High Speed
      dtmToFpgaHsP : out   sl;
      dtmToFpgaHsM : out   sl;
      fpgaToDtmHsP : in    sl;
      fpgaToDtmHsM : in    sl;
      -- SFP High Speed
      dtmToSfpHsP  : out   sl;
      dtmToSfpHsM  : out   sl;
      sfpToDtmHsP  : in    sl;
      sfpToDtmHsM  : in    sl);
end AtlasRd53HsioDtm;

architecture TOP_LEVEL of AtlasRd53HsioDtm is

   constant NUM_AXIL_MASTERS_C : natural := 2;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, x"A0000000", 25, 24);

   signal axilClk         : sl;
   signal axilRst         : sl;
   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType;

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);

   signal dmaClk       : slv(3 downto 0);
   signal dmaRst       : slv(3 downto 0);
   signal dmaObMasters : AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal dmaObSlaves  : AxiStreamSlaveArray(3 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal dmaIbMasters : AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal dmaIbSlaves  : AxiStreamSlaveArray(3 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

   signal ref200Clk : sl;
   signal ref200Rst : sl;
   signal locRefClk : sl;

   signal idpmFb              : slv(3 downto 0);
   signal odpmFb              : slv(3 downto 0);
   signal lol                 : sl;


begin

   -----------
   -- DTM Core
   -----------
   U_HsioCore : entity work.HsioCore
      generic map (
         TPD_G          => TPD_G,
         BUILD_INFO_G   => BUILD_INFO_G,
         RCE_DMA_MODE_G => RCE_DMA_AXISV2_C)  -- AXIS V2 Driver
      port map (
         -- I2C
         i2cSda             => i2cSda,
         i2cScl             => i2cScl,
         -- Clock Select
         clkSelA            => clkSelA,
         clkSelB            => clkSelB,
         -- Base Ethernet
         ethRxCtrl          => ethRxCtrl,
         ethRxClk           => ethRxClk,
         ethRxDataA         => ethRxDataA,
         ethRxDataB         => ethRxDataB,
         ethRxDataC         => ethRxDataC,
         ethRxDataD         => ethRxDataD,
         ethTxCtrl          => ethTxCtrl,
         ethTxClk           => ethTxClk,
         ethTxDataA         => ethTxDataA,
         ethTxDataB         => ethTxDataB,
         ethTxDataC         => ethTxDataC,
         ethTxDataD         => ethTxDataD,
         ethMdc             => ethMdc,
         ethMio             => ethMio,
         ethResetL          => ethResetL,
         -- IPMI
         dtmToIpmiP         => dtmToIpmiP,
         dtmToIpmiM         => dtmToIpmiM,
         -- Clocks
         sysClk200          => ref200Clk,
         sysClk200Rst       => ref200Rst,
         -- External Axi Bus, 0xA0000000 - 0xAFFFFFFF
         axiClk             => axilClk,
         axiClkRst          => axilRst,
         extAxilReadMaster  => axilReadMaster,
         extAxilReadSlave   => axilReadSlave,
         extAxilWriteMaster => axilWriteMaster,
         extAxilWriteSlave  => axilWriteSlave,
         -- DMA Interfaces
         dmaClk             => dmaClk,
         dmaClkRst          => dmaRst,
         dmaObMaster        => dmaObMasters,
         dmaObSlave         => dmaObSlaves,
         dmaIbMaster        => dmaIbMasters,
         dmaIbSlave         => dmaIbSlaves,
         -- User Interrupts
         userInterrupt      => (others => '0'));

   --------------------------
   -- AXI-Lite: Crossbar Core
   --------------------------  
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CONFIG_C)
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

   ----------------------------------
   -- DMA clock and reset assignments
   ----------------------------------
   dmaClk(0) <= ref200Clk;
   dmaRst(0) <= ref200Rst;

   dmaClk(1) <= axilClk;
   dmaRst(1) <= axilRst;

   dmaClk(2) <= ref200Clk;
   dmaRst(2) <= ref200Rst;

   dmaClk(3) <= ref200Clk;
   dmaRst(3) <= ref200Rst;

   ---------------------------------------   
   -- DMA[2] = PGPv2b to HSIO Artix-7 FPGA
   ---------------------------------------   
   U_HsioPgpLane : entity work.HsioPgpLane
      generic map (
         TPD_G => TPD_G)
      port map (
         sysClk200       => ref200Clk,
         locRefClk       => locRefClk,
         -- AXI-Lite Interface (axilClk domain): 0xA1000000 - 0xA1FFFFFF
         axiClk          => axilClk,
         axiClkRst       => axilRst,
         axiReadMaster   => axilReadMasters(1),
         axiReadSlave    => axilReadSlaves(1),
         axiWriteMaster  => axilWriteMasters(1),
         axiWriteSlave   => axilWriteSlaves(1),
         -- DMA Interfaces (dmaClk domain)
         pgpAxisClk      => dmaClk(0),
         pgpAxisRst      => dmaRst(0),
         pgpDataRxMaster => dmaIbMasters(0),
         pgpDataRxSlave  => dmaIbSlaves(0),
         pgpDataTxMaster => dmaObMasters(0),
         pgpDataTxSlave  => dmaObSlaves(0),
         -- FPGA Interface
         pgpTxP          => dtmToFpgaHsP,
         pgpTxM          => dtmToFpgaHsM,
         pgpRxP          => fpgaToDtmHsP,
         pgpRxM          => fpgaToDtmHsM);


   GEN_LOOPBACK : if (DEBUG_DMA_CH_G = "loopback") generate
      --------------------
      -- DMA[1] = Loopback
      --------------------
      dmaIbMasters(1) <= dmaObMasters(1);
      dmaObSlaves(1)  <= dmaIbSlaves(1);
   end generate;

   GEN_PGPv3 : if (DEBUG_DMA_CH_G = "PGPv3") generate
      ---------------------------
      -- DMA[1] = PgpProtocolOnly
      ---------------------------
      U_PgpProtocolOnly : entity work.PgpProtocolOnly
         generic map (
            TPD_G             => TPD_G,
            DMA_AXIS_CONFIG_G => RCEG3_AXIS_DMA_CONFIG_C)
         port map (
            dmaClk      => dmaClk(1),
            dmaRst      => dmaRst(1),
            dmaObMaster => dmaObMasters(1),
            dmaObSlave  => dmaObSlaves(1),
            dmaIbMaster => dmaIbMasters(1),
            dmaIbSlave  => dmaIbSlaves(1));
   end generate;

   GEN_SRP_TEST : if (DEBUG_DMA_CH_G = "SRPv3") generate
      --------------------
      -- DMA[1] = SRP Test
      --------------------
      U_DmaSrpTest : entity work.DmaSrpTest
         generic map (
            TPD_G        => TPD_G,
            BUILD_INFO_G => BUILD_INFO_G)
         port map (
            clk         => dmaClk(1),
            rst         => dmaRst(1),
            dmaObMaster => dmaObMasters(1),
            dmaObSlave  => dmaObSlaves(1),
            dmaIbMaster => dmaIbMasters(1),
            dmaIbSlave  => dmaIbSlaves(1));
   end generate;

   ------------------------
   -- DMA[2] = PGPv3 to FEB
   ------------------------
   U_Hardware : entity work.DtmPgpLaneWrapper
      generic map (
         TPD_G           => TPD_G,
         AXI_BASE_ADDR_G => x"A0000000")
      port map (
         -- SFP Interface
         refClk250P      => locRefClk1P,
         refClk250N      => locRefClk1M,
         refClk250       => locRefClk,
         dtmToRtmHsP     => dtmToSfpHsP,
         dtmToRtmHsN     => dtmToSfpHsM,
         rtmToDtmHsP     => sfpToDtmHsP,
         rtmToDtmHsN     => sfpToDtmHsM,
         -- DMA Interfaces (dmaClk domain)
         dmaClk          => dmaClk(2),
         dmaRst          => dmaRst(2),
         dmaObMaster     => dmaObMasters(2),
         dmaObSlave      => dmaObSlaves(2),
         dmaIbMaster     => dmaIbMasters(2),
         dmaIbSlave      => dmaIbSlaves(2),
         -- AXI-Lite Interface (axilClk domain): 0xA0000000 - 0xA0FFFFFF
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(0),
         axilReadSlave   => axilReadSlaves(0),
         axilWriteMaster => axilWriteMasters(0),
         axilWriteSlave  => axilWriteSlaves(0));

   -----------------------------------------
   -- DMA[3] = Not Connected in HsioCore.vhd
   -----------------------------------------
   dmaIbMasters(3) <= dmaObMasters(3);
   dmaObSlaves(3)  <= dmaIbSlaves(3);

  -- DPM Feedback Signals
   U_DpmFbGen : for i in 0 to 3 generate
      U_DpmFbIn : IBUFDS
         generic map ( DIFF_TERM => true ) 
         port map(
            I      => idpmFbP(i),
            IB     => idpmFbM(i),
            O      => idpmFb(i)
         );
      U_DpmFbOut : OBUFDS
         port map(
            O      => odpmFbP(i),
            OB     => odpmFbM(i),
            I      => odpmFb(i)
         );
   end generate;
      U_BusyOut : OBUFDS
         port map(
            O      => busyOutP,
            OB     => busyOutM,
            I      => idpmFb(0) 
         );
      U_sdIn : IBUFDS
         generic map ( DIFF_TERM => true ) 
         port map(
            I      => sdInP,
            IB     => sdInM,
            O      => odpmFb(0)
         );
      U_lolIn : IBUFDS
         generic map ( DIFF_TERM => true ) 
         port map(
            I      => lolInP,
            IB     => lolInM,
            O      => lol
         );
   odpmFb(1)<= not lol;
 

end architecture TOP_LEVEL;
