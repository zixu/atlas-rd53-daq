-------------------------------------------------------------------------------
-- File       : XpmAxisFifoTb.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-06-13
-- Last update: 2018-07-11
-------------------------------------------------------------------------------
-- Description: Simulation Testbed for testing the XpmAxisFifoTb module
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.Pgp3Pkg.all;

entity XpmAxisFifoTb is end XpmAxisFifoTb;

architecture testbed of XpmAxisFifoTb is

   signal pgpRefClk : sl := '0';
   signal clk       : sl := '0';
   signal rst       : sl := '1';

   signal pgpMasters : AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal pgpSlaves  : AxiStreamSlaveArray(3 downto 0)  := (others => AXI_STREAM_SLAVE_INIT_C);

begin

   U_ClkRst : entity work.ClkRst
      generic map (
         CLK_PERIOD_G      => 6.4 ns,
         RST_START_DELAY_G => 0 ns,  -- Wait this long into simulation before asserting reset
         RST_HOLD_TIME_G   => 1000 ns)  -- Hold reset for this long)
      port map (
         clkP => pgpRefClk);

   U_RoguePgp3Sim : entity work.RoguePgp3Sim
      generic map (
         TPD_G         => 1 ns,
         SYNTH_MODE_G  => "xpm",
         MEMORY_TYPE_G => "block",
         USER_ID_G     => 1,
         NUM_VC_G      => 4)
      port map (
         -- GT Ports
         pgpRefClk    => pgpRefClk,
         pgpGtRxP     => '0',
         pgpGtRxN     => '1',
         pgpGtTxP     => open,
         pgpGtTxN     => open,
         -- PGP Clock and Reset
         pgpClk       => clk,
         pgpClkRst    => rst,
         -- Non VC Rx Signals
         pgpRxIn      => PGP3_RX_IN_INIT_C,
         pgpRxOut     => open,
         -- Non VC Tx Signals
         pgpTxIn      => PGP3_TX_IN_INIT_C,
         pgpTxOut     => open,
         -- Frame Transmit Interface
         pgpTxMasters => pgpMasters,
         pgpTxSlaves  => pgpSlaves,
         -- Frame Receive Interface
         pgpRxMasters => pgpMasters,
         pgpRxSlaves  => pgpSlaves);

end testbed;
