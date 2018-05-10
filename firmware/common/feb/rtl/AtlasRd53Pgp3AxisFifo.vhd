-------------------------------------------------------------------------------
-- File       : AtlasRd53Pgp3AxisFifo.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-08
-- Last update: 2018-05-09
-------------------------------------------------------------------------------
-- Description: Top-Level module using four lanes of 10 Gbps PGPv3 communication
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

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.Pgp3Pkg.all;

entity AtlasRd53Pgp3AxisFifo is
   generic (
      TPD_G : time    := 1 ns;
      TX_G  : boolean := true;
      RX_G  : boolean := true);
   port (
      -- System Interface (axilClk domain)
      sysClk      : in  sl;
      sysRst      : in  sl;
      sAxisMaster : in  AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      sAxisSlave  : out AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;
      mAxisMaster : out AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      mAxisSlave  : in  AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;
      -- PGP Interface (pgpClk domain)
      pgpClk      : in  sl;
      pgpRst      : in  sl;
      pgpRxMaster : in  AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      pgpRxCtrl   : out AxiStreamCtrlType   := AXI_STREAM_CTRL_UNUSED_C;
      pgpTxMaster : out AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      pgpTxSlave  : in  AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C);
end AtlasRd53Pgp3AxisFifo;

architecture mapping of AtlasRd53Pgp3AxisFifo is

begin

   GEN_TX : if (TX_G) generate
      U_Fifo : entity work.AxiStreamFifoV2
         generic map (
            TPD_G               => TPD_G,
            SLAVE_READY_EN_G    => true,
            BRAM_EN_G           => false,
            GEN_SYNC_FIFO_G     => false,
            FIFO_ADDR_WIDTH_G   => 4,
            SLAVE_AXI_CONFIG_G  => PGP3_AXIS_CONFIG_C,
            MASTER_AXI_CONFIG_G => PGP3_AXIS_CONFIG_C)
         port map (
            -- Slave Port
            sAxisClk    => sysClk,
            sAxisRst    => sysRst,
            sAxisMaster => sAxisMaster,
            sAxisSlave  => sAxisSlave,
            -- Master Port
            mAxisClk    => pgpClk,
            mAxisRst    => pgpRst,
            mAxisMaster => pgpTxMaster,
            mAxisSlave  => pgpTxSlave);
   end generate;

   GEN_RX : if (RX_G) generate
      U_Fifo : entity work.AxiStreamFifoV2
         generic map (
            TPD_G               => TPD_G,
            SLAVE_READY_EN_G    => false,
            BRAM_EN_G           => true,
            GEN_SYNC_FIFO_G     => false,
            FIFO_ADDR_WIDTH_G   => 9,
            FIFO_FIXED_THRESH_G => true,
            FIFO_PAUSE_THRESH_G => 128,
            SLAVE_AXI_CONFIG_G  => PGP3_AXIS_CONFIG_C,
            MASTER_AXI_CONFIG_G => PGP3_AXIS_CONFIG_C)
         port map (
            -- Slave Port
            sAxisClk    => pgpClk,
            sAxisRst    => pgpRst,
            sAxisMaster => pgpRxMaster,
            sAxisCtrl   => pgpRxCtrl,
            -- Master Port
            mAxisClk    => sysClk,
            mAxisRst    => sysRst,
            mAxisMaster => mAxisMaster,
            mAxisSlave  => mAxisSlave);
   end generate;

end mapping;
