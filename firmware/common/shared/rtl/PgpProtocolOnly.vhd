-------------------------------------------------------------------------------
-- File       : PgpProtocolOnly.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-26
-- Last update: 2018-06-29
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.Pgp3Pkg.all;

entity PgpProtocolOnly is
   generic (
      TPD_G             : time     := 1 ns;
      SYNTH_MODE_G      : string   := "inferred";
      DMA_AXIS_CONFIG_G : AxiStreamConfigType;
      NUM_VC_G          : positive := 1);
   port (
      -- DMA Interface (dmaClk domain)
      dmaClk      : in  sl;
      dmaRst      : in  sl;
      pgpTxOut    : out Pgp3TxOutType;
      pgpRxOut    : out Pgp3RxOutType;
      dmaIbMaster : out AxiStreamMasterType;
      dmaIbSlave  : in  AxiStreamSlaveType;
      dmaObMaster : in  AxiStreamMasterType;
      dmaObSlave  : out AxiStreamSlaveType);
end PgpProtocolOnly;

architecture mapping of PgpProtocolOnly is

   signal pgpTxMasters : AxiStreamMasterArray(NUM_VC_G-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal pgpTxSlaves  : AxiStreamSlaveArray(NUM_VC_G-1 downto 0)  := (others => AXI_STREAM_SLAVE_INIT_C);
   signal pgpRxMasters : AxiStreamMasterArray(NUM_VC_G-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal pgpRxCtrl    : AxiStreamCtrlArray(NUM_VC_G-1 downto 0)   := (others => AXI_STREAM_CTRL_INIT_C);

   signal phyData   : slv(63 downto 0) := (others => '0');
   signal phyHeader : slv(1 downto 0)  := (others => '0');

begin

   U_Tx : entity work.PgpLaneTx
      generic map (
         TPD_G             => TPD_G,
         SYNTH_MODE_G      => SYNTH_MODE_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
         PGP_AXIS_CONFIG_G => PGP3_AXIS_CONFIG_C,
         NUM_VC_G          => NUM_VC_G)
      port map (
         -- DMA Interface (dmaClk domain)
         dmaClk       => dmaClk,
         dmaRst       => dmaRst,
         dmaObMaster  => dmaObMaster,
         dmaObSlave   => dmaObSlave,
         -- PGP Interface
         pgpClk       => dmaClk,
         pgpRst       => dmaRst,
         rxlinkReady  => '1',
         txlinkReady  => '1',
         pgpTxMasters => pgpTxMasters,
         pgpTxSlaves  => pgpTxSlaves);

   U_Pgp3Core : entity work.Pgp3Core
      generic map (
         TPD_G        => TPD_G,
         SYNTH_MODE_G => SYNTH_MODE_G,
         NUM_VC_G     => NUM_VC_G)
      port map (
         -- Tx User interface
         pgpTxClk        => dmaClk,
         pgpTxRst        => dmaRst,
         pgpTxIn         => PGP3_TX_IN_INIT_C,
         pgpTxOut        => pgpTxOut,
         pgpTxMasters    => pgpTxMasters,
         pgpTxSlaves     => pgpTxSlaves,
         -- Tx PHY interface
         phyTxActive     => '1',
         phyTxReady      => '1',
         phyTxStart      => open,
         phyTxSequence   => open,
         phyTxData       => phyData,
         phyTxHeader     => phyHeader,
         -- Rx User interface
         pgpRxClk        => dmaClk,
         pgpRxRst        => dmaRst,
         pgpRxIn         => PGP3_RX_IN_INIT_C,
         pgpRxOut        => pgpRxOut,
         pgpRxMasters    => pgpRxMasters,
         pgpRxCtrl       => pgpRxCtrl,
         -- Rx PHY interface
         phyRxClk        => dmaClk,
         phyRxRst        => dmaRst,
         phyRxActive     => '1',
         phyRxValid      => '1',
         phyRxHeader     => phyHeader,
         phyRxData       => phyData,
         phyRxStartSeq   => '0',
         -- AXI-Lite Register Interface (axilClk domain)
         axilClk         => dmaClk,
         axilRst         => dmaRst,
         axilReadMaster  => AXI_LITE_READ_MASTER_INIT_C,
         axilReadSlave   => open,
         axilWriteMaster => AXI_LITE_WRITE_MASTER_INIT_C,
         axilWriteSlave  => open);

   U_Rx : entity work.PgpLaneRx
      generic map (
         TPD_G             => TPD_G,
         SYNTH_MODE_G      => SYNTH_MODE_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
         PGP_AXIS_CONFIG_G => PGP3_AXIS_CONFIG_C,
         LANE_G            => 0,
         NUM_VC_G          => NUM_VC_G)
      port map (
         -- DMA Interface (dmaClk domain)
         dmaClk       => dmaClk,
         dmaRst       => dmaRst,
         dmaIbMaster  => dmaIbMaster,
         dmaIbSlave   => dmaIbSlave,
         -- PGP RX Interface (pgpRxClk domain)
         pgpClk       => dmaClk,
         pgpRst       => dmaRst,
         rxlinkReady  => '1',
         pgpRxMasters => pgpRxMasters,
         pgpRxCtrl    => pgpRxCtrl);

end mapping;
