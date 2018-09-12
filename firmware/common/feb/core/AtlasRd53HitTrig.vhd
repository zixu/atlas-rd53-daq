-------------------------------------------------------------------------------
-- File       : AtlasRd53HitTrig.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-18
-- Last update: 2018-08-21
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
      -- Timing/Trigger Interface
      clk640MHz       : in  sl;
      clk160MHz       : in  sl;
      clk80MHz        : in  sl;
      clk40MHz        : in  sl;
      rst640MHz       : in  sl;
      rst160MHz       : in  sl;
      rst80MHz        : in  sl;
      rst40MHz        : in  sl;
      ttc             : out AtlasRd53TimingTrigType;  -- clk160MHz domain
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

   constant LUT0_INDEX_C : natural := 0;
   constant LUT1_INDEX_C : natural := 1;
   constant FSM_INDEX_C  : natural := 2;

   constant XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := (
      LUT0_INDEX_C    => (
         baseAddr     => AXI_BASE_ADDR_G+ x"0000_0000",
         addrBits     => 16,
         connectivity => x"FFFF"),
      LUT1_INDEX_C    => (
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
   signal ramData : Slv32Array(1 downto 0);

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

   -------------------------------------       
   -- AXI-Lite: BRAM bit Pattern storage
   -------------------------------------       
   GEN_VEC : for i in 1 downto 0 generate
      U_BRAM : entity work.AxiDualPortRam
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
            axiReadMaster  => axilReadMasters(i),
            axiReadSlave   => axilReadSlaves(i),
            axiWriteMaster => axilWriteMasters(i),
            axiWriteSlave  => axilWriteSlaves(i),
            -- Standard Port
            clk            => clk160MHz,
            addr           => ramAddr,
            dout           => ramData(i));
   end generate GEN_VEC;

   --------------------------------
   -- FSM for reading out the BRAMs
   --------------------------------
   U_FSM : entity work.AtlasRd53EmuTrigTiming
      generic map (
         TPD_G        => TPD_G,
         ADDR_WIDTH_G => ADDR_WIDTH_C)
      port map (
         -- Clock and reset
         clk            => clk160MHz,
         rst            => rst160MHz,
         -- AXI-Lite Interface
         axilReadMaster  => axilReadMasters(FSM_INDEX_C),
         axilReadSlave   => axilReadSlaves(FSM_INDEX_C),
         axilWriteMaster => axilWriteMasters(FSM_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(FSM_INDEX_C),
         -- RAM Interface
         ramAddr        => ramAddr,
         ramData        => ramData,
         -- Timing/Trigger Interface
         ttc            => ttc);

   ------------------------------
   -- Placeholder for future code
   ------------------------------
   trigIn    <= not(trigInL);
   hitIn     <= not(hitInL);
   hitOut    <= '0';
   tluTrgClk <= '0';
   tluBsy    <= '0';

   GEN_FEB : for i in 3 downto 0 generate
      GEN_CH : for j in 3 downto 0 generate
         U_dPortHit : IBUFDS
            port map (
               I  => dPortHitP(i)(j),
               IB => dPortHitN(i)(j),
               O  => dPortHit(i)(j));
      end generate GEN_CH;
   end generate GEN_FEB;

   U_tluInt : IBUFDS
      port map (
         I  => tluIntP,
         IB => tluIntN,
         O  => tluInt);                 -- Place holder for future code

   U_tluRst : IBUFDS
      port map (
         I  => tluRstP,
         IB => tluRstN,
         O  => tluRst);                 -- Place holder for future code

   U_tluTrgClk : OBUFDS
      port map (
         I  => tluTrgClk,               -- Place holder for future code
         O  => tluTrgClkP,
         OB => tluTrgClkN);

   U_tluBsy : OBUFDS
      port map (
         I  => tluBsy,                  -- Place holder for future code
         O  => tluBsyP,
         OB => tluBsyN);

end mapping;
