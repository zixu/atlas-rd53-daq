-------------------------------------------------------------------------------
-- Description:
-- Core logic for BNL ASIC test FPGA.
-------------------------------------------------------------------------------
-- Copyright (c) 2008 by Ryan Herbst. All rights reserved.
-------------------------------------------------------------------------------
-- Modification history:
-- 07/21/2008: created.
-------------------------------------------------------------------------------

LIBRARY ieee;
use work.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity eudaqTrigger is 
   port (
     clk        : in std_logic;
     rst        : in std_logic;
     busyin     : in std_logic;
     enabled    : in std_logic;
     l1a        : in std_logic;
     trg        : in std_logic;
     done       : out std_logic;
     extbusy    : out std_logic;
     trgword    : out std_logic_vector(14 downto 0);
     trgclk     : out std_logic
     );
end eudaqTrigger;

architecture EUDAQTRIGGER of eudaqTrigger is

  signal clkcounter: std_logic_vector(7 downto 0);
  signal extbusyint: std_logic;
  signal trgwords:   std_logic_vector(14 downto 0);
  

begin

   trgword<=trgwords;
   extbusy<=extbusyint;

   process (rst,clk)
   begin
     if(rst='1')then
       clkcounter<="00000000";
       done<='0';
       trgclk<='0';
       trgwords<=x"000"&"000";
     elsif(rising_edge(clk))then
       if(clkcounter/="00000000")then
         clkcounter<=unsigned(clkcounter)-1;
         --if(clkcounter="10000000")then
         --  trgclk<='1';
         if(clkcounter(2 downto 0)="010")then -- every 4th tick
           trgwords(13 downto 0) <= trgwords(14 downto 1);
           trgwords(14)<=trg;
         elsif(clkcounter(2 downto 0)="000")then -- every 4th tick
           if(clkcounter(7)='0' )then
             trgclk<='1';
           end if;
         elsif(clkcounter(2 downto 0)="100")then
           trgclk<='0';
         elsif(clkcounter="00000001")then
           done<='1';
         end if;
       elsif(enabled='1' and l1a='1')then
         clkcounter<="11000000";
         extbusyint<='1';
       else
         done<='0';
         if(busyin='0' and extbusyint='1')then
           extbusyint<='0';
           trgclk<='0';
         elsif(extbusyint='0' and enabled='1' and busyin='1' )then --FIFO full
           trgclk<='1'; -- eudaq uses trgclk as a veto
         elsif(extbusyint='0' and busyin='0')then
           trgclk<='0';
         end if;
       end if;
     end if;
  end process;
       
end EUDAQTRIGGER;
