-------------------------------------------------------------------------------
-- File       : AtlasRd53HsioPgp3_6Gbps.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-05-01
-- Last update: 2018-05-01
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

entity AtlasRd53HsioPgp3_6Gbps is
   generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType);
   port (
      -- Debug
      led         : out   slv(1 downto 0) := "00";
      -- I2C
      i2cSda      : inout sl;
      i2cScl      : inout sl;
      -- Clock Select
      clkSelA     : out   sl;
      clkSelB     : out   sl;
      -- Base Ethernet
      ethRxCtrl   : in    slv(1 downto 0);
      ethRxClk    : in    slv(1 downto 0);
      ethRxDataA  : in    Slv(1 downto 0);
      ethRxDataB  : in    Slv(1 downto 0);
      ethRxDataC  : in    Slv(1 downto 0);
      ethRxDataD  : in    Slv(1 downto 0);
      ethTxCtrl   : out   slv(1 downto 0);
      ethTxClk    : out   slv(1 downto 0);
      ethTxDataA  : out   Slv(1 downto 0);
      ethTxDataB  : out   Slv(1 downto 0);
      ethTxDataC  : out   Slv(1 downto 0);
      ethTxDataD  : out   Slv(1 downto 0);
      ethMdc      : out   Slv(1 downto 0);
      ethMio      : inout Slv(1 downto 0);
      ethResetL   : out   Slv(1 downto 0);
      -- IPMI
      dtmToIpmiP  : out   slv(1 downto 0);
      dtmToIpmiM  : out   slv(1 downto 0);
      -- Reference Clock
      locRefClk1P : in    sl;
      locRefClk1M : in    sl;
      -- RTM High Speed
      dtmToRtmHsP : out   sl;
      dtmToRtmHsM : out   sl;
      rtmToDtmHsP : in    sl;
      rtmToDtmHsM : in    sl);
end AtlasRd53HsioPgp3_6Gbps;

architecture TOP_LEVEL of AtlasRd53HsioPgp3_6Gbps is

   signal ref200Clk : sl;
   signal ref200Rst : sl;

   signal dmaClk : slv(3 downto 0);
   signal dmaRst : slv(3 downto 0);

   signal dmaObMasters : AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal dmaObSlaves  : AxiStreamSlaveArray(3 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal dmaIbMasters : AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal dmaIbSlaves  : AxiStreamSlaveArray(3 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

   signal axilClk         : sl;
   signal axilRst         : sl;
   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType;

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

   ----------------------------------
   -- DMA clock and reset assignments
   ----------------------------------
   dmaClk <= (others => ref200Clk);
   dmaRst <= (others => ref200Rst);

   -----------------
   -- DMA[0] = PGPv3
   -----------------
   U_Hardware : entity work.DtmPgpLaneWrapper
      generic map (
         TPD_G           => TPD_G,
         AXI_BASE_ADDR_G => x"A0000000")
      port map (
         -- RTM Interface
         refClk250P      => locRefClk1P,
         refClk250N      => locRefClk1M,
         dtmToRtmHsP     => dtmToRtmHsP,
         dtmToRtmHsN     => dtmToRtmHsM,
         rtmToDtmHsP     => rtmToDtmHsP,
         rtmToDtmHsN     => rtmToDtmHsM,
         -- DMA Interfaces (dmaClk domain)
         dmaClk          => dmaClk(0),
         dmaRst          => dmaRst(0),
         dmaObMaster     => dmaObMasters(0),
         dmaObSlave      => dmaObSlaves(0),
         dmaIbMaster     => dmaIbMasters(0),
         dmaIbSlave      => dmaIbSlaves(0),
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave);

   --------------------
   -- DMA[1] = Loopback
   --------------------
   dmaIbMasters(1) <= dmaObMasters(1);
   dmaObSlaves(1)  <= dmaIbSlaves(1);

   --------------------
   -- DMA[2] = Loopback
   --------------------
   dmaIbMasters(2) <= dmaObMasters(2);
   dmaObSlaves(2)  <= dmaIbSlaves(2);

   --------------------
   -- DMA[3] = Loopback
   --------------------
   dmaIbMasters(3) <= dmaObMasters(3);
   dmaObSlaves(3)  <= dmaIbSlaves(3);

end architecture TOP_LEVEL;
