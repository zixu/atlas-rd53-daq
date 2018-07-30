-------------------------------------------------------------------------------
-- File       : AtlasRd53RxPhyCore.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-18
-- Last update: 2018-07-30
-------------------------------------------------------------------------------
-- Description: RX PHY Core module
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
use work.AtlasRd53Pkg.all;

entity AtlasRd53RxPhyCore is
   generic (
      TPD_G           : time             := 1 ns;
      SYNTH_MODE_G    : string           := "inferred";
      AXI_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      -- Misc. Interfaces
      enLocalEmu      : in  sl;
      enAuxClk        : in  sl;
      asicRst         : in  sl;
      batchSize       : in  slv(15 downto 0);
      timerConfig     : in  slv(15 downto 0);
      iDelayCtrlRdy   : in  sl;
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Streaming RD53 Config Interface (clk160MHz domain)
      sConfigMaster   : in  AxiStreamMasterType;
      sConfigSlave    : out AxiStreamSlaveType;
      mConfigMaster   : out AxiStreamMasterType;
      mConfigSlave    : in  AxiStreamSlaveType;
      -- Streaming RD43 Data Interface (axilClk domain)
      mDataMaster     : out AxiStreamMasterType;
      mDataSlave      : in  AxiStreamSlaveType;
      -- Timing/Trigger Interface
      clk640MHz       : in  sl;
      clk160MHz       : in  sl;
      clk80MHz        : in  sl;
      clk40MHz        : in  sl;
      rst640MHz       : in  sl;
      rst160MHz       : in  sl;
      rst80MHz        : in  sl;
      rst40MHz        : in  sl;
      ttc             : in  AtlasRd53TimingTrigType;  -- clk160MHz domain
      refClk300MHz    : in  sl;
      -- RD53 ASIC Serial Ports
      dPortDataP      : in  slv(3 downto 0);
      dPortDataN      : in  slv(3 downto 0);
      dPortCmdP       : out sl;
      dPortCmdN       : out sl;
      dPortAuxP       : out sl;
      dPortAuxN       : out sl);
end AtlasRd53RxPhyCore;

architecture mapping of AtlasRd53RxPhyCore is

   constant NUM_AXIL_MASTERS_C : natural := 2;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXI_BASE_ADDR_G, 21, 20);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);

   signal dataMaster  : AxiStreamMasterType;
   signal dataSlave   : AxiStreamSlaveType;
   signal autoReadReg : Slv32Array(3 downto 0);

   signal dataDrop : sl;
   signal timedOut : sl;

   signal enable : slv(3 downto 0);
   signal linkUp : slv(3 downto 0);
   signal chBond : sl;

   signal invData : slv(3 downto 0);
   signal invCmd  : sl;

begin

   ------------------------------------------------
   -- Provide 160 MHz reference clock to remote EMU
   ------------------------------------------------
   U_dPortAux : entity work.ClkOutBufDiff
      generic map (
         TPD_G          => TPD_G,
         RST_POLARITY_G => '0',         -- Active LOW reset
         XIL_DEVICE_G   => "7SERIES")
      port map (
         clkIn   => clk160MHz,
         rstIn   => enAuxClk,
         clkOutP => dPortAuxP,
         clkOutN => dPortAuxN);

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

   --------------------------------
   -- RX PHY Layer + Local Emulator
   --------------------------------
   U_RxPhy : entity work.AtlasRd53RxPhy
      generic map (
         TPD_G        => TPD_G,
         SYNTH_MODE_G => SYNTH_MODE_G)
      port map (
         -- Misc. Interfaces
         enLocalEmu      => enLocalEmu,
         asicRstIn       => asicRst,
         iDelayCtrlRdy   => iDelayCtrlRdy,
         enable          => enable,
         invData         => invData,
         invCmd          => invCmd,
         linkUp          => linkUp,
         chBond          => chBond,
         -- RD53 ASIC Serial Ports
         dPortDataP      => dPortDataP,
         dPortDataN      => dPortDataN,
         dPortCmdP       => dPortCmdP,
         dPortCmdN       => dPortCmdN,
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
         -- AXI-Lite Interface  (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(0),
         axilReadSlave   => axilReadSlaves(0),
         axilWriteMaster => axilWriteMasters(0),
         axilWriteSlave  => axilWriteSlaves(0),
         -- Streaming RD53 Config Interface (clk160MHz domain)
         sConfigMaster   => sConfigMaster,
         sConfigSlave    => sConfigSlave,
         mConfigMaster   => mConfigMaster,
         mConfigSlave    => mConfigSlave,
         -- Outbound Data/Auto-Read Interface (axilClk domain)
         mDataMaster     => dataMaster,
         mDataSlave      => dataSlave,
         dataDrop        => dataDrop,
         autoReadReg     => autoReadReg);

   ---------------------------------------------------------
   -- Batch Multiple 64-bit data words into large AXIS frame
   ---------------------------------------------------------
   U_DataBatcher : entity work.AtlasRd53RxDataBatcher
      generic map (
         TPD_G => TPD_G)
      port map (
         -- Clock and Reset
         axilClk     => axilClk,
         axilRst     => axilRst,
         -- Configuration/Status Interface
         batchSize   => batchSize,
         timerConfig => timerConfig,
         timedOut    => timedOut,
         -- AXI Streaming Interface
         sDataMaster => dataMaster,
         sDataSlave  => dataSlave,
         mDataMaster => mDataMaster,
         mDataSlave  => mDataSlave);

   ------------------------
   -- RX PHY Monitor Module
   ------------------------
   U_Monitor : entity work.AtlasRd53RxPhyMon
      generic map (
         TPD_G => TPD_G)
      port map (
         -- Monitoring Interface
         autoReadReg     => autoReadReg,
         dataDrop        => dataDrop,
         timedOut        => timedOut,
         enable          => enable,
         invData         => invData,
         invCmd          => invCmd,
         linkUp          => linkUp,
         chBond          => chBond,
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(1),
         axilReadSlave   => axilReadSlaves(1),
         axilWriteMaster => axilWriteMasters(1),
         axilWriteSlave  => axilWriteSlaves(1));

end mapping;
