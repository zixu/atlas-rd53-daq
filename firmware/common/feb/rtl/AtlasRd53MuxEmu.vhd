-------------------------------------------------------------------------------
-- File       : AtlasRd53MuxEmu.vhd
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

entity AtlasRd53MuxEmu is
   generic (
      TPD_G        : time    := 1 ns;
      LINK_INDEX_G : natural := 0);
   port (
      selEmuIn   : in  sl;
      dPortCmdIn : in  sl;
      validIn    : in  sl;
      chBondIn   : in  sl;
      dataIn     : in  Slv64Array(3 downto 0);
      syncIn     : in  Slv2Array(3 downto 0);
      validOut   : out sl;
      chBondOut  : out sl;
      dataOut    : out Slv64Array(3 downto 0);
      syncOut    : out Slv2Array(3 downto 0);
      -- Timing Clocks Interface
      clk160MHz  : in  sl;
      clk80MHz   : in  sl;
      clk40MHz   : in  sl;
      -- Timing Resets Interface
      rst160MHz  : in  sl;
      rst80MHz   : in  sl;
      rst40MHz   : in  sl);
end AtlasRd53MuxEmu;

architecture mapping of AtlasRd53MuxEmu is

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

   signal cmdValid : sl;
   signal cmdData  : slv(15 downto 0);

   signal frameData    : Slv64Array(3 downto 0);
   signal serviceFrame : slv(3 downto 0);
   signal sync         : Slv2Array(3 downto 0);

begin

   -------------------------------
   -- Decode the CMD serial stream
   -------------------------------
   U_ttc_top : ttc_top
      port map (
         clk160 => clk160MHz,
         rst    => rst160MHz,
         datain => dPortCmdIn,
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
         data_next        => '1',  -- Not sure if this is correct???
         \frame_out[0]\   => frameData(0),
         \frame_out[1]\   => frameData(1),
         \frame_out[2]\   => frameData(2),
         \frame_out[3]\   => frameData(3),
         service_frame(0) => serviceFrame(0),
         service_frame(1) => serviceFrame(1),
         service_frame(2) => serviceFrame(2),
         service_frame(3) => serviceFrame(3),
         trig_out         => open,
         fifo_full        => open,
         TT_full          => open,
         TT_empty         => open);

   GEN_VEC : for i in 3 downto 0 generate
      sync(i) <= "10" when (serviceFrame(i) = '1') else "01";
   end generate GEN_VEC;

   process(clk40MHz)
   begin
      if rising_edge(clk40MHz) then
         -- Pass through mode
         if (selEmuIn = '0') then
            validOut  <= validIn  after TPD_G;
            chBondOut <= chBondIn after TPD_G;
            dataOut   <= dataIn   after TPD_G;
            syncOut   <= syncIn   after TPD_G;
         -- Local Emulation mode
         else
            validOut  <= '1'       after TPD_G;
            chBondOut <= '1'       after TPD_G;
            dataOut   <= frameData after TPD_G;
            syncOut   <= sync      after TPD_G;
         end if;
      end if;
   end process;

end mapping;
