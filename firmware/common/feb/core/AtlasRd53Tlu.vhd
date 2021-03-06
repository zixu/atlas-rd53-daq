-------------------------------------------------------------------------------
-- File       : AtlasRd53Tlu.vhd
-- Company    : SLAC National Accelerator Laboratory
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
use work.AtlasRd53Pkg.all;

library unisim;
use unisim.vcomponents.all;

entity AtlasRd53Tlu is
   generic (
      TPD_G           : time             := 1 ns;
      AXI_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      -- AXI-Lite Interface (clk160MHz domain)
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Reference Timing Interface
      clk640MHz       : in  sl;
      clk160MHz       : in  sl;
      clk80MHz        : in  sl;
      clk40MHz        : in  sl;
      rst640MHz       : in  sl;
      rst160MHz       : in  sl;
      rst80MHz        : in  sl;
      rst40MHz        : in  sl;
      -- Streaming RD53 Trig Interface (clk160MHz domain)
      tluMaster       : out AxiStreamMasterType;
      tluSlave        : in  AxiStreamSlaveType;
      -- Trigger and hits Ports
      dPortHitP       : in  Slv4Array(3 downto 0);
      dPortHitN       : in  Slv4Array(3 downto 0);
      trigInL         : in  sl;
      hitInL          : in  sl;
      hitOut          : out sl;
      -- TLU Ports
      tluTrgClkP      : out sl;
      tluTrgClkN      : out sl;
      tluBsyP         : out sl;
      tluBsyN         : out sl;
      tluIntP         : in  sl;
      tluIntN         : in  sl;
      tluRstP         : in  sl;
      tluRstN         : in  sl);
end AtlasRd53Tlu;

architecture mapping of AtlasRd53Tlu is

   signal dPortHit  : Slv4Array(3 downto 0);
   signal trigIn    : sl;
   signal tluInt    : sl;
   signal tluRst    : sl;
   signal tluTrgClk : sl;
   signal tluBsy    : sl;
   signal hitIn     : sl;

begin

   ---------------------------
   -- Placeholder for TLU code
   ---------------------------
   tluMaster      <= AXI_STREAM_MASTER_INIT_C;
   axilReadSlave  <= AXI_LITE_READ_SLAVE_EMPTY_SLVERR_C;
   axilWriteSlave <= AXI_LITE_WRITE_SLAVE_EMPTY_SLVERR_C;
   trigIn         <= not(trigInL);
   hitIn          <= not(hitInL);
   hitOut         <= '0';
   tluTrgClk      <= '0';
   tluBsy         <= '0';

   GEN_FEB : for i in 3 downto 0 generate
      GEN_CH : for j in 3 downto 0 generate
         U_dPortHit : IBUFDS
            port map (
               I  => dPortHitP(i)(j),
               IB => dPortHitN(i)(j),
               O  => dPortHit(i)(j));
      end generate GEN_CH;
   end generate GEN_FEB;

   U_tluInt : IBUFDS
      port map (
         I  => tluIntP,
         IB => tluIntN,
         O  => tluInt);                 -- Place holder for future code

   U_tluRst : IBUFDS
      port map (
         I  => tluRstP,
         IB => tluRstN,
         O  => tluRst);                 -- Place holder for future code

   U_tluTrgClk : OBUFDS
      port map (
         I  => tluTrgClk,               -- Place holder for future code
         O  => tluTrgClkP,
         OB => tluTrgClkN);

   U_tluBsy : OBUFDS
      port map (
         I  => tluBsy,                  -- Place holder for future code
         O  => tluBsyP,
         OB => tluBsyN);

end mapping;
