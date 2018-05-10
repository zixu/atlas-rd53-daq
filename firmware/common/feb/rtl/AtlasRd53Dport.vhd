-------------------------------------------------------------------------------
-- File       : AtlasRd53Dport.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-18
-- Last update: 2018-05-09
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
      AXI_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
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
      -- Timing Clocks
      clk640MHz       : in  sl;
      rst640MHz       : in  sl;
      clk160MHz       : in  sl;
      rst160MHz       : in  sl;
      clk40MHz        : in  sl;
      rst40MHz        : in  sl;
      iDelayCtrlRdy   : in  sl;
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

   signal dataUnaligned  : Slv64Array(3 downto 0);
   signal syncUnaligned  : Slv2Array(3 downto 0);
   signal blockSync      : slv(3 downto 0);
   signal gearboxRdyRx   : slv(3 downto 0);
   signal validUnaligned : slv(3 downto 0);

   signal data          : Slv64Array(3 downto 0);
   signal sync          : Slv2Array(3 downto 0);
   signal valid         : sl;
   signal channelBonded : sl;

begin

   dPortRst <= rst40MHz;  -- Inverted in HW on FPGA board before dport connector

   U_dPortAux : entity work.ClkOutBufDiff
      generic map (
         TPD_G        => TPD_G,
         XIL_DEVICE_G => "7SERIES")
      port map (
         clkIn   => clk160MHz,
         clkOutP => dPortAuxP,
         clkOutN => dPortAuxN);

   U_dPortCmd : OBUFDS
      port map (
         I  => '0',                     -- Placeholder for future code
         O  => dPortCmdP,
         OB => dPortCmdN);

   -- Place holder for future code
   axilReadSlave  <= AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
   axilWriteSlave <= AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;
   sCmdSlave      <= AXI_STREAM_SLAVE_FORCE_C;
   mCmdMaster     <= AXI_STREAM_MASTER_INIT_C;

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

   U_channel_bond : channel_bond
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
         channel_bonded   => channelBonded);

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
         channelBonded => channelBonded,
         -- AXI Stream Interface
         mAxisClk      => axilClk,
         mAxisRst      => axilRst,
         mAxisMaster   => mDataMaster,
         mAxisSlave    => mDataSlave);

end mapping;
