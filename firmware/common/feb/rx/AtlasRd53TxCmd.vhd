-------------------------------------------------------------------------------
-- File       : AtlasRd53TxCmd.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Module to generate CMD serial stream to RD53 ASIC
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

entity AtlasRd53TxCmd is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Clock and Reset
      clk160MHz : in  sl;
      rst160MHz : in  sl;
      -- Streaming RD53 Config Interface (clk160MHz domain)
      cmdMaster : in  AxiStreamMasterType;
      cmdSlave  : out AxiStreamSlaveType;
      -- Serial Output Interface
      cmdOut    : out sl);
end AtlasRd53TxCmd;

architecture rtl of AtlasRd53TxCmd is

   constant SYNC_C : slv(15 downto 0) := b"1000_0001_0111_1110";

   type StateType is (
      INIT_S,
      LISTEN_S);

   type RegType is record
      cmd      : sl;
      shiftReg : slv(31 downto 0);
      shiftCnt : slv(4 downto 0);
      init     : slv(7 downto 0);
      cmdSlave : AxiStreamSlaveType;
      state    : StateType;
   end record RegType;
   constant REG_INIT_C : RegType := (
      cmd      => '0',
      shiftReg => (SYNC_C & SYNC_C),
      shiftCnt => (others => '0'),
      init     => x"FF",
      cmdSlave => AXI_STREAM_SLAVE_INIT_C,
      state    => INIT_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   comb : process (cmdMaster, r, rst160MHz) is
      variable v : RegType;
   begin
      -- Latch the current value
      v := r;

      -- Reset the strobes
      v.cmdSlave.tReady := '0';

      -- Update the shift register
      v.shiftReg := r.shiftReg(30 downto 0) & '0';

      -- Increment the counter
      v.shiftCnt := r.shiftCnt + 1;

      -- Check if last bit in shift registers sent
      if (r.shiftCnt = "11111") then

         -- Default shift reg update value
         v.shiftReg := (SYNC_C & SYNC_C);

         -- State Machine
         case r.state is
            ----------------------------------------------------------------------
            when INIT_S =>
               -- Decrement the counter
               v.init := r.init -1;
               -- Check initialization completed
               if (r.init = 0) then
                  -- Next state
                  v.state := LISTEN_S;
               end if;
            ----------------------------------------------------------------------
            when LISTEN_S =>
               -- Check for streaming data
               if (cmdMaster.tValid = '1') then
                  -- Accept the data
                  v.cmdSlave.tReady := '1';
                  -- Move the data (only 32-bit data from the software)
                  v.shiftReg        := cmdMaster.tData(31 downto 0);
               end if;
         ----------------------------------------------------------------------
         end case;

      end if;

      -- Outputs
      cmdSlave <= v.cmdSlave;
      cmdOut   <= r.shiftReg(31);

      -- Reset
      if (rst160MHz = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (clk160MHz) is
   begin
      if rising_edge(clk160MHz) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
