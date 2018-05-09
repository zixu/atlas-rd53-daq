-------------------------------------------------------------------------------
-- File       : AtlasRd53DportPacketizer.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-18
-- Last update: 2018-05-05
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
use work.AxiStreamPkg.all;
use work.Pgp3Pkg.all;

library unisim;
use unisim.vcomponents.all;

entity AtlasRd53DportPacketizer is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Aligned Inbound Interface
      clk160MHz     : in  sl;
      rst160MHz     : in  sl;
      clk40MHz      : in  sl;
      rst40MHz      : in  sl;
      data          : in  Slv64Array(3 downto 0);
      sync          : in  Slv2Array(3 downto 0);
      valid         : in  sl;
      channelBonded : in  sl;
      -- Monitoring   
      overflow      : out sl;
      -- AXI Stream Interface
      mAxisClk      : in  sl;
      mAxisRst      : in  sl;
      mAxisMaster   : out AxiStreamMasterType;
      mAxisSlave    : in  AxiStreamSlaveType);
end AtlasRd53DportPacketizer;

architecture rtl of AtlasRd53DportPacketizer is

   type RegType is record
      fifoRd   : sl;
      cnt      : natural range 0 to 3;
      txMaster : AxiStreamMasterType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      fifoRd   => '0',
      cnt      => 0,
      txMaster => AXI_STREAM_MASTER_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal txCtrl : AxiStreamCtrlType;

   signal fifoWr    : sl;
   signal fifoRd    : sl;
   signal fifoValid : sl;
   signal fifoRst   : sl;
   signal fifoDin   : slv(255 downto 0);
   signal fifoDout  : slv(255 downto 0);

   signal dataSync : Slv64Array(3 downto 0);

   -- attribute dont_touch           : string;
   -- attribute dont_touch of r      : signal is "TRUE";
   -- attribute dont_touch of txCtrl : signal is "TRUE";

begin


   fifoWr  <= '1';                      -- Placeholder for future code
   fifoRst <= rst160MHz or not(channelBonded);

   GEN_VEC : for i in 3 downto 0 generate
      fifoDin((i*64)+63 downto (i*64)) <= data(i);
      dataSync(i)                      <= fifoDout((i*64)+63 downto (i*64));
   end generate GEN_VEC;

   U_Fifo : entity work.FifoAsync
      generic map (
         TPD_G        => 1 ns,
         BRAM_EN_G    => false,         -- Use LUTRAM
         FWFT_EN_G    => true,
         DATA_WIDTH_G => 256,
         ADDR_WIDTH_G => 4)
      port map (
         -- Asynchronous Reset
         rst    => fifoRst,
         -- Write Ports (wr_clk domain)
         wr_clk => clk40MHz,
         wr_en  => fifoWr,
         din    => fifoDin,
         -- Read Ports (rd_clk domain)
         rd_clk => clk160MHz,
         rd_en  => fifoRd,
         dout   => fifoDout,
         valid  => fifoValid);

   comb : process (dataSync, fifoValid, r, rst160MHz, txCtrl) is
      variable v    : RegType;
      variable i    : natural;
      variable data : slv(63 downto 0);
   begin
      -- Latch the current value
      v := r;

      -- Reset the flags
      v.fifoRd          := '0';
      v.txMaster.tValid := '0';
      v.txMaster.tLast  := '0';
      v.txMaster.tUser  := (others => '0');

      ---------------------------------------------------------------
      ---------------------------------------------------------------
      ---------------------------------------------------------------
      -- This "process" is a placeholder for future code.We only 
      -- wrote enough firmware to check the min. resource requirement
      ---------------------------------------------------------------      
      ---------------------------------------------------------------      
      ---------------------------------------------------------------      

      -- Check for data to move
      if (fifoValid = '1') then

         -- Increment the counter
         v.cnt := r.cnt + 1;

         -- Move the data
         v.txMaster.tValid             := '1';
         v.txMaster.tData(63 downto 0) := dataSync(r.cnt);

         -- Check the counter
         if (r.cnt = 3) then
            -- Reset the counter
            v.cnt    := 0;
            -- Acknowledge the read
            v.fifoRd := '1';
         end if;

      end if;

      -- Synchronous Reset
      if (rst160MHz = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      fifoRd   <= v.fifoRd;
      overflow <= txCtrl.overflow;

   end process comb;

   seq : process (clk160MHz) is
   begin
      if rising_edge(clk160MHz) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   TX_FIFO : entity work.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 1,
         PIPE_STAGES_G       => 1,
         SLAVE_READY_EN_G    => false,  -- No flow control
         VALID_THOLD_G       => 1,
         -- FIFO configurations
         BRAM_EN_G           => true,
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 9,
         FIFO_PAUSE_THRESH_G => 500,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => PGP3_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => PGP3_AXIS_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => clk160MHz,
         sAxisRst    => rst160MHz,
         sAxisMaster => r.txMaster,
         sAxisCtrl   => txCtrl,
         -- Master Port
         mAxisClk    => mAxisClk,
         mAxisRst    => mAxisRst,
         mAxisMaster => mAxisMaster,
         mAxisSlave  => mAxisSlave);

end rtl;
