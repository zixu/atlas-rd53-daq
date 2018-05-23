-------------------------------------------------------------------------------
-- File       : AtlasRd53EmuDport.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-18
-- Last update: 2018-05-23
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
use work.Pgp3Pkg.all;

library unisim;
use unisim.vcomponents.all;

entity AtlasRd53EmuDport is
   generic (
      TPD_G           : time             := 1 ns;
      LINK_INDEX_G    : natural          := 0;
      AXI_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Status
      pllLocked       : out sl;
      trigOut         : out sl;
      fifoFull        : out sl;
      ttFull          : out sl;
      ttEmpty         : out sl;
      -- RD53 ASIC Emulation Ports
      dPortDataP      : out slv(3 downto 0);
      dPortDataN      : out slv(3 downto 0);
      dPortCmdP       : in  sl;
      dPortCmdN       : in  sl;
      dPortAuxP       : in  sl;
      dPortAuxN       : in  sl;
      dPortRst        : out sl);
end AtlasRd53EmuDport;

architecture mapping of AtlasRd53EmuDport is

   constant CHIP_ID_C : slv(3 downto 0) := toSlv(LINK_INDEX_G, 4);

   component ttc_top
      port (
         clk160 : in  std_logic;
         rst    : in  std_logic;
         datain : in  std_logic;
         valid  : out std_logic;
         data   : out std_logic_vector(15 downto 0));
   end component;

   component chip_output
      port (
         rst            : in  std_logic;
         clk160         : in  std_logic;
         clk80          : in  std_logic;
         clk40          : in  std_logic;
         word_valid     : in  std_logic;
         data_in        : in  std_logic_vector (15 downto 0);
         chip_id        : in  std_logic_vector (3 downto 0);
         data_next      : in  std_logic;
         \frame_out[0]\ : out std_logic_vector (63 downto 0);
         \frame_out[1]\ : out std_logic_vector (63 downto 0);
         \frame_out[2]\ : out std_logic_vector (63 downto 0);
         \frame_out[3]\ : out std_logic_vector (63 downto 0);
         service_frame  : out std_logic_vector (0 to 3);
         trig_out       : out std_logic;
         fifo_full      : out std_logic;
         TT_full        : out std_logic;
         TT_empty       : out std_logic);
   end component;

   component aurora_tx_four_lane
      port (
         clk40        : in  std_logic;
         clk160       : in  std_logic;
         clk640       : in  std_logic;
         rst          : in  std_logic;
         \data_in[0]\ : in  std_logic_vector (63 downto 0);
         \data_in[1]\ : in  std_logic_vector (63 downto 0);
         \data_in[2]\ : in  std_logic_vector (63 downto 0);
         \data_in[3]\ : in  std_logic_vector (63 downto 0);
         \sync[0]\    : in  std_logic_vector (1 downto 0);
         \sync[1]\    : in  std_logic_vector (1 downto 0);
         \sync[2]\    : in  std_logic_vector (1 downto 0);
         \sync[3]\    : in  std_logic_vector (1 downto 0);
         data_out_p   : out std_logic_vector (3 downto 0);
         data_out_n   : out std_logic_vector (3 downto 0);
         data_next    : out std_logic_vector (3 downto 0));
   end component;

   signal refClk : sl;

   signal clk640MHz : sl;
   signal clk160MHz : sl;
   signal clk80MHz  : sl;
   signal clk40MHz  : sl;

   signal rst640MHz : sl;
   signal rst160MHz : sl;
   signal rst80MHz  : sl;
   signal rst40MHz  : sl;

   signal dPortCmd : sl;
   signal dPortCmdReg : sl;
   
   signal cmdValid : sl;
   signal cmdData  : slv(15 downto 0);

   signal dataNextAll : sl;
   signal dataNext    : slv(3 downto 0);

   signal frameData    : Slv64Array(3 downto 0);
   signal serviceFrame : slv(3 downto 0);
   signal sync         : Slv2Array(3 downto 0);

begin

   dPortRst <= '0';                     -- Unused on the emulator side

   -- Place holder for future code
   axilReadSlave  <= AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
   axilWriteSlave <= AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;

   ---------------------------------------------------
   -- Generate the clocks (synchronous to other board)
   ---------------------------------------------------
   U_dPortAux : IBUFDS
      port map (
         I  => dPortAuxP,
         IB => dPortAuxN,
         O  => refClk);

   U_MMCM : entity work.ClockManager7
      generic map(
         TPD_G              => TPD_G,
         TYPE_G             => "MMCM",
         BANDWIDTH_G        => "HIGH",
         INPUT_BUFG_G       => true,
         FB_BUFG_G          => false,
         NUM_CLOCKS_G       => 4,
         CLKIN_PERIOD_G     => 25.0,    -- 40 MHz
         DIVCLK_DIVIDE_G    => 1,       -- 40 MHz = 40 MHz/1
         CLKFBOUT_MULT_F_G  => 32.0,    -- 1.28 GHz = 40 MHz x 32
         CLKOUT0_DIVIDE_F_G => 2.0,     -- 640 MHz = 1.28 GHz/2
         CLKOUT1_DIVIDE_G   => 8,       -- 160 MHz = 1.28 GHz/8
         CLKOUT2_DIVIDE_G   => 16,      -- 80 MHz = 1.28 GHz/16
         CLKOUT3_DIVIDE_G   => 32)      -- 40 MHz = 1.28 GHz/32
      port map(
         clkIn     => refClk,
         -- Clock Outputs
         clkOut(0) => clk640MHz,
         clkOut(1) => clk160MHz,
         clkOut(2) => clk80MHz,
         clkOut(3) => clk40MHz,
         -- Reset Outputs
         rstOut(0) => rst640MHz,
         rstOut(1) => rst160MHz,
         rstOut(2) => rst80MHz,
         rstOut(3) => rst40MHz,
         -- Status
         locked    => pllLocked);

   -------------------------------
   -- Decode the CMD serial stream
   -------------------------------
   U_dPortCmd : IBUFDS
      port map (
         I  => dPortCmdP,
         IB => dPortCmdN,
         O  => dPortCmd);
         
   U_IDDR : IDDR
      generic map (
         DDR_CLK_EDGE => "SAME_EDGE_PIPELINED",  -- "OPPOSITE_EDGE", "SAME_EDGE", or "SAME_EDGE_PIPELINED"
         INIT_Q1      => '0',           -- Initial value of Q1: '0' or '1'
         INIT_Q2      => '0',           -- Initial value of Q2: '0' or '1'
         SRTYPE       => "SYNC")        -- Set/Reset type: "SYNC" or "ASYNC" 
      port map (
         D  => dPortCmd,      -- 1-bit DDR data input
         C  => clk160MHz,     -- 1-bit clock input
         CE => '1',           -- 1-bit clock enable input
         R  => rst160MHz,     -- 1-bit reset
         S  => '0',           -- 1-bit set
         Q1 => open,          -- 1-bit output for positive edge of clock 
         Q2 => dPortCmdReg);  -- 1-bit output for negative edge of clock          

   U_ttc_top : ttc_top
      port map (
         clk160 => clk160MHz,
         rst    => rst160MHz,
         datain => dPortCmdReg,
         valid  => cmdValid,
         data   => cmdData);

   --------------------------
   -- Emulate the RD53 Output
   --------------------------
   U_chip_output : chip_output
      port map(
         rst              => rst40MHz,
         clk160           => clk160MHz,
         clk80            => clk80MHz,
         clk40            => clk40MHz,
         word_valid       => cmdValid,
         data_in          => cmdData,
         chip_id          => CHIP_ID_C,
         data_next        => dataNextAll,
         \frame_out[0]\   => frameData(0),
         \frame_out[1]\   => frameData(1),
         \frame_out[2]\   => frameData(2),
         \frame_out[3]\   => frameData(3),
         service_frame(0) => serviceFrame(0),
         service_frame(1) => serviceFrame(1),
         service_frame(2) => serviceFrame(2),
         service_frame(3) => serviceFrame(3),
         trig_out         => trigOut,
         fifo_full        => fifoFull,
         TT_full          => ttFull,
         TT_empty         => ttEmpty);

   dataNextAll <= uOr(dataNext);

   GEN_VEC : for i in 3 downto 0 generate
      sync(i) <= "10" when (serviceFrame(i) = '1') else "01";
   end generate GEN_VEC;

   -------------------------------
   -- Emulate the RD53 Serializer 
   -------------------------------
   U_aurora_tx_four_lane : aurora_tx_four_lane
      port map(
         clk40        => clk40MHz,
         clk160       => clk160MHz,
         clk640       => clk640MHz,
         rst          => rst40MHz,
         \data_in[0]\ => frameData(0),
         \data_in[1]\ => frameData(1),
         \data_in[2]\ => frameData(2),
         \data_in[3]\ => frameData(3),
         \sync[0]\    => sync(0),
         \sync[1]\    => sync(1),
         \sync[2]\    => sync(2),
         \sync[3]\    => sync(3),
         data_out_p   => dPortDataP,
         data_out_n   => dPortDataN,
         data_next    => dataNext);

end mapping;
