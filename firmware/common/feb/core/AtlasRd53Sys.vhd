-------------------------------------------------------------------------------
-- File       : AtlasRd53Sys.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-18
-- Last update: 2018-05-25
-------------------------------------------------------------------------------
-- Description: System Level Modules
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
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.I2cPkg.all;
use work.AtlasRd53Pkg.all;

library unisim;
use unisim.vcomponents.all;

entity AtlasRd53Sys is
   generic (
      TPD_G           : time             := 1 ns;
      BUILD_INFO_G    : BuildInfoType;
      AXI_CLK_FREQ_G  : real             := 156.25E+6;  -- units of Hz
      AXI_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      -- Configuration/Status interface
      status          : in    AtlasRd53StatusType;
      config          : out   AtlasRd53ConfigType;
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;
      -- NTC SPI Ports
      dPortNtcCsL     : out   slv(3 downto 0);
      dPortNtcSck     : out   slv(3 downto 0);
      dPortNtcSdo     : in    slv(3 downto 0);
      -- QSFP Ports
      qsfpScl         : inout sl;
      qsfpSda         : inout sl;
      qsfpLpMode      : out   sl;
      qsfpRst         : out   sl;
      qsfpSel         : out   sl;
      qsfpIntL        : in    sl;
      qsfpPrstL       : in    sl;
      -- Boot Memory Ports
      bootCsL         : out   sl;
      bootMosi        : out   sl;
      bootMiso        : in    sl;
      -- Misc Ports
      pwrScl          : inout sl;
      pwrSda          : inout sl;
      tempAlertL      : in    sl;
      vPIn            : in    sl;
      vNIn            : in    sl);
end AtlasRd53Sys;

architecture mapping of AtlasRd53Sys is

   constant NUM_AXIL_MASTERS_C : natural := 6;

   constant VERSION_INDEX_C  : natural := 0;
   constant XADC_INDEX_C     : natural := 1;
   constant BOOT_MEM_INDEX_C : natural := 2;
   constant SYS_REG_INDEX_C  : natural := 3;
   constant NTC_INDEX_C      : natural := 4;
   constant PWR_INDEX_C      : natural := 5;

   constant XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := (
      VERSION_INDEX_C  => (
         baseAddr      => (AXI_BASE_ADDR_G+x"0000_0000"),
         addrBits      => 16,
         connectivity  => x"FFFF"),
      XADC_INDEX_C     => (
         baseAddr      => (AXI_BASE_ADDR_G+x"0001_0000"),
         addrBits      => 16,
         connectivity  => x"FFFF"),
      BOOT_MEM_INDEX_C => (
         baseAddr      => (AXI_BASE_ADDR_G+x"0002_0000"),
         addrBits      => 16,
         connectivity  => x"FFFF"),
      SYS_REG_INDEX_C  => (
         baseAddr      => (AXI_BASE_ADDR_G+x"0003_0000"),
         addrBits      => 16,
         connectivity  => x"FFFF"),
      NTC_INDEX_C      => (
         baseAddr      => (AXI_BASE_ADDR_G+x"0004_0000"),
         addrBits      => 16,
         connectivity  => x"FFFF"),
      PWR_INDEX_C      => (
         baseAddr      => (AXI_BASE_ADDR_G+x"0005_0000"),
         addrBits      => 16,
         connectivity  => x"FFFF"));

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   constant PWR_I2C_C : I2cAxiLiteDevArray(1 downto 0) := (
      0              => MakeI2cAxiLiteDevType(
         i2cAddress  => "1001000",      -- 0x90 = SA56004ATK
         dataSize    => 8,              -- in units of bits
         addrSize    => 8,              -- in units of bits
         endianness  => '0',            -- Little endian                   
         repeatStart => '0'),           -- No repeat start                   
      1              => MakeI2cAxiLiteDevType(
         i2cAddress  => "1101111",      -- 0xDE = LTC4151CMS#PBF
         dataSize    => 8,              -- in units of bits
         addrSize    => 8,              -- in units of bits
         endianness  => '0',            -- Little endian   
         repeatStart => '1'));          -- Repeat Start  

   signal bootSck : sl;

   signal ntcClk : sl;
   signal ntcSdi : sl;
   signal ntcCsL : slv(3 downto 0);

begin

   qsfpLpMode <= '0';                   -- Not low power mode
   qsfpRst    <= not(axilRst);          -- Invert of system reset
   qsfpSel    <= '1';                   -- '1' = module not responds to I2C

   --------------------------
   -- AXI-Lite: Crossbar Core
   --------------------------  
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => XBAR_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   ---------------------------
   -- AXI-Lite: Version Module
   ---------------------------          
   U_AxiVersion : entity work.AxiVersion
      generic map (
         TPD_G              => TPD_G,
         BUILD_INFO_G       => BUILD_INFO_G,
         CLK_PERIOD_G       => (1.0/AXI_CLK_FREQ_G),
         XIL_DEVICE_G       => "7SERIES",
         EN_DEVICE_DNA_G    => true,
         EN_DS2411_G        => false,
         EN_ICAP_G          => true,
         AUTO_RELOAD_EN_G   => false,
         AUTO_RELOAD_TIME_G => 10.0,    -- 10 seconds
         AUTO_RELOAD_ADDR_G => x"04000000")
      port map (
         -- AXI-Lite Register Interface
         axiReadMaster  => axilReadMasters(VERSION_INDEX_C),
         axiReadSlave   => axilReadSlaves(VERSION_INDEX_C),
         axiWriteMaster => axilWriteMasters(VERSION_INDEX_C),
         axiWriteSlave  => axilWriteSlaves(VERSION_INDEX_C),
         -- Clocks and Resets
         axiClk         => axilClk,
         axiRst         => axilRst);

   -----------------------
   -- AXI-Lite XADC Module
   -----------------------
   U_Xadc : entity work.AxiXadcMinimumCore
      port map (
         -- XADC Ports
         vPIn           => vPIn,
         vNIn           => vNIn,
         -- AXI-Lite Register Interface
         axiReadMaster  => axilReadMasters(XADC_INDEX_C),
         axiReadSlave   => axilReadSlaves(XADC_INDEX_C),
         axiWriteMaster => axilWriteMasters(XADC_INDEX_C),
         axiWriteSlave  => axilWriteSlaves(XADC_INDEX_C),
         -- Clocks and Resets
         axiClk         => axilClk,
         axiRst         => axilRst);

   ------------------------------
   -- AXI-Lite: Boot Flash Module
   ------------------------------
   U_BootProm : entity work.AxiMicronN25QCore
      generic map (
         TPD_G           => TPD_G,
         MEM_ADDR_MASK_G => x"00000000",  -- Using hardware write protection
         AXI_CLK_FREQ_G  => AXI_CLK_FREQ_G,        -- units of Hz
         SPI_CLK_FREQ_G  => (AXI_CLK_FREQ_G/8.0))  -- units of Hz
      port map (
         -- FLASH Memory Ports
         csL            => bootCsL,
         sck            => bootSck,
         mosi           => bootMosi,
         miso           => bootMiso,
         -- AXI-Lite Register Interface
         axiReadMaster  => axilReadMasters(BOOT_MEM_INDEX_C),
         axiReadSlave   => axilReadSlaves(BOOT_MEM_INDEX_C),
         axiWriteMaster => axilWriteMasters(BOOT_MEM_INDEX_C),
         axiWriteSlave  => axilWriteSlaves(BOOT_MEM_INDEX_C),
         -- Clocks and Resets
         axiClk         => axilClk,
         axiRst         => axilRst);

   -----------------------------------------------------
   -- Using the STARTUPE2 to access the FPGA's CCLK port
   -----------------------------------------------------
   STARTUPE2_Inst : STARTUPE2
      port map (
         CFGCLK    => open,  -- 1-bit output: Configuration main clock output
         CFGMCLK   => open,  -- 1-bit output: Configuration internal oscillator clock output
         EOS       => open,  -- 1-bit output: Active high output signal indicating the End Of Startup.
         PREQ      => open,  -- 1-bit output: PROGRAM request to fabric output
         CLK       => '0',  -- 1-bit input: User start-up clock input
         GSR       => '0',  -- 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
         GTS       => '0',  -- 1-bit input: Global 3-state input (GTS cannot be used for the port name)
         KEYCLEARB => '0',  -- 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
         PACK      => '0',  -- 1-bit input: PROGRAM acknowledge input
         USRCCLKO  => bootSck,          -- 1-bit input: User CCLK input
         USRCCLKTS => '0',  -- 1-bit input: User CCLK 3-state enable input
         USRDONEO  => '1',  -- 1-bit input: User DONE pin output control
         USRDONETS => '1');  -- 1-bit input: User DONE 3-state enable output            

   -----------------------------------
   -- AXI-Lite: System Register Module
   -----------------------------------
   U_SysReg : entity work.AtlasRd53SysReg
      generic map (
         TPD_G          => TPD_G,
         AXI_CLK_FREQ_G => AXI_CLK_FREQ_G)
      port map (
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(SYS_REG_INDEX_C),
         axilReadSlave   => axilReadSlaves(SYS_REG_INDEX_C),
         axilWriteMaster => axilWriteMasters(SYS_REG_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(SYS_REG_INDEX_C),
         -- System Interface 
         status          => status,
         config          => config);

   --------------------
   -- AXI-Lite: NTC SPI
   --------------------
   U_NtcSpi : entity work.AxiSpiMaster
      generic map (
         TPD_G             => TPD_G,
         ADDRESS_SIZE_G    => 0,
         DATA_SIZE_G       => 11,        -- 10-bit + sign output code
         MODE_G            => "RO",      -- "RO" (read only)
         CLK_PERIOD_G      => (1/AXI_CLK_FREQ_G),
         SPI_SCLK_PERIOD_G => (1.0E-6),  -- 1us = 1/(1 MHz)
         SPI_NUM_CHIPS_G   => 4)
      port map (
         -- AXI-Lite Register Interface
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => axilReadMasters(NTC_INDEX_C),
         axiReadSlave   => axilReadSlaves(NTC_INDEX_C),
         axiWriteMaster => axilWriteMasters(NTC_INDEX_C),
         axiWriteSlave  => axilWriteSlaves(NTC_INDEX_C),
         -- SPI Ports
         coreSclk       => ntcClk,
         coreSDin       => ntcSdi,
         coreMCsb       => ntcCsL);

   process(dPortNtcSdo, ntcClk, ntcCsL)
      variable sclk : slv(3 downto 0);
      variable din  : sl;
   begin
      -- Set the default values
      sclk := x"0";
      din  := '0';
      -- Check the chip select bus
      for i in 3 downto 0 loop
         if ntcCsL(i) = '0' then
            sclk(i) := ntcClk;
            din     := dPortNtcSdo(i);
         end if;
      end loop;
      -- Return the results
      dPortNtcCsL <= ntcCsL;
      dPortNtcSck <= sclk;
      ntcSdi      <= din;
   end process;

   ----------------------
   -- AXI-Lite: Power I2C
   ----------------------
   U_PwrI2C : entity work.AxiI2cRegMaster
      generic map (
         TPD_G          => TPD_G,
         DEVICE_MAP_G   => PWR_I2C_C,
         I2C_SCL_FREQ_G => 400.0E+3,    -- units of Hz
         AXI_CLK_FREQ_G => AXI_CLK_FREQ_G)
      port map (
         -- I2C Ports
         scl            => pwrScl,
         sda            => pwrSda,
         -- AXI-Lite Register Interface
         axiReadMaster  => axilReadMasters(PWR_INDEX_C),
         axiReadSlave   => axilReadSlaves(PWR_INDEX_C),
         axiWriteMaster => axilWriteMasters(PWR_INDEX_C),
         axiWriteSlave  => axilWriteSlaves(PWR_INDEX_C),
         -- Clocks and Resets
         axiClk         => axilClk,
         axiRst         => axilRst);

end mapping;
