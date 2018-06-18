-------------------------------------------------------------------------------
-- File       : AtlasRd53Pgp3.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-08
-- Last update: 2018-06-02
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
use work.Pgp3Pkg.all;
use work.AtlasRd53Pkg.all;

entity AtlasRd53Pgp3 is
   generic (
      TPD_G       : time   := 1 ns;
      PGP3_RATE_G : string := "6.25Gbps");  -- or "10.3125Gbps"  
   port (
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : out sl;
      axilRst         : out sl;
      axilReadMaster  : out AxiLiteReadMasterType;
      axilReadSlave   : in  AxiLiteReadSlaveType;
      axilWriteMaster : out AxiLiteWriteMasterType;
      axilWriteSlave  : in  AxiLiteWriteSlaveType;
      -- Streaming RD43 Data Interface (axilClk domain)
      sDataMasters    : in  AxiStreamMasterArray(3 downto 0);
      sDataSlaves     : out AxiStreamSlaveArray(3 downto 0);
      -- Streaming TLU Interface (axilClk domain)
      sTluMaster      : in  AxiStreamMasterType;
      sTluSlave       : out AxiStreamSlaveType;
      mTluMaster      : out AxiStreamMasterType;
      mTluSlave       : in  AxiStreamSlaveType;
      -- Stable Reference IDELAY Clock and Reset
      refClk300MHz    : out sl;
      refRst300MHz    : out sl;
      -- Link Status
      rxLinkUp        : out slv(3 downto 0);
      txLinkUp        : out slv(3 downto 0);
      -- PGP Ports
      pgpClkP         : in  sl;
      pgpClkN         : in  sl;
      pgpRxP          : in  slv(3 downto 0);
      pgpRxN          : in  slv(3 downto 0);
      pgpTxP          : out slv(3 downto 0);
      pgpTxN          : out slv(3 downto 0));
end AtlasRd53Pgp3;

architecture mapping of AtlasRd53Pgp3 is

   signal pgpRxIn  : Pgp3RxInArray(3 downto 0)  := (others => PGP3_RX_IN_INIT_C);
   signal pgpRxOut : Pgp3RxOutArray(3 downto 0) := (others => PGP3_RX_OUT_INIT_C);

   signal pgpTxIn  : Pgp3TxInArray(3 downto 0)  := (others => PGP3_TX_IN_INIT_C);
   signal pgpTxOut : Pgp3TxOutArray(3 downto 0) := (others => PGP3_TX_OUT_INIT_C);

   signal pgpTxMasters : AxiStreamMasterArray(5 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal pgpTxSlaves  : AxiStreamSlaveArray(5 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal pgpRxMasters : AxiStreamMasterArray(5 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal pgpRxCtrl    : AxiStreamCtrlArray(5 downto 0)   := (others => AXI_STREAM_CTRL_UNUSED_C);

   signal pgpClk : slv(3 downto 0) := x"0";
   signal pgpRst : slv(3 downto 0) := x"0";

   signal pgpRefClkDiv2    : sl;
   signal pgpRefClkDiv2Rst : sl;

   signal sysClk : sl;
   signal sysRst : sl;

   -- attribute dont_touch             : string;
   -- attribute dont_touch of pgpRxOut : signal is "TRUE";
   -- attribute dont_touch of pgpTxOut : signal is "TRUE";

begin

   axilClk <= sysClk;
   axilRst <= sysRst;

   U_PwrUpRst : entity work.PwrUpRst
      generic map(
         TPD_G => TPD_G)
      port map (
         clk    => pgpRefClkDiv2,
         rstOut => pgpRefClkDiv2Rst);

   U_MMCM : entity work.ClockManager7
      generic map(
         TPD_G              => TPD_G,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => false,
         FB_BUFG_G          => false,
         RST_IN_POLARITY_G  => '1',
         NUM_CLOCKS_G       => 2,
         -- MMCM attributes
         BANDWIDTH_G        => "OPTIMIZED",
         CLKIN_PERIOD_G     => 6.4,     -- 156.25 MHz
         DIVCLK_DIVIDE_G    => 1,       -- 156.25 MHz = 156.25 MHz/1
         CLKFBOUT_MULT_F_G  => 6.0,     -- 937.5 MHz = 156.25 MHz x 6     
         CLKOUT0_DIVIDE_F_G => 3.125,   -- 300 MHz = 937.5 MHz/3.125
         CLKOUT1_DIVIDE_G   => 6)       -- 156.25 MHz = 937.5 MHz/6       
      port map(
         clkIn     => pgpRefClkDiv2,
         rstIn     => pgpRefClkDiv2Rst,
         clkOut(0) => refClk300MHz,
         clkOut(1) => sysClk,
         rstOut(0) => refRst300MHz,
         rstOut(1) => sysRst);

   U_PGPv3 : entity work.Pgp3Gtx7Wrapper
      generic map(
         TPD_G         => TPD_G,
         NUM_LANES_G   => 1,
         NUM_VC_G      => 6,
         RATE_G        => PGP3_RATE_G,
         REFCLK_TYPE_G => PGP3_REFCLK_312_C,
         EN_PGP_MON_G  => false,
         EN_GTH_DRP_G  => false,
         EN_QPLL_DRP_G => false)
      port map (
         -- Stable Clock and Reset
         stableClk         => sysClk,
         stableRst         => sysRst,
         -- Gt Serial IO
         pgpGtTxP(0)       => pgpTxP(0),
         pgpGtTxN(0)       => pgpTxN(0),
         pgpGtRxP(0)       => pgpRxP(0),
         pgpGtRxN(0)       => pgpRxN(0),
         -- GT Clocking
         pgpRefClkP        => pgpClkP,
         pgpRefClkN        => pgpClkN,
         pgpRefClkDiv2Bufg => pgpRefClkDiv2,
         -- Clocking
         pgpClk(0)         => pgpClk(0),
         pgpClkRst(0)      => pgpRst(0),
         -- Non VC Rx Signals
         pgpRxIn(0)        => pgpRxIn(0),
         pgpRxOut(0)       => pgpRxOut(0),
         -- Non VC Tx Signals
         pgpTxIn(0)        => pgpTxIn(0),
         pgpTxOut(0)       => pgpTxOut(0),
         -- Frame Transmit Interface
         pgpTxMasters      => pgpTxMasters,
         pgpTxSlaves       => pgpTxSlaves,
         -- Frame Receive Interface
         pgpRxMasters      => pgpRxMasters,
         pgpRxCtrl         => pgpRxCtrl,
         -- AXI-Lite Register Interface (axilClk domain)
         axilClk           => sysClk,
         axilRst           => sysRst,
         axilReadMaster    => AXI_LITE_READ_MASTER_INIT_C,
         axilReadSlave     => open,
         axilWriteMaster   => AXI_LITE_WRITE_MASTER_INIT_C,
         axilWriteSlave    => open);

   U_Gtxe2ChannelDummy : entity work.Gtxe2ChannelDummy
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 3)
      port map (
         refClk => sysClk,
         gtRxP  => pgpRxP(3 downto 1),
         gtRxN  => pgpRxN(3 downto 1),
         gtTxP  => pgpTxP(3 downto 1),
         gtTxN  => pgpTxN(3 downto 1));

   U_Lane0_Vc0 : entity work.SrpV3AxiLite
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => false,
         GEN_SYNC_FIFO_G     => false,
         AXI_STREAM_CONFIG_G => PGP3_AXIS_CONFIG_C)
      port map (
         -- Streaming Slave (Rx) Interface (sAxisClk domain) 
         sAxisClk         => pgpClk(0),
         sAxisRst         => pgpRst(0),
         sAxisMaster      => pgpRxMasters(0),
         sAxisCtrl        => pgpRxCtrl(0),
         -- Streaming Master (Tx) Data Interface (mAxisClk domain)
         mAxisClk         => pgpClk(0),
         mAxisRst         => pgpRst(0),
         mAxisMaster      => pgpTxMasters(0),
         mAxisSlave       => pgpTxSlaves(0),
         -- Master AXI-Lite Interface (axilClk domain)
         axilClk          => sysClk,
         axilRst          => sysRst,
         mAxilReadMaster  => axilReadMaster,
         mAxilReadSlave   => axilReadSlave,
         mAxilWriteMaster => axilWriteMaster,
         mAxilWriteSlave  => axilWriteSlave);

   U_Lane0_Vc1 : entity work.AtlasRd53Pgp3AxisFifo
      generic map (
         TPD_G => TPD_G)
      port map (
         -- System Interface (axilClk domain)
         sysClk      => sysClk,
         sysRst      => sysRst,
         sAxisMaster => sTluMaster,
         sAxisSlave  => sTluSlave,
         mAxisMaster => mTluMaster,
         mAxisSlave  => mTluSlave,
         -- PGP Interface (pgpClk domain)
         pgpClk      => pgpClk(0),
         pgpRst      => pgpRst(0),
         pgpRxMaster => pgpRxMasters(1),
         pgpRxCtrl   => pgpRxCtrl(1),
         pgpTxMaster => pgpTxMasters(1),
         pgpTxSlave  => pgpTxSlaves(1));

   PGP_LANE : for i in 3 downto 0 generate

      rxLinkUp(i) <= pgpRxOut(i).linkReady;
      txLinkUp(i) <= pgpTxOut(i).linkReady;

      U_Lane0_Vc5_Vc2 : entity work.AtlasRd53Pgp3AxisFifo
         generic map (
            TPD_G => TPD_G,
            RX_G  => false)
         port map (
            -- System Interface (axilClk domain)
            sysClk      => sysClk,
            sysRst      => sysRst,
            sAxisMaster => sDataMasters(i),
            sAxisSlave  => sDataSlaves(i),
            -- PGP Interface (pgpClk domain)
            pgpClk      => pgpClk(0),
            pgpRst      => pgpRst(0),
            pgpTxMaster => pgpTxMasters(2+i),
            pgpTxSlave  => pgpTxSlaves(2+i));

   end generate PGP_LANE;

end mapping;
