-------------------------------------------------------------------------------
-- File       : AtlasRd53RxAsyncFifo.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-05-25
-- Last update: 2018-05-25
-------------------------------------------------------------------------------
-- Description: ASYNC FIFO for RX data
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
use work.AtlasRd53Pkg.all;

entity AtlasRd53RxAsyncFifo is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Asynchronous Reset
      rst   : in  sl := '0';
      -- Write Ports (wr_clk domain)
      wrClk : in  sl;
      rxIn  : in  AtlasRD53DataType;
      -- Read Ports (rd_clk domain)
      rdClk : in  sl;
      rxOut : out AtlasRD53DataType);
end AtlasRd53RxAsyncFifo;

architecture mapping of AtlasRd53RxAsyncFifo is

begin

   U_Sync : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 265)
      port map (
         rst                  => rst,
         -- Write Ports (wr_clk domain)
         wr_clk               => wrClk,
         wr_en                => rxIn.valid,
         din(63 downto 0)     => rxIn.data(0),
         din(127 downto 64)   => rxIn.data(1),
         din(191 downto 128)  => rxIn.data(2),
         din(255 downto 192)  => rxIn.data(3),
         din(257 downto 256)  => rxIn.sync(0),
         din(259 downto 258)  => rxIn.sync(1),
         din(261 downto 260)  => rxIn.sync(2),
         din(263 downto 262)  => rxIn.sync(3),
         din(264)             => rxIn.chBond,
         -- Read Ports (rd_clk domain)
         rd_clk               => rdClk,
         valid                => rxOut.valid,
         dout(63 downto 0)    => rxOut.data(0),
         dout(127 downto 64)  => rxOut.data(1),
         dout(191 downto 128) => rxOut.data(2),
         dout(255 downto 192) => rxOut.data(3),
         dout(257 downto 256) => rxOut.sync(0),
         dout(259 downto 258) => rxOut.sync(1),
         dout(261 downto 260) => rxOut.sync(2),
         dout(263 downto 262) => rxOut.sync(3),
         dout(264)            => rxOut.chBond);

end mapping;
