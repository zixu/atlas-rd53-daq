-------------------------------------------------------------------------------
-- File       : AtlasRd53RxPhy.vhd
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

entity AtlasRd53RxPhy is
   generic (
      TPD_G        : time    := 1 ns;
      LINK_INDEX_G : natural := 0);
   port (
      -- Misc. Interfaces
      selEmuIn      : in  sl;
      enAuxClk      : in  sl;
      userRst       : in  sl;
      iDelayCtrlRdy : in  sl;
      dPortCmd      : in  sl;
      -- RD53 ASIC Serial Ports
      dPortDataP    : in  slv(3 downto 0);
      dPortDataN    : in  slv(3 downto 0);
      dPortCmdP     : out sl;
      dPortCmdN     : out sl;
      dPortAuxP     : out sl;
      dPortAuxN     : out sl;
      dPortRst      : out sl;
      -- RX PHY Interface
      validOut      : out sl;
      chBondOut     : out sl;
      dataOut       : out Slv64Array(3 downto 0);
      syncOut       : out Slv2Array(3 downto 0);
      -- Timing Clocks Interface
      clk640MHz     : in  sl;
      clk160MHz     : in  sl;
      clk80MHz      : in  sl;
      clk40MHz      : in  sl;
      -- Timing Resets Interface
      rst640MHz     : in  sl;
      rst160MHz     : in  sl;
      rst80MHz      : in  sl;
      rst40MHz      : in  sl);
end AtlasRd53RxPhy;

architecture mapping of AtlasRd53RxPhy is

   component aurora_rx_top_xapp
      port (
         rst           : in  sl;
         clk40         : in  sl;
         clk160        : in  sl;
         clk640        : in  sl;
         data_in_p     : in  sl;
         data_in_n     : in  sl;
         idelay_rdy    : in  sl;
         blocksync_out : out sl;
         gearbox_rdy   : out sl;
         data_valid    : out sl;
         sync_out      : out slv(1 downto 0);
         data_out      : out slv(63 downto 0));
   end component;

   component channel_bond
      port (
         rst              : in  sl;
         clk40            : in  sl;
         \data_in[0]\     : in  slv(63 downto 0);
         \data_in[1]\     : in  slv(63 downto 0);
         \data_in[2]\     : in  slv(63 downto 0);
         \data_in[3]\     : in  slv(63 downto 0);
         \sync_in[0]\     : in  slv(1 downto 0);
         \sync_in[1]\     : in  slv(1 downto 0);
         \sync_in[2]\     : in  slv(1 downto 0);
         \sync_in[3]\     : in  slv(1 downto 0);
         blocksync_out    : in  slv(3 downto 0);
         gearbox_rdy_rx   : in  slv(3 downto 0);
         data_valid       : in  slv(3 downto 0);
         \data_out_cb[0]\ : out slv(63 downto 0);
         \data_out_cb[1]\ : out slv(63 downto 0);
         \data_out_cb[2]\ : out slv(63 downto 0);
         \data_out_cb[3]\ : out slv(63 downto 0);
         \sync_out_cb[0]\ : out slv(1 downto 0);
         \sync_out_cb[1]\ : out slv(1 downto 0);
         \sync_out_cb[2]\ : out slv(1 downto 0);
         \sync_out_cb[3]\ : out slv(1 downto 0);
         data_valid_cb    : out sl;
         channel_bonded   : out sl);
   end component;

   signal dPortCmdReg : sl;

   signal dataUnaligned  : Slv64Array(3 downto 0);
   signal syncUnaligned  : Slv2Array(3 downto 0);
   signal blockSync      : slv(3 downto 0);
   signal gearboxRdyRx   : slv(3 downto 0);
   signal validUnaligned : slv(3 downto 0);

   signal data   : Slv64Array(3 downto 0);
   signal sync   : Slv2Array(3 downto 0);
   signal valid  : sl;
   signal chBond : sl;

begin

   dPortRst <= rst40MHz or userRst;  -- Inverted in HW on FPGA board before dport connector

   -----------------------------------------------
   -- Provide 40 MHz reference clock to remote EMU
   -----------------------------------------------
   U_dPortAux : entity work.ClkOutBufDiff
      generic map (
         TPD_G          => TPD_G,
         RST_POLARITY_G => '0',
         XIL_DEVICE_G   => "7SERIES")
      port map (
         clkIn   => clk40MHz,
         rstIn   => enAuxClk,
         clkOutP => dPortAuxP,
         clkOutN => dPortAuxN);

   ------------------------
   -- Output the serial CMD
   ------------------------
   U_ODDR : ODDR
      generic map(
         DDR_CLK_EDGE => "OPPOSITE_EDGE",  -- "OPPOSITE_EDGE" or "SAME_EDGE" 
         INIT         => '0',  -- Initial value for Q port ('1' or '0')
         SRTYPE       => "SYNC")        -- Reset Type ("ASYNC" or "SYNC")
      port map (
         D1 => dPortCmd,                -- 1-bit data input (positive edge)
         D2 => dPortCmd,                -- 1-bit data input (negative edge)
         Q  => dPortCmdReg,             -- 1-bit DDR output
         C  => clk160MHz,               -- 1-bit clock input
         CE => '1',                     -- 1-bit clock enable input
         R  => rst160MHz,               -- 1-bit reset
         S  => '0');                    -- 1-bit set

   U_dPortCmd : OBUFDS
      port map (
         I  => dPortCmdReg,
         O  => dPortCmdP,
         OB => dPortCmdN);

   ---------------
   -- RX PHY Layer
   ---------------
   GEN_LANE : for i in 3 downto 0 generate
      U_rx_lane : aurora_rx_top_xapp
         port map (
            -- Clock and Reset
            rst           => rst40MHz,
            clk40         => clk40MHz,
            clk160        => clk160MHz,
            clk640        => clk640MHz,
            -- RD53 ASIC Serial Ports
            data_in_p     => dPortDataP(i),
            data_in_n     => dPortDataN(i),
            -- IDELAYCTRL status
            idelay_rdy    => iDelayCtrlRdy,
            -- Unaligned Outbound Interface
            blocksync_out => blockSync(i),
            gearbox_rdy   => gearboxRdyRx(i),
            data_valid    => validUnaligned(i),
            sync_out      => syncUnaligned(i),
            data_out      => dataUnaligned(i));
   end generate GEN_LANE;

   U_chBond : channel_bond
      port map (
         -- Clock and Reset
         rst              => rst40MHz,
         clk40            => clk40MHz,
         -- Unaligned Inbound Interface
         \data_in[0]\     => dataUnaligned(0),
         \data_in[1]\     => dataUnaligned(1),
         \data_in[2]\     => dataUnaligned(2),
         \data_in[3]\     => dataUnaligned(3),
         \sync_in[0]\     => syncUnaligned(0),
         \sync_in[1]\     => syncUnaligned(1),
         \sync_in[2]\     => syncUnaligned(2),
         \sync_in[3]\     => syncUnaligned(3),
         blocksync_out    => blockSync,
         gearbox_rdy_rx   => gearboxRdyRx,
         data_valid       => validUnaligned,
         -- Aligned Outbound Interface
         \data_out_cb[0]\ => data(0),
         \data_out_cb[1]\ => data(1),
         \data_out_cb[2]\ => data(2),
         \data_out_cb[3]\ => data(3),
         \sync_out_cb[0]\ => sync(0),
         \sync_out_cb[1]\ => sync(1),
         \sync_out_cb[2]\ => sync(2),
         \sync_out_cb[3]\ => sync(3),
         data_valid_cb    => valid,
         channel_bonded   => chBond);

   ----------------------------------------
   -- Mux for selecting RX PHY or emulation
   ----------------------------------------
   U_MuxEmu : entity work.AtlasRd53MuxEmu
      generic map (
         TPD_G        => TPD_G,
         LINK_INDEX_G => LINK_INDEX_G)
      port map (
         selEmuIn   => selEmuIn,
         dPortCmdIn => dPortCmd,
         -- RX Input
         validIn    => valid,
         chBondIn   => chBond,
         dataIn     => data,
         syncIn     => sync,
         -- RX Output
         validOut   => validOut,
         chBondOut  => chBondOut,
         dataOut    => dataOut,
         syncOut    => syncOut,
         -- Timing Clocks Interface
         clk160MHz  => clk160MHz,
         clk80MHz   => clk80MHz,
         clk40MHz   => clk40MHz,
         -- Timing Resets Interface
         rst160MHz  => rst160MHz,
         rst80MHz   => rst80MHz,
         rst40MHz   => rst40MHz);

end mapping;
