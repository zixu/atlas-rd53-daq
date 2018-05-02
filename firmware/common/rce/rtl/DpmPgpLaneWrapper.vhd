-------------------------------------------------------------------------------
-- File       : DpmPgpLaneWrapper.vhd
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.BuildInfoPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.RceG3Pkg.all;
use work.Pgp3Pkg.all;

library unisim;
use unisim.vcomponents.all;

entity DpmPgpLaneWrapper is
   generic (
      TPD_G           : time             := 1 ns;
      AXI_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      -- RTM Interface
      refClk250P      : in  sl;
      refClk250N      : in  sl;
      dpmToRtmHsP     : out slv(11 downto 0);
      dpmToRtmHsN     : out slv(11 downto 0);
      rtmToDpmHsP     : in  slv(11 downto 0);
      rtmToDpmHsN     : in  slv(11 downto 0);
      -- DMA Interface (dmaClk domain)
      dmaClk          : in  sl;
      dmaRst          : in  sl;
      dmaObMaster     : in  AxiStreamMasterType;
      dmaObSlave      : out AxiStreamSlaveType;
      dmaIbMaster     : out AxiStreamMasterType;
      dmaIbSlave      : in  AxiStreamSlaveType;
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end DpmPgpLaneWrapper;

architecture mapping of DpmPgpLaneWrapper is

   constant NUM_LANE_C : natural := 2;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_LANE_C-1 downto 0) := genAxiLiteConfig(NUM_LANE_C, AXI_BASE_ADDR_G, 20, 16);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_LANE_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_LANE_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_LANE_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_LANE_C-1 downto 0);

   signal dmaObMasters : AxiStreamMasterArray(NUM_LANE_C-1 downto 0);
   signal dmaObSlaves  : AxiStreamSlaveArray(NUM_LANE_C-1 downto 0);
   signal dmaIbMasters : AxiStreamMasterArray(NUM_LANE_C-1 downto 0);
   signal dmaIbSlaves  : AxiStreamSlaveArray(NUM_LANE_C-1 downto 0);

   signal pgpTxP : slv(NUM_LANE_C-1 downto 0);
   signal pgpTxN : slv(NUM_LANE_C-1 downto 0);
   signal pgpRxP : slv(NUM_LANE_C-1 downto 0);
   signal pgpRxN : slv(NUM_LANE_C-1 downto 0);

   signal refClk250 : sl;

begin

   ------------------------
   -- Common PGP Clocking
   ------------------------
   U_IBUFDS_GTE2 : IBUFDS_GTE2
      port map (
         I     => refClk250P,
         IB    => refClk250N,
         CEB   => '0',
         O     => refClk250,
         ODIV2 => open);


   --------------------------------
   -- Mapping RTM[0] to PGP[0]
   --------------------------------
   dpmToRtmHsP(0) <= pgpTxP(0);
   dpmToRtmHsN(0) <= pgpTxN(0);
   pgpRxP(0)      <= rtmToDpmHsP(0);
   pgpRxN(0)      <= rtmToDpmHsN(0);

   ---------------------
   -- Terminate RTM[5:1]
   ---------------------   
   U_UnusedGtx7_A : entity work.Gtxe2ChannelDummy
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 5)
      port map (
         refClk => axilClk,
         gtRxP  => rtmToDpmHsP(5 downto 1),
         gtRxN  => rtmToDpmHsN(5 downto 1),
         gtTxP  => dpmToRtmHsP(5 downto 1),
         gtTxN  => dpmToRtmHsN(5 downto 1));

   --------------------------------
   -- Mapping RTM[6] to PGP[1]
   --------------------------------
   dpmToRtmHsP(6) <= pgpTxP(1);
   dpmToRtmHsN(6) <= pgpTxN(1);
   pgpRxP(1)      <= rtmToDpmHsP(6);
   pgpRxN(1)      <= rtmToDpmHsN(6);

   ---------------------
   -- Terminate RTM[11:7]
   ---------------------   
   U_UnusedGtx7_B : entity work.Gtxe2ChannelDummy
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 5)
      port map (
         refClk => axilClk,
         gtRxP  => rtmToDpmHsP(11 downto 7),
         gtRxN  => rtmToDpmHsN(11 downto 7),
         gtTxP  => dpmToRtmHsP(11 downto 7),
         gtTxN  => dpmToRtmHsN(11 downto 7));

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_LANE_C,
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

   ------------
   -- PGP Lanes
   ------------
   GEN_LANE : for i in NUM_LANE_C-1 downto 0 generate

      U_Lane : entity work.PgpLane
         generic map (
            TPD_G           => TPD_G,
            LANE_G          => i,
            NUM_VC_G        => 2,
            AXI_BASE_ADDR_G => AXI_CONFIG_C(i).baseAddr)
         port map (
            -- PGP Serial Ports
            pgpRxP          => pgpRxP(i),
            pgpRxN          => pgpRxN(i),
            pgpTxP          => pgpTxP(i),
            pgpTxN          => pgpTxN(i),
            -- GT Clocking
            pgpRefClk250    => refClk250,
            -- DMA Interface (dmaClk domain)
            dmaClk          => dmaClk,
            dmaRst          => dmaRst,
            dmaObMaster     => dmaObMasters(i),
            dmaObSlave      => dmaObSlaves(i),
            dmaIbMaster     => dmaIbMasters(i),
            dmaIbSlave      => dmaIbSlaves(i),
            -- AXI-Lite Interface (axilClk domain)
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => axilReadMasters(i),
            axilReadSlave   => axilReadSlaves(i),
            axilWriteMaster => axilWriteMasters(i),
            axilWriteSlave  => axilWriteSlaves(i));

   end generate GEN_LANE;

   U_Mux : entity work.AxiStreamMux
      generic map (
         TPD_G                => TPD_G,
         NUM_SLAVES_G         => NUM_LANE_C,
         MODE_G               => "ROUTED",
         TDEST_ROUTES_G       => (0 => "0000000-", 1 => "0000001-"),
         ILEAVE_EN_G          => true,
         ILEAVE_ON_NOTVALID_G => false,
         ILEAVE_REARB_G       => 128,
         PIPE_STAGES_G        => 1)
      port map (
         -- Clock and reset
         axisClk      => dmaClk,
         axisRst      => dmaRst,
         -- Slaves
         sAxisMasters => dmaIbMasters,
         sAxisSlaves  => dmaIbSlaves,
         -- Master
         mAxisMaster  => dmaIbMaster,
         mAxisSlave   => dmaIbSlave);

   U_DeMux : entity work.AxiStreamDeMux
      generic map (
         TPD_G          => TPD_G,
         NUM_MASTERS_G  => NUM_LANE_C,
         MODE_G         => "ROUTED",
         TDEST_ROUTES_G => (0 => "0000000-", 1 => "0000001-"),
         PIPE_STAGES_G  => 1)
      port map (
         -- Clock and reset
         axisClk      => dmaClk,
         axisRst      => dmaRst,
         -- Slave         
         sAxisMaster  => dmaObMaster,
         sAxisSlave   => dmaObSlave,
         -- Masters
         mAxisMasters => dmaObMasters,
         mAxisSlaves  => dmaObSlaves);

end mapping;
