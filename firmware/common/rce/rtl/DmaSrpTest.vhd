-------------------------------------------------------------------------------
-- File       : DmaSrpTest.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: 
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
use work.RceG3Pkg.all;
use work.Pgp3Pkg.all;

entity DmaSrpTest is
   generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType);
   port (
      clk         : in  sl;
      rst         : in  sl;
      dmaObMaster : in  AxiStreamMasterType;
      dmaObSlave  : out AxiStreamSlaveType;
      dmaIbMaster : out AxiStreamMasterType;
      dmaIbSlave  : in  AxiStreamSlaveType);
end DmaSrpTest;

architecture mapping of DmaSrpTest is

   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType;

begin

   U_SRPv3 : entity work.SrpV3AxiLite
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         GEN_SYNC_FIFO_G     => true,
         AXI_STREAM_CONFIG_G => RCEG3_AXIS_DMA_CONFIG_C)
      port map (
         -- Streaming Slave (Rx) Interface (sAxisClk domain) 
         sAxisClk         => clk,
         sAxisRst         => rst,
         sAxisMaster      => dmaObMaster,
         sAxisSlave       => dmaObSlave,
         -- Streaming Master (Tx) Data Interface (mAxisClk domain)
         mAxisClk         => clk,
         mAxisRst         => rst,
         mAxisMaster      => dmaIbMaster,
         mAxisSlave       => dmaIbSlave,
         -- Master AXI-Lite Interface (axilClk domain)
         axilClk          => clk,
         axilRst          => rst,
         mAxilReadMaster  => axilReadMaster,
         mAxilReadSlave   => axilReadSlave,
         mAxilWriteMaster => axilWriteMaster,
         mAxilWriteSlave  => axilWriteSlave);

   U_AxiVersion : entity work.AxiVersion
      generic map (
         TPD_G        => TPD_G,
         BUILD_INFO_G => BUILD_INFO_G,
         CLK_PERIOD_G => (1.0/200.0E+6))
      port map (
         -- AXI-Lite Register Interface
         axiReadMaster  => axilReadMaster,
         axiReadSlave   => axilReadSlave,
         axiWriteMaster => axilWriteMaster,
         axiWriteSlave  => axilWriteSlave,
         -- Clocks and Resets
         axiClk         => clk,
         axiRst         => rst);

end mapping;
