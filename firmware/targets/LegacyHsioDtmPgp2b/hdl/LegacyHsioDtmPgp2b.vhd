-------------------------------------------------------------------------------
-- File       : LegacyHsioDtmPgp2b.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-05-29
-- Last update: 2018-05-29
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.numeric_std.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

use work.RceG3Pkg.all;
use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;

entity LegacyHsioDtmPgp2b is
   generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType);
   port (

      -- Debug
      led          : out   slv(1 downto 0);

      -- I2C
      i2cSda       : inout sl;
      i2cScl       : inout sl;

      -- Reference Clock
      locRefClkP  : in    sl;
      locRefClkM  : in    sl;

      -- Clock Select
      clkSelA     : out   sl;
      clkSelB     : out   sl;

      -- Base Ethernet
      ethRxCtrl   : in    slv(1 downto 0);
      ethRxClk    : in    slv(1 downto 0);
      ethRxDataA  : in    Slv(1 downto 0);
      ethRxDataB  : in    Slv(1 downto 0);
      ethRxDataC  : in    Slv(1 downto 0);
      ethRxDataD  : in    Slv(1 downto 0);
      ethTxCtrl   : out   slv(1 downto 0);
      ethTxClk    : out   slv(1 downto 0);
      ethTxDataA  : out   Slv(1 downto 0);
      ethTxDataB  : out   Slv(1 downto 0);
      ethTxDataC  : out   Slv(1 downto 0);
      ethTxDataD  : out   Slv(1 downto 0);
      ethMdc      : out   Slv(1 downto 0);
      ethMio      : inout Slv(1 downto 0);
      ethResetL   : out   Slv(1 downto 0);

      -- RTM High Speed
      dtmToRtmHsP : out   sl; -- to_dtm0_tx_p
      dtmToRtmHsM : out   sl; -- to_dtm0_tx_m
      rtmToDtmHsP : in    sl; -- to_dtm0_rx_p
      rtmToDtmHsM : in    sl; -- to_dtm0_rx_m

      -- RTM Low Speed
      --dtmToRtmLsP  : inout slv(5 downto 0);
      --dtmToRtmLsM  : inout slv(5 downto 0);
      busyOutP    : out sl;
      busyOutM    : out sl;
      lolInP      : in sl;
      lolInM      : in sl;
      sdInP       : in sl;
      sdInM       : in sl;

      --DTM low speed lines
      dpmClkP: out slv(2 downto 0);
      dpmClkM: out slv(2 downto 0);
      idpmFbP: in slv(3 downto 0);
      idpmFbM: in slv(3 downto 0);
      odpmFbP: out slv(3 downto 0);
      odpmFbM: out slv(3 downto 0);


      -- Backplane Clocks
      bpClkIn      : in    slv(5 downto 0);
      bpClkOut     : out   slv(5 downto 0);

      -- Spare Signals
      --plSpareP     : inout slv(4 downto 0);
      --plSpareM     : inout slv(4 downto 0);

      -- IPMI
      dtmToIpmiP   : out   slv(1 downto 0);
      dtmToIpmiM   : out   slv(1 downto 0)

   );
end LegacyHsioDtmPgp2b;

architecture STRUCTURE of LegacyHsioDtmPgp2b is

   constant TPD_C : time := 1 ns;

   -- Local Signals
   signal axiClk             : sl;
   signal axiClkRst          : sl;
   signal sysClk125          : sl;
   signal sysClk125Rst       : sl;
   signal sysClk200          : sl;
   signal sysClk200Rst       : sl;
   signal extAxilReadMaster  : AxiLiteReadMasterType;
   signal extAxilReadSlave   : AxiLiteReadSlaveType;
   signal extAxilWriteMaster : AxiLiteWriteMasterType;
   signal extAxilWriteSlave  : AxiLiteWriteSlaveType;
   signal locAxilReadMaster  : AxiLiteReadMasterArray(0 downto 0);
   signal locAxilReadSlave   : AxiLiteReadSlaveArray(0 downto 0);
   signal locAxilWriteMaster : AxiLiteWriteMasterArray(0 downto 0);
   signal locAxilWriteSlave  : AxiLiteWriteSlaveArray(0 downto 0);
   signal dmaClk             : slv(3 downto 0);
   signal dmaClkRst          : slv(3 downto 0);
   signal dmaObMaster        : AxiStreamMasterArray(3 downto 0);
   signal dmaObSlave         : AxiStreamSlaveArray(3 downto 0);
   signal dmaIbMaster        : AxiStreamMasterArray(3 downto 0);
   signal dmaIbSlave         : AxiStreamSlaveArray(3 downto 0);
   signal dpmClkIn           : slv(2 downto 0);
   signal idpmFb              : slv(3 downto 0);
   signal odpmFb              : slv(3 downto 0);
   signal lol                 : sl;

begin

   --------------------------------------------------
   -- Core
   --------------------------------------------------
   U_HsioCore: entity work.HsioCore 
      generic map (
         TPD_G          => TPD_G,
         BUILD_INFO_G   => BUILD_INFO_G,
         RCE_DMA_MODE_G => RCE_DMA_AXISV2_C)  -- AXIS V2 Driver
      port map (
         -- I2C
         i2cSda             => i2cSda,
         i2cScl             => i2cScl,
         -- Clock Select
         clkSelA            => clkSelA,
         clkSelB            => clkSelB,
         -- Base Ethernet
         ethRxCtrl          => ethRxCtrl,
         ethRxClk           => ethRxClk,
         ethRxDataA         => ethRxDataA,
         ethRxDataB         => ethRxDataB,
         ethRxDataC         => ethRxDataC,
         ethRxDataD         => ethRxDataD,
         ethTxCtrl          => ethTxCtrl,
         ethTxClk           => ethTxClk,
         ethTxDataA         => ethTxDataA,
         ethTxDataB         => ethTxDataB,
         ethTxDataC         => ethTxDataC,
         ethTxDataD         => ethTxDataD,
         ethMdc             => ethMdc,
         ethMio             => ethMio,
         ethResetL          => ethResetL,
         -- IPMI
         dtmToIpmiP         => dtmToIpmiP,
         dtmToIpmiM         => dtmToIpmiM,
         -- Clocks
         sysClk125          => sysClk125,
         sysClk125Rst       => sysClk125Rst,
         sysClk200          => sysClk200,
         sysClk200Rst       => sysClk200Rst,         
         -- External Axi Bus, 0xA0000000 - 0xAFFFFFFF
         axiClk             => axiClk,
         axiClkRst          => axiClkRst,
         extAxilReadMaster  => extAxilReadMaster,
         extAxilReadSlave   => extAxilReadSlave,
         extAxilWriteMaster => extAxilWriteMaster,
         extAxilWriteSlave  => extAxilWriteSlave,
         -- DMA Interfaces
         dmaClk             => dmaClk,
         dmaClkRst          => dmaClkRst,
         dmaObMaster        => dmaObMaster,
         dmaObSlave         => dmaObSlave,
         dmaIbMaster        => dmaIbMaster,
         dmaIbSlave         => dmaIbSlave,
         -- User Interrupts
         userInterrupt      => (others => '0'));

   -------------------------------------
   -- AXI Lite Crossbar
   -- Base: 0xA0000000 - 0xAFFFFFFF
   -------------------------------------
   U_AxiCrossbar : entity work.AxiLiteCrossbar 
      generic map (
         TPD_G              => TPD_C,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => 1,
         DEC_ERROR_RESP_G   => AXI_RESP_OK_C,
         MASTERS_CONFIG_G   => (

            -- Channel 0 = 0xA0000000 - 0xA000FFFF : PGP
            0 => ( baseAddr     => x"A0000000",
                   addrBits     => 16,
                   connectivity => x"FFFF")
         )
      ) port map (
         axiClk              => axiClk,
         axiClkRst           => axiClkRst,
         sAxiWriteMasters(0) => extAxilWriteMaster,
         sAxiWriteSlaves(0)  => extAxilWriteSlave,
         sAxiReadMasters(0)  => extAxilReadMaster,
         sAxiReadSlaves(0)   => extAxilReadSlave,
         mAxiWriteMasters    => locAxilWriteMaster,
         mAxiWriteSlaves     => locAxilWriteSlave,
         mAxiReadMasters     => locAxilReadMaster,
         mAxiReadSlaves      => locAxilReadSlave
      );


   --------------------------------------------------
   -- PPI Loopback
   --------------------------------------------------
   dmaClk(3 downto 1)      <= (others=>sysClk125);
   dmaClkRst(3 downto 1)   <= (others=>sysClk125Rst);
   dmaIbMaster(3 downto 1) <= dmaObMaster(3 downto 1);
   dmaObSlave(3 downto 1)  <= dmaIbSlave(3 downto 1);
   dmaClk(0)      <= sysClk200;
   dmaClkRst(0)   <= sysClk200Rst;



   --------------------------------------------------
   -- PGP Lane
   --------------------------------------------------
   U_HsioPgpLane : entity work.HsioPgpLane
      generic map (
         TPD_G  => TPD_C
      ) port map (
         sysClk200       => sysClk200,
         --sysClk200Rst    => sysClk200Rst,
         axiClk          => axiClk,
         axiClkRst       => axiClkRst,
         axiReadMaster   => locAxilReadMaster(0),
         axiReadSlave    => locAxilReadSlave(0),
         axiWriteMaster  => locAxilWriteMaster(0),
         axiWriteSlave   => locAxilWriteSlave(0),
         pgpAxisClk      => dmaClk(0),
         pgpAxisRst      => dmaClkRst(0),
         pgpDataRxMaster => dmaIbMaster(0),
         pgpDataRxSlave  => dmaIbSlave(0),
         pgpDataTxMaster => dmaObMaster(0),
         pgpDataTxSlave  => dmaObSlave(0),
         locRefClkP      => locRefClkP,
         locRefClkM      => locRefClkM,
         pgpTxP          => dtmToRtmHsP,
         pgpTxM          => dtmToRtmHsM,
         pgpRxP          => rtmToDtmHsP,
         pgpRxM          => rtmToDtmHsM
      );

   --------------------------------------------------
   -- Top Level Signals
   --------------------------------------------------

   -- Debug
   led <= (others=>'0');
   dpmclkin(2 downto 0)<=(others=>'0');

   -- Reference Cloc/afs/slac.stanford.edu/g/reseng/vol15/Xilinx/vivado_2014.1/SDK/2014.1/gnu/arm/lin/k
   --locRefClkP  : in    sl;
   --locRefClkM  : in    sl;

   -- RTM High Speed
   --dtmToRtmHsP : out   sl;
   --dtmToRtmHsM : out   sl;
   --rtmToDtmHsP : in    sl;
   --rtmToDtmHsM : in    sl;

   -- RTM Low Speed
   --dtmToRtmLsP  : inout slv(5 downto 0);
   --dtmToRtmLsM  : inout slv(5 downto 0);

   -- DPM Clock Signals
   U_DpmClkGen : for i in 0 to 2 generate
      U_DpmClkOut : OBUFDS
         port map(
            O      => dpmClkP(i),
            OB     => dpmClkM(i),
            I      => dpmclkin(i) 
         );
   end generate;

   -- DPM Feedback Signals
   U_DpmFbGen : for i in 0 to 3 generate
      U_DpmFbIn : IBUFDS
         generic map ( DIFF_TERM => true ) 
         port map(
            I      => idpmFbP(i),
            IB     => idpmFbM(i),
            O      => idpmFb(i)
         );
      U_DpmFbOut : OBUFDS
         port map(
            O      => odpmFbP(i),
            OB     => odpmFbM(i),
            I      => odpmFb(i)
         );
   end generate;
      U_BusyOut : OBUFDS
         port map(
            O      => busyOutP,
            OB     => busyOutM,
            I      => idpmFb(0) 
         );
      U_sdIn : IBUFDS
         generic map ( DIFF_TERM => true ) 
         port map(
            I      => sdInP,
            IB     => sdInM,
            O      => odpmFb(0)
         );
      U_lolIn : IBUFDS
         generic map ( DIFF_TERM => true ) 
         port map(
            I      => lolInP,
            IB     => lolInM,
            O      => lol
         );
   odpmFb(1)<= not lol;
   -- Backplane Clocks
   --bpClkIn      : in    slv(5 downto 0);
   --bpClkOut     : out   slv(5 downto 0);
   bpClkOut <= (others=>'0');

   -- Spare Signals
   --plSpareP     : inout slv(4 downto 0);
   --plSpareM     : inout slv(4 downto 0)

end architecture STRUCTURE;

