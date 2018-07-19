-------------------------------------------------------------------------------
-- File       : AtlasRd53RdReg.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-05-24
-- Last update: 2018-07-18
-------------------------------------------------------------------------------
-- Description: Demux the auto-reg, RdReg and data paths 
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
use work.SsiPkg.all;
use work.AtlasRd53Pkg.all;

entity AtlasRd53RdReg is
   generic (
      TPD_G : time := 1 ns);
   port (
      clk160MHz   : in  sl;
      rst160MHz   : in  sl;
      -- Data Tap Interface
      rxStatus    : in  Slv8Array(3 downto 0);
      rxValid     : in  slv(3 downto 0);
      rxHeader    : in  Slv2Array(3 downto 0);
      rxData      : in  Slv64Array(3 downto 0);
      -- AutoReg and Readback Interface
      autoReadReg : out Slv32Array(3 downto 0);
      rdReg       : out AxiStreamMasterType);
end AtlasRd53RdReg;

architecture rtl of AtlasRd53RdReg is

   type RegType is record
      autoDet     : sl;
      cmdDrop     : sl;
      autoReadReg : Slv32Array(3 downto 0);
      rdReg       : AxiStreamMasterType;
   end record RegType;
   constant REG_INIT_C : RegType := (
      autoDet     => '0',
      cmdDrop     => '0',
      autoReadReg => (others => (others => '0')),
      rdReg       => AXI_STREAM_MASTER_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal txSlave : AxiStreamSlaveType;

begin

   comb : process (r, rst160MHz, rxData, rxHeader, rxStatus, rxValid) is
      variable v      : RegType;
      variable i      : natural;
      variable opCode : Slv8Array(3 downto 0);

      procedure fwdRdReg is
      begin
         -- Move the data
         v.rdReg.tValid             := '1';
         v.rdReg.tData(63 downto 0) := rxData(0);  -- only lane[0] has RdReg command read back
         -- Set the End of Frame (EOF) flag
         v.rdReg.tLast              := '1';
         -- Set Start of Frame (SOF) flag
         ssiSetUserSof(PGP3_AXIS_CONFIG_C, v.rdReg, '1');
      end procedure fwdRdReg;

   begin
      -- Latch the current value
      v := r;

      -- Reset the flags
      v.autoDet      := '0';
      v.rdReg.tValid := '0';

      -- Update the metadata field
      for i in 3 downto 0 loop
         opCode(i) := rxData(i)(63 downto 56);
      end loop;

      -- Loop through the lanes
      for i in 3 downto 0 loop
         -- Check for valid and not Aurora data 
         if (rxValid(i) = '1') and (rxStatus(i)(1 downto 0) = "11") and (rxHeader(i) = "10") then
            -- Both register fields are of type AutoRead
            if (opCode(i) = x"B4") then
               v.autoDet                      := '1';
               v.autoReadReg(i)(15 downto 0)  := rxData(i)(15 downto 0);
               v.autoReadReg(i)(31 downto 16) := rxData(i)(41 downto 26);
            -- First frame is AutoRead, second is from a read register command
            elsif (opCode(i) = x"55") then
               v.autoDet                     := '1';
               v.autoReadReg(i)(15 downto 0) := rxData(i)(15 downto 0);
               -- Check if lane[0] (see note below)
               if (i = 0) then
                  fwdRdReg;
               end if;
            -- First is from a read register command, second frame is AutoRead
            elsif (opCode(i) = x"99") then
               v.autoDet                      := '1';
               v.autoReadReg(i)(31 downto 16) := rxData(i)(41 downto 26);
               -- Check if lane[0] (see note below)
               if (i = 0) then
                  fwdRdReg;
               end if;
            -- Both register fields are from read register commands
            elsif (opCode(i) = x"D2") then
               -- Check if lane[0] (see note below)
               if (i = 0) then
                  fwdRdReg;
               end if;
            end if;
         end if;
      ------------------------------------------------------
      --                 Note                             --
      ------------------------------------------------------
      -- "Lanes 1 to 3 are unaffected by the RdReg command 
      -- and only output their assigned auto-fill registers"
      -- So we only check lane[0] for RdReg command read back
      ------------------------------------------------------
      end loop;

      -- Reset
      if (rst160MHz = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      autoReadReg <= r.autoReadReg;
      rdReg       <= r.rdReg;

   end process comb;

   seq : process (clk160MHz) is
   begin
      if rising_edge(clk160MHz) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
