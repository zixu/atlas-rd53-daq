-------------------------------------------------------------------------------
-- File       : AtlasRd53RxPhyCore.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-18
-- Last update: 2018-05-25
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
      LINK_INDEX_G    : natural          := 0;
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
      -- Streaming RD43 Data Interface (axilClk domain)
      mDataMaster     : out AxiStreamMasterType;
      mDataSlave      : in  AxiStreamSlaveType;
      -- Streaming RD43 CMD Interface (axilClk domain)
      sCmdMaster      : in  AxiStreamMasterType;
      sCmdSlave       : out AxiStreamSlaveType;
      mCmdMaster      : out AxiStreamMasterType;
      mCmdSlave       : in  AxiStreamSlaveType;
      -- Timing Clocks Interface
      clk640MHz       : in  sl;
      clk160MHz       : in  sl;
      clk80MHz        : in  sl;
      clk40MHz        : in  sl;
      -- Timing Resets Interface
      rst640MHz       : in  sl;
      rst160MHz       : in  sl;
      rst80MHz        : in  sl;
      rst40MHz        : in  sl;
      -- RD53 ASIC Serial Ports
      dPortDataP      : in  slv(3 downto 0);
      dPortDataN      : in  slv(3 downto 0);
      dPortCmdP       : out sl;
      dPortCmdN       : out sl;
      dPortAuxP       : out sl;
      dPortAuxN       : out sl;
      dPortRst        : out sl);
end AtlasRd53RxPhyCore;

architecture mapping of AtlasRd53RxPhyCore is

   signal rx : AtlasRD53DataArray(1 downto 0);

   signal autoReadReg : Slv32Array(3 downto 0);
   signal cmdDrop     : sl;
   signal dataDrop    : slv(3 downto 0);
   signal timedOut    : sl;

   signal dPortCmd : sl;

   signal dataMaster : AxiStreamMasterType;
   signal dataSlave  : AxiStreamSlaveType;

begin

   -------------------------------
   -- Place holder for future code
   -------------------------------
   sCmdSlave <= AXI_STREAM_SLAVE_FORCE_C;
   dPortCmd  <= '0';

   ------------------------
   -- RX PHY Monitor Module
   ------------------------
   U_Monitor : entity work.AtlasRd53RxPhyMon
      generic map (
         TPD_G => TPD_G)
      port map (
         -- Monitoring Interface
         autoReadReg     => autoReadReg,
         cmdDrop         => cmdDrop,
         dataDrop        => dataDrop,
         timedOut        => timedOut,
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave);

   --------------------------------
   -- RX PHY Layer + Local Emulator
   --------------------------------
   U_RxPhy : entity work.AtlasRd53RxPhy
      generic map (
         TPD_G        => TPD_G,
         LINK_INDEX_G => LINK_INDEX_G)
      port map (
         -- Misc. Interfaces
         enLocalEmu    => enLocalEmu,
         enAuxClk      => enAuxClk,
         asicRst       => asicRst,
         iDelayCtrlRdy => iDelayCtrlRdy,
         dPortCmd      => dPortCmd,
         -- RD53 ASIC Serial Ports
         dPortDataP    => dPortDataP,
         dPortDataN    => dPortDataN,
         dPortCmdP     => dPortCmdP,
         dPortCmdN     => dPortCmdN,
         dPortAuxP     => dPortAuxP,
         dPortAuxN     => dPortAuxN,
         dPortRst      => dPortRst,
         -- Outbound Reg/Data Interface (clk80MHz domain)
         rxOut         => rx(0),        -- Reg/Data
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

   -------------------------------
   -- Demux the data/register path
   -------------------------------
   U_DeMuxRegData : entity work.AtlasRd53DeMuxRegData
      generic map (
         TPD_G => TPD_G)
      port map (
         -- RX Interface (clk80MHz domain)
         clk80MHz    => clk80MHz,
         rst80MHz    => rst80MHz,
         rxIn        => rx(0),          -- Reg/Data
         rxOut       => rx(1),          -- Data only
         -- Outbound Reg only Interface (axilClk domain)
         axilClk     => axilClk,
         axilRst     => axilRst,
         autoReadReg => autoReadReg,
         cmdDrop     => cmdDrop,
         mCmdMaster  => mCmdMaster,
         mCmdSlave   => mCmdSlave);

   ---------------------------------------
   -- Convert RX Data Path into AXI stream
   ---------------------------------------
   U_RxData : entity work.AtlasRd53RxData
      generic map (
         TPD_G => TPD_G)
      port map (
         -- RX Interface (clk80MHz domain)
         clk80MHz    => clk80MHz,
         rst80MHz    => rst80MHz,
         rx          => rx(1),          -- Data only  
         -- Outbound Reg only Interface (axilClk domain)
         axilClk     => axilClk,
         axilRst     => axilRst,
         dataDrop    => dataDrop,
         mDataMaster => dataMaster,
         mDataSlave  => dataSlave);

   ---------------------------------------------------------
   -- Batch Multiple 32-bit data words into large AXIS frame
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

end mapping;
