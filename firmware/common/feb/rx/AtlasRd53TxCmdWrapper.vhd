-------------------------------------------------------------------------------
-- File       : AtlasRd53TxCmdWrapper.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-05-31
-- Last update: 2018-05-31
-------------------------------------------------------------------------------
-- Description: Wrapper for AtlasRd53TxCmd
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
use work.AxiStreamPkg.all;
use work.Pgp3Pkg.all;
use work.AtlasRd53Pkg.all;

library unisim;
use unisim.vcomponents.all;

entity AtlasRd53TxCmdWrapper is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- AXI Stream Interface (axilClk domain)
      axilClk    : in  sl;
      axilRst    : in  sl;
      sCmdMaster : in  AxiStreamMasterType;
      sCmdSlave  : out AxiStreamSlaveType;
      -- Timing Interface (clk160MHz domain)
      clk160MHz  : in  sl;
      rst160MHz  : in  sl;
      ttc        : in  AtlasRd53TimingTrigType;
      -- Command Serial Interface (clk160MHz domain)
      cmdOut     : out sl;              -- Copy of CMD for local emulation
      cmdOutP    : out sl;
      cmdOutN    : out sl);
end entity AtlasRd53TxCmdWrapper;

architecture rtl of AtlasRd53TxCmdWrapper is

   signal cmdMaster : AxiStreamMasterType;
   signal cmdSlave  : AxiStreamSlaveType;

   signal wrValid : sl;
   signal wrReady : sl;

   signal rdValid : sl;
   signal rdReady : sl;

   signal cmd    : sl;
   signal cmdReg : sl;

begin

   U_Sync : entity work.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
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
         sAxisClk    => axilClk,
         sAxisRst    => axilRst,
         sAxisMaster => sCmdMaster,
         sAxisSlave  => sCmdSlave,
         -- Master Port
         mAxisClk    => clk160MHz,
         mAxisRst    => rst160MHz,
         mAxisMaster => cmdMaster,
         mAxisSlave  => cmdSlave);

   -- Flow control
   cmdSlave.tReady <= wrReady or rdReady;

   -- Using TDATA[63] to indicate RnW operation
   wrValid <= cmdMaster.tValid and not(cmdMaster.tData(63));
   rDValid <= cmdMaster.tValid and cmdMaster.tData(63);

   U_Cmd : entity work.AtlasRd53TxCmd
      generic map (
         TPD_G => TPD_G)
      port map (
         -- Clock and Reset
         clk160MHz  => clk160MHz,
         rst160MHz  => rst160MHz,
         -- Timing/Trigger Interface
         trig       => ttc.trig,
         ecr        => ttc.ecr,
         bcr        => ttc.bcr,
         -- Global Pulse Interface
         gPulse     => ttc.gPulse,
         gPulseId   => ttc.gPulseId,
         gPulseData => ttc.gPulseData,
         -- Calibration Interface
         cal        => ttc.cal,
         calId      => ttc.calId,
         calDat     => ttc.calDat,
         -- Write Register Interface
         wrValid    => wrValid,
         wrReady    => wrReady,
         wrRegId    => cmdMaster.tData(51 downto 48),
         wrRegAddr  => cmdMaster.tData(40 downto 32),
         wrRegData  => cmdMaster.tData(15 downto 0),
         -- Read Register Interface
         rdValid    => rdValid,
         rdReady    => rdReady,
         rdRegId    => cmdMaster.tData(51 downto 48),
         rdRegAddr  => cmdMaster.tData(40 downto 32),
         -- Serial Output Interface
         cmdOut     => cmd);

   cmdOut <= cmd;

   U_ODDR : ODDR
      generic map(
         DDR_CLK_EDGE => "OPPOSITE_EDGE",  -- "OPPOSITE_EDGE" or "SAME_EDGE" 
         INIT         => '0',  -- Initial value for Q port ('1' or '0')
         SRTYPE       => "SYNC")        -- Reset Type ("ASYNC" or "SYNC")
      port map (
         D1 => cmd,                     -- 1-bit data input (positive edge)
         D2 => cmd,                     -- 1-bit data input (negative edge)
         Q  => cmdReg,                  -- 1-bit DDR output
         C  => clk160MHz,               -- 1-bit clock input
         CE => '1',                     -- 1-bit clock enable input
         R  => rst160MHz,               -- 1-bit reset
         S  => '0');                    -- 1-bit set

   U_dPortCmd : OBUFDS
      port map (
         I  => cmdReg,
         O  => cmdOutP,
         OB => cmdOutN);

end rtl;
