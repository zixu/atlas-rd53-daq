-------------------------------------------------------------------------------
-- File       : AtlasRd53HitTrig.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Hit/Trig Module
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

library unisim;
use unisim.vcomponents.all;

entity AtlasRd53HitTrig is
   generic (
      TPD_G           : time             := 1 ns;
      AXI_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Reference Timing Interface
      clk640MHz       : in  sl;
      clk160MHz       : in  sl;
      clk80MHz        : in  sl;
      clk40MHz        : in  sl;
      rst640MHz       : in  sl;
      rst160MHz       : in  sl;
      rst80MHz        : in  sl;
      rst40MHz        : in  sl;
      -- Streaming RD53 Trig Interface (clk160MHz domain)
      tluTrigMasters  : out AxiStreamMasterArray(3 downto 0);
      tluTrigSlaves   : in  AxiStreamSlaveArray(3 downto 0);
      -- Trigger and hits Ports
      dPortHitP       : in  Slv4Array(3 downto 0);
      dPortHitN       : in  Slv4Array(3 downto 0);
      trigInL         : in  sl;
      hitInL          : in  sl;
      hitOut          : out sl;
      -- TLU Ports
      tluTrgClkP      : out sl;
      tluTrgClkN      : out sl;
      tluBsyP         : out sl;
      tluBsyN         : out sl;
      tluIntP         : in  sl;
      tluIntN         : in  sl;
      tluRstP         : in  sl;
      tluRstN         : in  sl);
end AtlasRd53HitTrig;

architecture mapping of AtlasRd53HitTrig is

   constant ADDR_WIDTH_C : positive := 10;

   constant NUM_AXIL_MASTERS_C : natural := 3;

   constant TLU_INDEX_C : natural := 0;
   constant LUT_INDEX_C : natural := 1;
   constant FSM_INDEX_C : natural := 2;

   constant XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := (
      TLU_INDEX_C     => (
         baseAddr     => AXI_BASE_ADDR_G+ x"0000_0000",
         addrBits     => 16,
         connectivity => x"FFFF"),
      LUT_INDEX_C     => (
         baseAddr     => AXI_BASE_ADDR_G+ x"0001_0000",
         addrBits     => 16,
         connectivity => x"FFFF"),
      FSM_INDEX_C     => (
         baseAddr     => AXI_BASE_ADDR_G + x"0002_0000",
         addrBits     => 16,
         connectivity => x"FFFF"));

   signal regWriteMaster : AxiLiteWriteMasterType;
   signal regWriteSlave  : AxiLiteWriteSlaveType;
   signal regReadMaster  : AxiLiteReadMasterType;
   signal regReadSlave   : AxiLiteReadSlaveType;

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);

   signal ramAddr : slv(ADDR_WIDTH_C-1 downto 0);
   signal ramData : slv(31 downto 0);

   signal trigMaster : AxiStreamMasterType;
   signal trigSlave  : AxiStreamSlaveType;

   signal tluMaster : AxiStreamMasterType;
   signal tluSlave  : AxiStreamSlaveType;

   signal txMaster : AxiStreamMasterType;
   signal txSlave  : AxiStreamSlaveType;

   signal dPortHit  : Slv4Array(3 downto 0);
   signal trigIn    : sl;
   signal tluInt    : sl;
   signal tluRst    : sl;
   signal tluTrgClk : sl;
   signal tluBsy    : sl;
   signal hitIn     : sl;

begin


   ----------------------------------------
   -- Sync AXI-Lite to 160 MHz clock domain
   ----------------------------------------
   U_AxiLiteAsync : entity work.AxiLiteAsync
      generic map (
         TPD_G => TPD_G)
      port map (
         -- Slave Port
         sAxiClk         => axilClk,
         sAxiClkRst      => axilRst,
         sAxiReadMaster  => axilReadMaster,
         sAxiReadSlave   => axilReadSlave,
         sAxiWriteMaster => axilWriteMaster,
         sAxiWriteSlave  => axilWriteSlave,
         -- Master Port
         mAxiClk         => clk160MHz,
         mAxiClkRst      => rst160MHz,
         mAxiReadMaster  => regReadMaster,
         mAxiReadSlave   => regReadSlave,
         mAxiWriteMaster => regWriteMaster,
         mAxiWriteSlave  => regWriteSlave);

   --------------------------
   -- AXI-Lite: Crossbar Core
   --------------------------  
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => XBAR_CONFIG_C)
      port map (
         axiClk              => clk160MHz,
         axiClkRst           => rst160MHz,
         sAxiWriteMasters(0) => regWriteMaster,
         sAxiWriteSlaves(0)  => regWriteSlave,
         sAxiReadMasters(0)  => regReadMaster,
         sAxiReadSlaves(0)   => regReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   ---------------------
   -- AXI-Lite: TLU Core
   ---------------------
   U_TLU : entity work.AtlasRd53Tlu
      generic map(
         TPD_G           => TPD_G,
         AXI_BASE_ADDR_G => XBAR_CONFIG_C(TLU_INDEX_C).baseAddr)
      port map(
         -- AXI-Lite Interface (clk160MHz domain)
         axilReadMaster  => axilReadMasters(TLU_INDEX_C),
         axilReadSlave   => axilReadSlaves(TLU_INDEX_C),
         axilWriteMaster => axilWriteMasters(TLU_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(TLU_INDEX_C),
         -- Reference Timing Interface
         clk640MHz       => clk640MHz,
         clk160MHz       => clk160MHz,
         clk80MHz        => clk80MHz,
         clk40MHz        => clk40MHz,
         rst640MHz       => rst640MHz,
         rst160MHz       => rst160MHz,
         rst80MHz        => rst80MHz,
         rst40MHz        => rst40MHz,
         -- Streaming RD53 Trig Interface (clk160MHz domain)
         tluMaster       => tluMaster,
         tluSlave        => tluSlave,
         -- Trigger and hits Ports
         dPortHitP       => dPortHitP,
         dPortHitN       => dPortHitN,
         trigInL         => trigInL,
         hitInL          => hitInL,
         hitOut          => hitOut,
         -- TLU Ports
         tluTrgClkP      => tluTrgClkP,
         tluTrgClkN      => tluTrgClkN,
         tluBsyP         => tluBsyP,
         tluBsyN         => tluBsyN,
         tluIntP         => tluIntP,
         tluIntN         => tluIntN,
         tluRstP         => tluRstP,
         tluRstN         => tluRstN);

   ---------------------------------------------       
   -- AXI-Lite: BRAM trigger bit Pattern storage
   ---------------------------------------------       
   U_LUT : entity work.AxiDualPortRam
      generic map (
         TPD_G            => TPD_G,
         MEMORY_TYPE_G    => "block",
         REG_EN_G         => false,
         AXI_WR_EN_G      => true,
         SYS_WR_EN_G      => false,
         SYS_BYTE_WR_EN_G => false,
         COMMON_CLK_G     => true,
         ADDR_WIDTH_G     => ADDR_WIDTH_C,
         DATA_WIDTH_G     => 32)
      port map (
         -- Axi Port
         axiClk         => clk160MHz,
         axiRst         => rst160MHz,
         axiReadMaster  => axilReadMasters(LUT_INDEX_C),
         axiReadSlave   => axilReadSlaves(LUT_INDEX_C),
         axiWriteMaster => axilWriteMasters(LUT_INDEX_C),
         axiWriteSlave  => axilWriteSlaves(LUT_INDEX_C),
         -- Standard Port
         clk            => clk160MHz,
         addr           => ramAddr,
         dout           => ramData);

   --------------------------------
   -- FSM for reading out the BRAMs
   --------------------------------
   U_FSM : entity work.AtlasRd53EmuTrigTiming
      generic map (
         TPD_G        => TPD_G,
         ADDR_WIDTH_G => ADDR_WIDTH_C)
      port map (
         -- Clock and reset
         clk             => clk160MHz,
         rst             => rst160MHz,
         -- AXI-Lite Interface
         axilReadMaster  => axilReadMasters(FSM_INDEX_C),
         axilReadSlave   => axilReadSlaves(FSM_INDEX_C),
         axilWriteMaster => axilWriteMasters(FSM_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(FSM_INDEX_C),
         -- RAM Interface
         ramAddr         => ramAddr,
         ramData         => ramData,
         -- Streaming RD53 Trig Interface (clk160MHz domain)
         trigMaster      => trigMaster,
         trigSlave       => trigSlave);

   ---------------------------
   -- MUX the streams together
   ---------------------------
   U_Mux : entity work.AxiStreamMux
      generic map (
         TPD_G         => TPD_G,
         NUM_SLAVES_G  => 2,
         PIPE_STAGES_G => 1)
      port map (
         -- Clock and reset
         axisClk         => clk160MHz,
         axisRst         => rst160MHz,
         -- Slaves
         sAxisMasters(0) => tluMaster,
         sAxisMasters(1) => trigMaster,
         sAxisSlaves(0)  => tluSlave,
         sAxisSlaves(1)  => trigSlave,
         -- Master
         mAxisMaster     => txMaster,
         mAxisSlave      => txSlave);

   ---------------------------------------------------         
   -- Repeat the AXI stream to all RD53 CMD interfaces
   ---------------------------------------------------         
   U_Repeater : entity work.AxiStreamRepeater
      generic map(
         TPD_G                => TPD_G,
         NUM_MASTERS_G        => 4,
         INPUT_PIPE_STAGES_G  => 0,
         OUTPUT_PIPE_STAGES_G => 1)
      port map (
         -- Clock and reset
         axisClk      => clk160MHz,
         axisRst      => rst160MHz,
         -- Slave
         sAxisMaster  => txMaster,
         sAxisSlave   => txSlave,
         -- Masters
         mAxisMasters => tluTrigMasters,
         mAxisSlaves  => tluTrigSlaves);

end mapping;
