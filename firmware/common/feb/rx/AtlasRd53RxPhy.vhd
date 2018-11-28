-------------------------------------------------------------------------------
-- File       : AtlasRd53RxPhy.vhd
-- Company    : SLAC National Accelerator Laboratory
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
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.Pgp3Pkg.all;
use work.AtlasRd53Pkg.all;

entity AtlasRd53RxPhy is
   generic (
      TPD_G        : time   := 1 ns;
      SYNTH_MODE_G : string := "inferred");
   port (
      -- Misc. Interfaces
      enLocalEmu      : in  sl;
      asicRstIn       : in  sl;         -- TBD interface
      iDelayCtrlRdy   : in  sl;
      invCmd          : in  sl;
      enable          : in  slv(3 downto 0);
      invData         : in  slv(3 downto 0);
      linkUp          : out slv(3 downto 0);
      chBond          : out sl;
      rxPhyXbar       : in  Slv2Array(3 downto 0);
      debugStream     : in  sl;
      -- RD53 ASIC Serial Ports
      dPortDataP      : in  slv(3 downto 0);
      dPortDataN      : in  slv(3 downto 0);
      dPortCmdP       : out sl;
      dPortCmdN       : out sl;
      -- Timing/Trigger Interface
      clk640MHz       : in  sl;
      clk160MHz       : in  sl;
      clk80MHz        : in  sl;
      clk40MHz        : in  sl;
      rst640MHz       : in  sl;
      rst160MHz       : in  sl;
      rst80MHz        : in  sl;
      rst40MHz        : in  sl;
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_SLVERR_C;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_SLVERR_C;
      -- Streaming RD53 Config/Trig Interface (clk160MHz domain)
      sConfigMaster   : in  AxiStreamMasterType;
      sConfigSlave    : out AxiStreamSlaveType;
      mConfigMaster   : out AxiStreamMasterType;
      mConfigSlave    : in  AxiStreamSlaveType;
      tluTrigMaster   : in  AxiStreamMasterType;
      tluTrigSlave    : out AxiStreamSlaveType;
      -- Outbound Reg/Data Interface (axilClk domain)
      mDataMaster     : out AxiStreamMasterType;
      mDataSlave      : in  AxiStreamSlaveType;
      dataDrop        : out sl;
      autoReadReg     : out Slv32Array(3 downto 0));
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
      tUser  => toSlv(2, AXI_STREAM_MAX_TDATA_WIDTH_C));  -- Set the Start of Frame bit for SSI

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
   signal enableSync  : slv(3 downto 0);
   signal invDataSync : slv(3 downto 0);

   signal dataCtrl : AxiStreamCtrlType;

begin

   ------------------------
   -- CMD Generation Module
   ------------------------
   U_Cmd : entity work.AtlasRd53TxCmdWrapper
      generic map (
         TPD_G        => TPD_G,
         SYNTH_MODE_G => SYNTH_MODE_G)
      port map (
         -- Streaming RD53 Config/Trig Interface (clk160MHz domain)
         sConfigMaster => sConfigMaster,
         sConfigSlave  => sConfigSlave,
         tluTrigMaster => tluTrigMaster,
         tluTrigSlave  => tluTrigSlave,
         -- Timing Interface
         clk640MHz     => clk640MHz,
         clk160MHz     => clk160MHz,
         clk80MHz      => clk80MHz,
         clk40MHz      => clk40MHz,
         rst640MHz     => rst640MHz,
         rst160MHz     => rst160MHz,
         rst80MHz      => rst80MHz,
         rst40MHz      => rst40MHz,
         -- Command Serial Interface (clk160MHz domain)
         invCmd        => invCmd,
         cmdOutP       => dPortCmdP,
         cmdOutN       => dPortCmdN);

   ---------------
   -- RX PHY Layer
   ---------------
   U_RxPhyLayer : entity work.AuroraRxChannel
      generic map (
         TPD_G        => TPD_G,
         SYNTH_MODE_G => SYNTH_MODE_G)
      port map (
         -- RD53 ASIC Serial Ports
         dPortDataP  => dPortDataP,
         dPortDataN  => dPortDataN,
         -- Timing Interface
         clk640MHz   => clk640MHz,
         clk160MHz   => clk160MHz,
         rst160MHz   => rst160MHz,
         -- Control Interface
         enable      => enableSync,
         invData     => invDataSync,
         linkUp      => linkUp,
         chBond      => chBond,
         rxPhyXbar   => rxPhyXbar,
         debugStream => debugStream,
         -- AutoReg and Read back Interface
         axisData    => rx,
         autoReadReg => autoReg,
         rdReg       => rdReg);

   U_enable : entity work.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 4)
      port map (
         clk     => clk160MHz,
         dataIn  => enable,
         dataOut => enableSync);

   U_invData : entity work.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 4)
      port map (
         clk     => clk160MHz,
         dataIn  => invData,
         dataOut => invDataSync);

   ----------------------------
   -- Local Emulation PHY Layer
   ----------------------------
   -- Placeholder for future code
   emuRx         <= AXIS_MASTER_INIT_C;
   emuRdReg      <= AXIS_MASTER_INIT_C;
   emuAutoRegOut <= (others => x"0000_0000");

   ----------------------------------------
   -- Mux for selecting RX PHY or emulation
   ----------------------------------------
   rxOut         <= rx      when(enEmu = '0') else emuRx;
   mConfigMaster <= rdReg   when(enEmu = '0') else emuRdReg;
   autoRegOut    <= autoReg when(enEmu = '0') else emuAutoRegOut;

   U_enEmu : entity work.Synchronizer
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
         SYNTH_MODE_G        => SYNTH_MODE_G,
         MEMORY_TYPE_G       => "block",
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

   GEN_VEC : for i in 3 downto 0 generate

      U_autoReadReg : entity work.SynchronizerFifo
         generic map (
            TPD_G        => TPD_G,
            SYNTH_MODE_G => SYNTH_MODE_G,
            DATA_WIDTH_G => 32)
         port map (
            wr_clk => clk160MHz,
            din    => autoRegOut(i),
            rd_clk => axilClk,
            dout   => autoReadReg(i));

   end generate GEN_VEC;

end mapping;
