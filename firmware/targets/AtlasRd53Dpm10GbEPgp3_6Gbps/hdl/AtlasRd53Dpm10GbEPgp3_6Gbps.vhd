-------------------------------------------------------------------------------
-- File       : AtlasRd53Dpm10GbEPgp3_6Gbps.vhd
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

library unisim;
use unisim.vcomponents.all;

entity AtlasRd53Dpm10GbEPgp3_6Gbps is
   generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType);
   port (
      -- Debug
      led         : out   slv(1 downto 0) := "00";
      -- I2C
      i2cSda      : inout sl;
      i2cScl      : inout sl;
      -- Ethernet
      ethRxP      : in    slv(3 downto 0);
      ethRxM      : in    slv(3 downto 0);
      ethTxP      : out   slv(3 downto 0);
      ethTxM      : out   slv(3 downto 0);
      ethRefClkP  : in    sl;
      ethRefClkM  : in    sl;
      -- RTM Interface
      locRefClkP  : in    sl;
      locRefClkM  : in    sl;
      dpmToRtmHsP : out   slv(11 downto 0);
      dpmToRtmHsM : out   slv(11 downto 0);
      rtmToDpmHsP : in    slv(11 downto 0);
      rtmToDpmHsM : in    slv(11 downto 0);
      -- DTM Signals
      dtmClkP     : in    slv(1 downto 0);
      dtmClkM     : in    slv(1 downto 0);
      dtmFbP      : out   sl;
      dtmFbM      : out   sl;
      -- Clock Select
      clkSelA     : out   slv(1 downto 0);
      clkSelB     : out   slv(1 downto 0));
end AtlasRd53Dpm10GbEPgp3_6Gbps;

architecture TOP_LEVEL of AtlasRd53Dpm10GbEPgp3_6Gbps is

   signal ref200Clk : sl;
   signal ref200Rst : sl;

   signal dmaClk : slv(2 downto 0);
   signal dmaRst : slv(2 downto 0);

   signal dmaObMasters : AxiStreamMasterArray(2 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal dmaObSlaves  : AxiStreamSlaveArray(2 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal dmaIbMasters : AxiStreamMasterArray(2 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal dmaIbSlaves  : AxiStreamSlaveArray(2 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

   signal axilClk         : sl;
   signal axilRst         : sl;
   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType;

begin

   -----------
   -- DPM Core
   -----------
   U_DpmCore : entity work.DpmCore
      generic map (
         TPD_G          => TPD_G,
         BUILD_INFO_G   => BUILD_INFO_G,
         RCE_DMA_MODE_G => RCE_DMA_AXISV2_C,  -- AXIS V2 Driver
         ETH_10G_EN_G   => true)              -- 10 GbE XAUI
      port map (
         -- I2C
         i2cSda             => i2cSda,
         i2cScl             => i2cScl,
         -- Ethernet
         ethRxP             => ethRxP,
         ethRxM             => ethRxM,
         ethTxP             => ethTxP,
         ethTxM             => ethTxM,
         ethRefClkP         => ethRefClkP,
         ethRefClkM         => ethRefClkM,
         -- Clock Select
         clkSelA            => clkSelA,
         clkSelB            => clkSelB,
         -- Clocks and Resets
         sysClk125          => open,
         sysClk125Rst       => open,
         sysClk200          => ref200Clk,
         sysClk200Rst       => ref200Rst,
         -- External AXI-Lite Interface [0xA0000000:0xAFFFFFFF]
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
         dmaIbSlave         => dmaIbSlaves);

   ----------------------------------
   -- DMA clock and reset assignments
   ----------------------------------
   dmaClk <= (others => ref200Clk);
   dmaRst <= (others => ref200Rst);

   --------------------
   -- DTM Clock Signals
   --------------------
   U_DtmClkgen : for i in 0 to 1 generate
      U_DtmClkIn : IBUFDS
         generic map (
            DIFF_TERM => true)
         port map(
            I  => dtmClkP(i),
            IB => dtmClkM(i),
            O  => open);
   end generate;

   ---------------
   -- DTM Feedback
   ---------------
   U_DtmFbOut : OBUFDS
      port map(
         O  => dtmFbP,
         OB => dtmFbM,
         I  => '0');

   -----------------
   -- DMA[0] = PGPv3
   -----------------
   U_Hardware : entity work.DpmPgpLaneWrapper
      generic map (
         TPD_G           => TPD_G,
         AXI_BASE_ADDR_G => x"A0000000")
      port map (
         -- RTM Interface
         refClk250P      => locRefClkP,
         refClk250N      => locRefClkM,
         dpmToRtmHsP     => dpmToRtmHsP,
         dpmToRtmHsN     => dpmToRtmHsM,
         rtmToDpmHsP     => rtmToDpmHsP,
         rtmToDpmHsN     => rtmToDpmHsM,
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

end architecture TOP_LEVEL;
