-------------------------------------------------------------------------------
-- File       : PgpLane.vhd
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
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.RceG3Pkg.all;
use work.Pgp3Pkg.all;

entity PgpLane is
   generic (
      TPD_G           : time := 1 ns;
      LANE_G          : natural;
      NUM_VC_G        : positive;
      AXI_BASE_ADDR_G : slv(31 downto 0));
   port (
      -- PGP Serial Ports
      pgpTxP          : out sl;
      pgpTxN          : out sl;
      pgpRxP          : in  sl;
      pgpRxN          : in  sl;
      -- GT Clocking
      pgpRefClk250    : in  sl;
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
end PgpLane;

architecture mapping of PgpLane is

   signal pgpClk : sl;
   signal pgpRst : sl;

   signal pgpTxIn      : Pgp3TxInType := PGP3_TX_IN_INIT_C;
   signal pgpTxOut     : Pgp3TxOutType;
   signal pgpTxMasters : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
   signal pgpTxSlaves  : AxiStreamSlaveArray(NUM_VC_G-1 downto 0);

   signal pgpRxIn      : Pgp3RxInType := PGP3_RX_IN_INIT_C;
   signal pgpRxOut     : Pgp3RxOutType;
   signal pgpRxMasters : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
   signal pgpRxCtrl    : AxiStreamCtrlArray(NUM_VC_G-1 downto 0);

begin

   -----------
   -- PGP Core
   -----------
   U_PGPv3 : entity work.Pgp3Gtx7Wrapper
      generic map(
         TPD_G            => TPD_G,
         NUM_LANES_G      => 1,
         NUM_VC_G         => 2,
         RATE_G           => false,     -- false = 6.25 Gbps
         REFCLK_TYPE_G    => PGP3_REFCLK_250_C, -- 250 MHz reference clock
         REFCLK_G         => true,      -- TRUE: use pgpRefClkIn
         EN_PGP_MON_G     => true,
         EN_GTH_DRP_G     => false,
         EN_QPLL_DRP_G    => false,
         AXIL_BASE_ADDR_G => AXI_BASE_ADDR_G,
         AXIL_CLK_FREQ_G  => 125.0E+6)
      port map (
         -- Stable Clock and Reset
         stableClk       => axilClk,
         stableRst       => axilRst,
         -- Gt Serial IO
         pgpGtTxP(0)     => pgpTxP,
         pgpGtTxN(0)     => pgpTxN,
         pgpGtRxP(0)     => pgpRxP,
         pgpGtRxN(0)     => pgpRxN,
         -- GT Clocking
         pgpRefClkIn     => pgpRefClk250,
         -- Clocking
         pgpClk(0)       => pgpClk,
         pgpClkRst(0)    => pgpRst,
         -- Non VC Rx Signals
         pgpRxIn(0)      => pgpRxIn,
         pgpRxOut(0)     => pgpRxOut,
         -- Non VC Tx Signals
         pgpTxIn(0)      => pgpTxIn,
         pgpTxOut(0)     => pgpTxOut,
         -- Frame Transmit Interface
         pgpTxMasters    => pgpTxMasters,
         pgpTxSlaves     => pgpTxSlaves,
         -- Frame Receive Interface
         pgpRxMasters    => pgpRxMasters,
         pgpRxCtrl       => pgpRxCtrl,
         -- AXI-Lite Register Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave);

   --------------
   -- PGP TX Path
   --------------
   U_Tx : entity work.PgpLaneTx
      generic map (
         TPD_G             => TPD_G,
         DMA_AXIS_CONFIG_G => RCEG3_AXIS_DMA_CONFIG_C,
         NUM_VC_G          => NUM_VC_G)
      port map (
         -- DMA Interface (dmaClk domain)
         dmaClk       => dmaClk,
         dmaRst       => dmaRst,
         dmaObMaster  => dmaObMaster,
         dmaObSlave   => dmaObSlave,
         -- PGP Interface
         pgpClk       => pgpClk,
         pgpRst       => pgpRst,
         pgpRxOut     => pgpRxOut,
         pgpTxOut     => pgpTxOut,
         pgpTxMasters => pgpTxMasters,
         pgpTxSlaves  => pgpTxSlaves);

   --------------
   -- PGP RX Path
   --------------
   U_Rx : entity work.PgpLaneRx
      generic map (
         TPD_G             => TPD_G,
         DMA_AXIS_CONFIG_G => RCEG3_AXIS_DMA_CONFIG_C,
         LANE_G            => LANE_G,
         NUM_VC_G          => NUM_VC_G)
      port map (
         -- DMA Interface (dmaClk domain)
         dmaClk       => dmaClk,
         dmaRst       => dmaRst,
         dmaIbMaster  => dmaIbMaster,
         dmaIbSlave   => dmaIbSlave,
         -- PGP RX Interface (pgpRxClk domain)
         pgpClk       => pgpClk,
         pgpRst       => pgpRst,
         pgpRxOut     => pgpRxOut,
         pgpRxMasters => pgpRxMasters,
         pgpRxCtrl    => pgpRxCtrl);

end mapping;
