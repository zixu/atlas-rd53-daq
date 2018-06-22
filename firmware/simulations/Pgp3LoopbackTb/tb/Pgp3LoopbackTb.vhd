-------------------------------------------------------------------------------
-- File       : Pgp3LoopbackTb.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-06-13
-- Last update: 2018-06-13
-------------------------------------------------------------------------------
-- Description: Simulation Testbed for testing the Pgp3LoopbackTb module
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
use work.RceG3Pkg.all;
use work.Pgp3Pkg.all;

entity Pgp3LoopbackTb is end Pgp3LoopbackTb;

architecture testbed of Pgp3LoopbackTb is

   constant CLK_PERIOD_C  : time             := 10 ns;
   constant TPD_G         : time             := CLK_PERIOD_C/4;
   constant PKT_SIZE_C    : positive         := 3;
   constant TKEEP_TLAST_C : slv(15 downto 0) := genTKeep(4);

   type RegType is record
      pkt         : slv(31 downto 0);
      cnt         : slv(31 downto 0);
      dmaObMaster : AxiStreamMasterType;
   end record RegType;
   constant REG_INIT_C : RegType := (
      pkt         => (others => '0'),
      cnt         => (others => '0'),
      dmaObMaster => AXI_STREAM_MASTER_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal clk : sl := '0';
   signal rst : sl := '1';

   signal dmaObMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal dmaObSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;
   signal dmaIbMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal dmaIbSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;

   signal pgpTxOut : Pgp3TxOutType;
   signal pgpRxOut : Pgp3RxOutType;

begin

   U_ClkRst : entity work.ClkRst
      generic map (
         CLK_PERIOD_G      => CLK_PERIOD_C,
         RST_START_DELAY_G => 0 ns,  -- Wait this long into simulation before asserting reset
         RST_HOLD_TIME_G   => 1000 ns)  -- Hold reset for this long)
      port map (
         clkP => clk,
         rst  => rst);

   U_PgpProtocolOnly : entity work.PgpProtocolOnly
      generic map (
         TPD_G             => TPD_G,
         DMA_AXIS_CONFIG_G => RCEG3_AXIS_DMA_CONFIG_C)
      port map (
         dmaClk      => clk,
         dmaRst      => rst,
         pgpTxOut    => pgpTxOut,
         pgpRxOut    => pgpRxOut,
         dmaObMaster => dmaObMaster,
         dmaObSlave  => dmaObSlave,
         dmaIbMaster => dmaIbMaster,
         dmaIbSlave  => dmaIbSlave);

   U_PrbsFlowCtrl : entity work.AxiStreamPrbsFlowCtrl
      generic map (
         TPD_G       => TPD_G,
         SEED_G      => x"AAAA_5555",
         PRBS_TAPS_G => (0 => 31, 1 => 6, 2 => 2, 3 => 1))
      port map (
         clk         => clk,
         rst         => rst,
         threshold   => x"8000_0000",
         -- Slave Port
         sAxisMaster => dmaIbMaster,
         sAxisSlave  => dmaIbSlave,
         -- Master Port
         mAxisMaster => open,
         mAxisSlave  => AXI_STREAM_SLAVE_FORCE_C);

   comb : process (dmaObSlave, pgpRxOut, pgpTxOut, r, rst) is
      variable v : RegType;
   begin
      -- Latch the current value
      v := r;

      if (dmaObSlave.tReady = '1') then
         v.dmaObMaster.tValid   := '0';
         v.dmaObMaster.tLast    := '0';
         v.dmaObMaster.tUser(1) := '0';
         v.dmaObMaster.tKeep    := x"00FF";
      end if;

      -- Check if ready to move data
      if (v.dmaObMaster.tValid = '0') and (pgpTxOut.linkReady = '1') and (pgpRxOut.linkReady = '1') then
         v.cnt                            := r.cnt + 1;
         v.dmaObMaster.tValid             := '1';
         v.dmaObMaster.tData(63 downto 0) := r.pkt & r.cnt;
         if r.cnt = 0 then
            v.dmaObMaster.tUser(1) := '1';
         end if;
         if r.cnt = PKT_SIZE_C-1 then
            v.cnt               := (others => '0');
            v.pkt               := r.pkt + 1;
            v.dmaObMaster.tLast := '1';
            v.dmaObMaster.tKeep := TKEEP_TLAST_C;
         end if;
      end if;

      -- Reset
      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      dmaObMaster <= r.dmaObMaster;

   end process comb;

   seq : process (clk) is
   begin
      if rising_edge(clk) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end testbed;
