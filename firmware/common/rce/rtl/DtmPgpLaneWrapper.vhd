-------------------------------------------------------------------------------
-- File       : DtmPgpLaneWrapper.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-05-01
-- Last update: 2018-05-01
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
use work.BuildInfoPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;

library unisim;
use unisim.vcomponents.all;

entity DtmPgpLaneWrapper is
   generic (
      TPD_G           : time             := 1 ns;
      AXI_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      -- RTM Interface
      refClk250P      : in  sl;
      refClk250N      : in  sl;
      dtmToRtmHsP     : out sl;
      dtmToRtmHsN     : out sl;
      rtmToDtmHsP     : in  sl;
      rtmToDtmHsN     : in  sl;
      -- DMA Interface (dmaClk domain)
      dmaClk          : in  sl;
      dmaRst          : in  sl;
      dmaObMaster     : in  AxiStreamMasterType;
      dmaObSlave      : out AxiStreamSlaveType;
      dmaIbMaster     : out AxiStreamMasterType;
      dmaIbSlave      : in  AxiStreamSlaveType;
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end DtmPgpLaneWrapper;

architecture mapping of DtmPgpLaneWrapper is

   signal refClk250 : sl;

begin

   ------------------------
   -- Common PGP Clocking
   ------------------------
   U_IBUFDS_GTE2 : IBUFDS_GTE2
      port map (
         I     => refClk250P,
         IB    => refClk250N,
         CEB   => '0',
         O     => refClk250,
         ODIV2 => open);

   U_Lane : entity work.PgpLane
      generic map (
         TPD_G           => TPD_G,
         LANE_G          => 0,
         NUM_VC_G        => 16,
         AXI_BASE_ADDR_G => AXI_BASE_ADDR_G)
      port map (
         -- PGP Serial Ports
         pgpRxP          => rtmToDtmHsP,
         pgpRxN          => rtmToDtmHsN,
         pgpTxP          => dtmToRtmHsP,
         pgpTxN          => dtmToRtmHsN,
         -- GT Clocking
         pgpRefClk250    => refClk250,
         -- DMA Interface (dmaClk domain)
         dmaClk          => dmaClk,
         dmaRst          => dmaRst,
         dmaObMaster     => dmaObMaster,
         dmaObSlave      => dmaObSlave,
         dmaIbMaster     => dmaIbMaster,
         dmaIbSlave      => dmaIbSlave,
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave);

end mapping;
