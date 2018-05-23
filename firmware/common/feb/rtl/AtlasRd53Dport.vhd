-------------------------------------------------------------------------------
-- File       : AtlasRd53Dport.vhd
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

entity AtlasRd53Dport is
   generic (
      TPD_G           : time             := 1 ns;
      LINK_INDEX_G    : natural          := 0;
      AXI_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      -- Misc. Interfaces
      selEmuIn        : in  sl;
      enAuxClk        : in  sl;
      userRst         : in  sl;
      iDelayCtrlRdy   : in  sl;
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Streaming RD43 Data Interface (axilClk domain)
      mDataMaster     : out AxiStreamMasterType;
      mDataSlave      : in  AxiStreamSlaveType;
      -- Streaming RD43 CMD Interface (axilClk domain)
      sCmdMaster      : in  AxiStreamMasterType;
      sCmdSlave       : out AxiStreamSlaveType;
      mCmdMaster      : out AxiStreamMasterType;
      mCmdSlave       : in  AxiStreamSlaveType;
      -- Timing Clocks Interface
      clk640MHz       : in  sl;
      clk160MHz       : in  sl;
      clk80MHz        : in  sl;
      clk40MHz        : in  sl;
      -- Timing Resets Interface
      rst640MHz       : in  sl;
      rst160MHz       : in  sl;
      rst80MHz        : in  sl;
      rst40MHz        : in  sl;
      -- RD53 ASIC Serial Ports
      dPortDataP      : in  slv(3 downto 0);
      dPortDataN      : in  slv(3 downto 0);
      dPortCmdP       : out sl;
      dPortCmdN       : out sl;
      dPortAuxP       : out sl;
      dPortAuxN       : out sl;
      dPortRst        : out sl);
end AtlasRd53Dport;

architecture mapping of AtlasRd53Dport is

   signal data     : Slv64Array(3 downto 0);
   signal sync     : Slv2Array(3 downto 0);
   signal valid    : sl;
   signal chBond   : sl;
   signal dPortCmd : sl;

begin

   -------------------------------
   -- Place holder for future code
   -------------------------------
   axilReadSlave  <= AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
   axilWriteSlave <= AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;
   sCmdSlave      <= AXI_STREAM_SLAVE_FORCE_C;
   mCmdMaster     <= AXI_STREAM_MASTER_INIT_C;

   dPortCmd <= '0';

   --------------------------------
   -- RX PHY Layer + Local Emulator
   --------------------------------
   U_RxPhy : entity work.AtlasRd53RxPhy
      generic map (
         TPD_G        => TPD_G,
         LINK_INDEX_G => LINK_INDEX_G)
      port map (
         -- Misc. Interfaces
         selEmuIn      => selEmuIn,
         enAuxClk      => enAuxClk,
         userRst       => userRst,
         iDelayCtrlRdy => iDelayCtrlRdy,
         dPortCmd      => dPortCmd,
         -- RD53 ASIC Serial Ports
         dPortDataP    => dPortDataP,
         dPortDataN    => dPortDataN,
         dPortCmdP     => dPortCmdP,
         dPortCmdN     => dPortCmdN,
         dPortAuxP     => dPortAuxP,
         dPortAuxN     => dPortAuxN,
         dPortRst      => dPortRst,
         -- RX PHY Interface
         validOut      => valid,
         chBondOut     => chBond,
         dataOut       => data,
         syncOut       => sync,
         -- Timing Clocks Interface
         clk640MHz     => clk640MHz,
         clk160MHz     => clk160MHz,
         clk80MHz      => clk80MHz,
         clk40MHz      => clk40MHz,
         -- Timing Resets Interface
         rst640MHz     => rst640MHz,
         rst160MHz     => rst160MHz,
         rst80MHz      => rst80MHz,
         rst40MHz      => rst40MHz);

   U_Packetizer : entity work.AtlasRd53DportPacketizer
      generic map (
         TPD_G => TPD_G)
      port map (
         -- Aligned Inbound Interface
         clk160MHz     => clk160MHz,
         rst160MHz     => rst160MHz,
         clk40MHz      => clk40MHz,
         rst40MHz      => rst40MHz,
         data          => data,
         sync          => sync,
         valid         => valid,
         channelBonded => chBond,
         -- AXI Stream Interface
         mAxisClk      => axilClk,
         mAxisRst      => axilRst,
         mAxisMaster   => mDataMaster,
         mAxisSlave    => mDataSlave);

end mapping;
