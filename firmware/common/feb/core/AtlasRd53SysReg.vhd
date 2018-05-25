-------------------------------------------------------------------------------
-- File       : AtlasRd53SysReg.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-05-07
-- Last update: 2018-05-25
-------------------------------------------------------------------------------
-- Description: System Registers
-------------------------------------------------------------------------------
-- This file is part of 'DUNE Development Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'DUNE Development Firmware', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AtlasRd53Pkg.all;

entity AtlasRd53SysReg is
   generic (
      TPD_G          : time := 1 ns;
      AXI_CLK_FREQ_G : real := 156.25E+6);  -- units of Hz
   port (
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- System Interface
      status          : in  AtlasRd53StatusType;
      config          : out AtlasRd53ConfigType);
end AtlasRd53SysReg;

architecture rtl of AtlasRd53SysReg is

   constant STATUS_SIZE_C : positive := 2;

   type RegType is record
      cntRst         : sl;
      rollOverEn     : slv(STATUS_SIZE_C-1 downto 0);
      config         : AtlasRD53ConfigType;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      cntRst         => '1',
      rollOverEn     => (others => '0'),
      config         => RD53_FEB_CONFIG_INIT_C,
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal statusOut : slv(STATUS_SIZE_C-1 downto 0);
   signal statusCnt : SlVectorArray(STATUS_SIZE_C-1 downto 0, 31 downto 0);

   signal refClk160MHzFreq : slv(31 downto 0);

   -- attribute dont_touch               : string;
   -- attribute dont_touch of r          : signal is "TRUE";

begin

   comb : process (axilReadMaster, axilRst, axilWriteMaster, r,
                   refClk160MHzFreq, statusCnt, statusOut) is
      variable v      : RegType;
      variable regCon : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Reset the strobes
      v.cntRst := '0';

      -- Determine the transaction type
      axiSlaveWaitTxn(regCon, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Map the read registers
      for i in STATUS_SIZE_C-1 downto 0 loop
         axiSlaveRegisterR(regCon, toSlv((4*i), 12), 0, muxSlVectorArray(statusCnt, i));
      end loop;
      axiSlaveRegisterR(regCon, x"400", 0, statusOut);
      axiSlaveRegisterR(regCon, x"404", 0, refClk160MHzFreq);

      -- Map the write registers
      axiSlaveRegister(regCon, x"800", 0, v.config.refSelect);
      axiSlaveRegister(regCon, x"804", 0, v.config.pllRst);
      axiSlaveRegister(regCon, x"808", 0, v.config.asicRst);
      axiSlaveRegister(regCon, x"80C", 0, v.config.timerConfig);
      axiSlaveRegister(regCon, x"810", 0, v.config.batchSize);
      axiSlaveRegister(regCon, x"814", 0, v.config.enAuxClk);
      axiSlaveRegister(regCon, x"818", 0, v.config.enLocalEmu);

      axiSlaveRegister(regCon, x"FF8", 0, v.rollOverEn);
      axiSlaveRegister(regCon, x"FFC", 0, v.cntRst);

      -- Closeout the transaction
      axiSlaveDefault(regCon, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      -- Synchronous Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axilWriteSlave <= r.axilWriteSlave;
      axilReadSlave  <= r.axilReadSlave;
      config         <= r.config;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_refClk160MHz : entity work.SyncClockFreq
      generic map (
         TPD_G          => TPD_G,
         REF_CLK_FREQ_G => AXI_CLK_FREQ_G,
         REFRESH_RATE_G => 1.0,         -- 1 Hz
         CNT_WIDTH_G    => 32)
      port map (
         freqOut => refClk160MHzFreq,
         clkIn   => status.refClk160MHz,
         locClk  => axilClk,
         refClk  => axilClk);

   U_SyncStatusVector : entity work.SyncStatusVector
      generic map (
         TPD_G          => TPD_G,
         COMMON_CLK_G   => true,
         OUT_POLARITY_G => '1',
         CNT_RST_EDGE_G => false,
         CNT_WIDTH_G    => 32,
         WIDTH_G        => STATUS_SIZE_C)
      port map (
         -- Input Status bit Signals (wrClk domain)
         statusIn(1)  => status.pllLocked,
         statusIn(0)  => status.iDelayCtrlRdy,
         -- Output Status bit Signals (rdClk domain)  
         statusOut    => statusOut,
         -- Status Bit Counters Signals (rdClk domain) 
         cntRstIn     => r.cntRst,
         rollOverEnIn => r.rollOverEn,
         cntOut       => statusCnt,
         -- Clocks and Reset Ports
         wrClk        => axilClk,
         rdClk        => axilClk);

end rtl;
