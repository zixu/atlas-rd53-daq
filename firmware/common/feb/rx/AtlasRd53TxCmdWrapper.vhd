-------------------------------------------------------------------------------
-- File       : AtlasRd53TxCmdWrapper.vhd
-- Company    : SLAC National Accelerator Laboratory
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
use work.SsiPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AtlasRd53TxCmdWrapper is
   generic (
      TPD_G        : time   := 1 ns;
      SYNTH_MODE_G : string := "inferred");
   port (
      -- Streaming RD53 Config/Trig Interface (clk160MHz domain)
      sConfigMaster : in  AxiStreamMasterType;
      sConfigSlave  : out AxiStreamSlaveType;
      tluTrigMaster : in  AxiStreamMasterType;
      tluTrigSlave  : out AxiStreamSlaveType;
      -- Timing Interface
      clk640MHz     : in  sl;
      clk160MHz     : in  sl;
      clk80MHz      : in  sl;
      clk40MHz      : in  sl;
      rst640MHz     : in  sl;
      rst160MHz     : in  sl;
      rst80MHz      : in  sl;
      rst40MHz      : in  sl;
      -- Command Serial Interface (clk160MHz domain)
      invCmd        : in  sl;
      cmdOut        : out sl;           -- Copy of CMD for local emulation
      cmdOutP       : out sl;
      cmdOutN       : out sl);
end entity AtlasRd53TxCmdWrapper;

architecture rtl of AtlasRd53TxCmdWrapper is

   signal cmd     : sl;
   signal cmdMask : sl;
   signal cmdReg  : sl;

   signal cmdMaster : AxiStreamMasterType;
   signal cmdSlave  : AxiStreamSlaveType;

   signal muxMaster : AxiStreamMasterType;
   signal muxSlave  : AxiStreamSlaveType;

begin

   U_Mux : entity work.AxiStreamMux
      generic map (
         TPD_G         => TPD_G,
         NUM_SLAVES_G  => 2,
         PIPE_STAGES_G => 1)
      port map (
         -- Clock and reset
         axisClk         => clk160MHz,
         axisRst         => rst160MHz,
         -- Slaves
         sAxisMasters(0) => sConfigMaster,
         sAxisMasters(1) => tluTrigMaster,
         sAxisSlaves(0)  => sConfigSlave,
         sAxisSlaves(1)  => tluTrigSlave,
         -- Master
         mAxisMaster     => muxMaster,
         mAxisSlave      => muxSlave);

   U_FW_CACH : entity work.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 0,
         PIPE_STAGES_G       => 0,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 4090,   -- less than 2**FIFO_ADDR_WIDTH_G
         VALID_BURST_MODE_G  => true,   -- bursting mode enabled
         -- FIFO configurations
         SYNTH_MODE_G        => SYNTH_MODE_G,
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => true,
         FIFO_ADDR_WIDTH_G   => 12,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => ssiAxiStreamConfig(4),
         MASTER_AXI_CONFIG_G => ssiAxiStreamConfig(4))
      port map (
         -- Slave Port
         sAxisClk    => clk160MHz,
         sAxisRst    => rst160MHz,
         sAxisMaster => muxMaster,
         sAxisSlave  => muxSlave,
         -- Master Port
         mAxisClk    => clk160MHz,
         mAxisRst    => rst160MHz,
         mAxisMaster => cmdMaster,
         mAxisSlave  => cmdSlave);

   U_Cmd : entity work.AtlasRd53TxCmd
      generic map (
         TPD_G => TPD_G)
      port map (
         -- Clock and Reset
         clk160MHz => clk160MHz,
         rst160MHz => rst160MHz,
         -- Streaming RD53 Config Interface (clk160MHz domain)
         cmdMaster => cmdMaster,
         cmdSlave  => cmdSlave,
         -- Serial Output Interface
         cmdOut    => cmd);

   cmdOut <= cmd;

   cmdMask <= cmd xor invCmd;

   U_ODDR : ODDR
      generic map(
         DDR_CLK_EDGE => "OPPOSITE_EDGE",  -- "OPPOSITE_EDGE" or "SAME_EDGE" 
         INIT         => '0',  -- Initial value for Q port ('1' or '0')
         SRTYPE       => "SYNC")        -- Reset Type ("ASYNC" or "SYNC")
      port map (
         D1 => cmdMask,                 -- 1-bit data input (positive edge)
         D2 => cmdMask,                 -- 1-bit data input (negative edge)
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
