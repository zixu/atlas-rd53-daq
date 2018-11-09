-------------------------------------------------------------------------------
-- File       : AtlasRd53RxPhyMon.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Monitor the RX PHY status signals
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AtlasRd53Pkg.all;

entity AtlasRd53RxPhyMon is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Monitoring Interface
      autoReadReg     : in  Slv32Array(3 downto 0);
      dataDrop        : in  sl;
      timedOut        : in  sl;
      enable          : out slv(3 downto 0);
      invData         : out slv(3 downto 0);
      invCmd          : out sl;
      linkUp          : in  slv(3 downto 0);
      chBond          : in  sl;
      rxPhyXbar       : out Slv2Array(3 downto 0);
      debugStream     : out sl;
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end AtlasRd53RxPhyMon;

architecture rtl of AtlasRd53RxPhyMon is

   constant STATUS_SIZE_C : positive := 7;

   type RegType is record
      debugStream    : sl;
      rxPhyXbar      : Slv2Array(3 downto 0);
      invData        : slv(3 downto 0);
      invCmd         : sl;
      cntRst         : sl;
      rollOverEn     : slv(STATUS_SIZE_C-1 downto 0);
      enable         : slv(3 downto 0);
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      debugStream    => '0',
      rxPhyXbar      => (0 => "00", 1 => "01", 2 => "10", 3 => "11"),
      invData        => (others => '1'),  -- Invert by default
      invCmd         => '0',
      cntRst         => '1',
      rollOverEn     => (others => '0'),
      enable         => x"F",
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal chBondSync : sl;
   signal linkUpSync : slv(3 downto 0);
   signal statusOut  : slv(STATUS_SIZE_C-1 downto 0);
   signal statusCnt  : SlVectorArray(STATUS_SIZE_C-1 downto 0, 31 downto 0);

   -- attribute dont_touch               : string;
   -- attribute dont_touch of r          : signal is "TRUE";

begin

   comb : process (autoReadReg, axilReadMaster, axilRst, axilWriteMaster, r,
                   statusCnt, statusOut) is
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

      axiSlaveRegisterR(regCon, x"410", 0, autoReadReg(0));
      axiSlaveRegisterR(regCon, x"414", 0, autoReadReg(1));
      axiSlaveRegisterR(regCon, x"418", 0, autoReadReg(2));
      axiSlaveRegisterR(regCon, x"41C", 0, autoReadReg(3));

      axiSlaveRegister(regCon, x"800", 0, v.enable);
      axiSlaveRegister(regCon, x"804", 0, v.invData);
      axiSlaveRegister(regCon, x"808", 0, v.invCmd);

      axiSlaveRegister(regCon, x"80C", 0, v.rxPhyXbar(0));
      axiSlaveRegister(regCon, x"80C", 2, v.rxPhyXbar(1));
      axiSlaveRegister(regCon, x"80C", 4, v.rxPhyXbar(2));
      axiSlaveRegister(regCon, x"80C", 6, v.rxPhyXbar(3));

      axiSlaveRegister(regCon, x"810", 0, v.debugStream);

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
      enable         <= r.enable;
      invData        <= r.invData;
      invCmd         <= r.invCmd;
      rxPhyXbar      <= r.rxPhyXbar;
      debugStream    <= r.debugStream;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_chBond : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => axilClk,
         dataIn  => chBond,
         dataOut => chBondSync);

   U_linkUp : entity work.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 4)
      port map (
         clk     => axilClk,
         dataIn  => linkUp,
         dataOut => linkUpSync);

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
         statusIn(6)          => chBondSync,
         statusIn(5 downto 2) => linkUpSync,
         statusIn(1)          => timedOut,
         statusIn(0)          => dataDrop,
         -- Output Status bit Signals (rdClk domain)  
         statusOut            => statusOut,
         -- Status Bit Counters Signals (rdClk domain) 
         cntRstIn             => r.cntRst,
         rollOverEnIn         => r.rollOverEn,
         cntOut               => statusCnt,
         -- Clocks and Reset Ports
         wrClk                => axilClk,
         rdClk                => axilClk);

end rtl;
