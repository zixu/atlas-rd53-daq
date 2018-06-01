-------------------------------------------------------------------------------
-- File       : AtlasRd53RxPhy.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-18
-- Last update: 2018-05-31
-------------------------------------------------------------------------------
-- Description: RX PHY Module
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
use work.AtlasRd53Pkg.all;

entity AtlasRd53RxPhy is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Misc. Interfaces
      enLocalEmu    : in  sl;
      asicRst       : in  sl;
      iDelayCtrlRdy : in  sl;
      -- RD53 ASIC Serial Ports
      dPortDataP    : in  slv(3 downto 0);
      dPortDataN    : in  slv(3 downto 0);
      dPortCmdP     : out sl;
      dPortCmdN     : out sl;
      dPortRst      : out sl;
      -- Timing/Trigger Interface
      clk640MHz     : in  sl;
      clk160MHz     : in  sl;
      clk80MHz      : in  sl;
      clk40MHz      : in  sl;
      rst640MHz     : in  sl;
      rst160MHz     : in  sl;
      rst80MHz      : in  sl;
      rst40MHz      : in  sl;
      ttc           : in  AtlasRd53TimingTrigType;  -- clk160MHz domain
      -- Outbound Reg/Data Interface (axilClk domain)
      axilClk       : in  sl;
      axilRst       : in  sl;
      mDataMaster   : out AxiStreamMasterType;
      mDataSlave    : in  AxiStreamSlaveType;
      dataDrop      : out sl;
      sCmdMaster    : in  AxiStreamMasterType;
      sCmdSlave     : out AxiStreamSlaveType;
      mCmdMaster    : out AxiStreamMasterType;
      mCmdSlave     : in  AxiStreamSlaveType;
      cmdDrop       : out sl;
      autoReadReg   : out Slv32Array(3 downto 0));
end AtlasRd53RxPhy;

architecture mapping of AtlasRd53RxPhy is

   constant AXIS_MASTER_INIT_C : AxiStreamMasterType := (
      tValid => '0',
      tData  => (others => '0'),
      tStrb  => (others => '1'),
      tKeep  => (others => '1'),
      tLast  => '1',                    -- single 64-bit word transactions
      tDest  => (others => '0'),
      tId    => (others => '0'),
      tUser  => toSlv(2, 128));         -- Set the Start of Frame bit for SSI

   signal rx      : AxiStreamMasterType    := AXIS_MASTER_INIT_C;
   signal rdReg   : AxiStreamMasterType    := AXIS_MASTER_INIT_C;
   signal autoReg : Slv32Array(3 downto 0) := (others => x"0000_0000");

   signal emuRx         : AxiStreamMasterType    := AXIS_MASTER_INIT_C;
   signal emuRdReg      : AxiStreamMasterType    := AXIS_MASTER_INIT_C;
   signal emuAutoRegOut : Slv32Array(3 downto 0) := (others => x"0000_0000");

   signal rxOut      : AxiStreamMasterType    := AXIS_MASTER_INIT_C;
   signal rdRegOut   : AxiStreamMasterType    := AXIS_MASTER_INIT_C;
   signal autoRegOut : Slv32Array(3 downto 0) := (others => x"0000_0000");

   signal dPortCmd    : sl;
   signal dPortCmdReg : sl;
   signal enEmu       : sl;

   signal dataCtrl : AxiStreamCtrlType;
   signal cmdCtrl  : AxiStreamCtrlType;

begin

   dPortRst <= rst160MHz or asicRst;  -- Inverted in HW on FPGA board before dport connector

   ------------------------
   -- CMD Generation Module
   ------------------------
   U_Cmd : entity work.AtlasRd53TxCmdWrapper
      generic map (
         TPD_G => TPD_G)
      port map (
         -- AXI Stream Interface (axilClk domain)
         axilClk    => axilClk,
         axilRst    => axilRst,
         sCmdMaster => sCmdMaster,
         sCmdSlave  => sCmdSlave,
         -- Timing Interface (clk160MHz domain)
         clk160MHz  => clk160MHz,
         rst160MHz  => rst160MHz,
         ttc        => ttc,
         -- Command Serial Interface (clk160MHz domain)
         cmdOutP    => dPortCmdP,
         cmdOutN    => dPortCmdN);

   ---------------
   -- RX PHY Layer
   ---------------
   U_RxPhyLayer : entity work.aurora_rx_channel
      generic map (
         g_NUM_LANES => 4)
      port map (
         rst_n_i      => not(rst160MHz),
         clk_rx_i     => clk160MHz,        -- Fabric clock (serdes/8)
         clk_serdes_i => clk640MHz,        -- IO clock
         -- Input
         enable_i     => not(asicRst),
         rx_data_i_p  => dPortDataP,
         rx_data_i_n  => dPortDataN,
         trig_tag_i   => (others => '0'),  -- Unused
         -- Output
         rx_data_o    => rx.tData(63 downto 0),
         rx_valid_o   => rx.tValid,
         rx_stat_o    => open);

   -- Placeholder for future code
   emuRdReg      <= AXIS_MASTER_INIT_C;
   emuAutoRegOut <= (others => x"0000_0000");

   -------------------------
   -- TX Emulation PHY Layer
   -------------------------
   -- Placeholder for future code
   emuRx         <= AXIS_MASTER_INIT_C;
   emuRdReg      <= AXIS_MASTER_INIT_C;
   emuAutoRegOut <= (others => x"0000_0000");

   ----------------------------------------
   -- Mux for selecting RX PHY or emulation
   ----------------------------------------
   rxOut      <= rx      when(enEmu = '0') else emuRx;
   rdRegOut   <= rdReg   when(enEmu = '0') else emuRdReg;
   autoRegOut <= autoReg when(enEmu = '0') else emuAutoRegOut;

   U_enEmu : entity work.SynchronizerOneShot
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => clk160MHz,
         dataIn  => enLocalEmu,
         dataOut => enEmu);

   ---------------------------------------------   
   -- Synchronize the outputs to AXI clock domain
   ---------------------------------------------      
   U_SyncRxData : entity work.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => false,
         VALID_THOLD_G       => 1,
         -- FIFO configurations
         BRAM_EN_G           => true,
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 9,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => PGP3_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => PGP3_AXIS_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => clk160MHz,
         sAxisRst    => rst160MHz,
         sAxisMaster => rxOut,
         sAxisCtrl   => dataCtrl,
         -- Master Port
         mAxisClk    => axilClk,
         mAxisRst    => axilRst,
         mAxisMaster => mDataMaster,
         mAxisSlave  => mDataSlave);

   U_dataDrop : entity work.SynchronizerOneShot
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => axilClk,
         dataIn  => dataCtrl.overflow,
         dataOut => dataDrop);

   U_SyncCmdData : entity work.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => false,
         VALID_THOLD_G       => 1,
         -- FIFO configurations
         BRAM_EN_G           => true,
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 9,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => PGP3_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => PGP3_AXIS_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => clk160MHz,
         sAxisRst    => rst160MHz,
         sAxisMaster => rdRegOut,
         sAxisCtrl   => cmdCtrl,
         -- Master Port
         mAxisClk    => axilClk,
         mAxisRst    => axilRst,
         mAxisMaster => mCmdMaster,
         mAxisSlave  => mCmdSlave);

   U_cmdDrop : entity work.SynchronizerOneShot
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => axilClk,
         dataIn  => cmdCtrl.overflow,
         dataOut => cmdDrop);

   GEN_VEC : for i in 3 downto 0 generate

      U_autoReadReg : entity work.SynchronizerFifo
         generic map (
            TPD_G        => TPD_G,
            DATA_WIDTH_G => 32)
         port map (
            wr_clk => clk160MHz,
            din    => autoRegOut(i),
            rd_clk => axilClk,
            dout   => autoReadReg(i));

   end generate GEN_VEC;

end mapping;
