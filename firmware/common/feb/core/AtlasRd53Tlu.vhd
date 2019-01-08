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

   signal extTrigComb: sl;
   --signal extTrigCombExtend64    : sl;
   signal extTrigCombExtend128    : sl;
   --signal extTrigCombExtendCnt: slv(5 downto 0);
   signal extTrigCombExtendCnt: slv(6 downto 0);



   signal tluInt    : sl;
   signal tluRst    : sl;
   signal tluTrgClk : sl;
   signal tluBsy    : sl;

   signal tluTrig    : sl;
   signal tluTrig_out: sl;
   signal tluTrig_reg0: sl;

   signal eudaqclkout : sl;
   signal eudaqtrgword   : slv(14 downto 0);
   signal eudaqtrgword_out   : slv(14 downto 0);
   signal eudaqdone      : slv(0 downto 0);
   signal eudaqenable      : sl:='1';


   signal hitIn     : sl;


      constant SYNC_C       : slv(31 downto 0) := b"1000_0001_0111_1110_1000_0001_0111_1110";
--   constant FORCE_SYNC_C : slv(4 downto 0)  := toSlv(31, 5);  -- It is recommended that at lest one sync frame be inserted at least every 32 frames.
    constant TRIG_ROM_C : Slv8Array(0 to 15) := (
      0  => b"0000_0000",  -- Undefined (index zero required for inferring ROM)
      1  => b"0010_1011",               -- 000T
      2  => b"0010_1101",               -- 00T0
      3  => b"0010_1110",               -- 00TT
      4  => b"0011_0011",               -- 0T00
      5  => b"0011_0101",               -- 0T0T
      6  => b"0011_0110",               -- 0TT0
      7  => b"0011_1001",               -- 0TTT
      8  => b"0011_1010",               -- T000
      9  => b"0011_1100",               -- T00T
      10 => b"0100_1011",               -- T0T0
      11 => b"0100_1101",               -- T0TT
      12 => b"0100_1110",               -- TT00
      13 => b"0101_0011",               -- TT0T
      14 => b"0101_0101",               -- TTT0
      15 => b"0101_0110");              -- TTTT

   constant DATA_ROM_C : Slv8Array(0 to 31) := (
      0  => b"0110_1010",
      1  => b"0110_1100",
      2  => b"0111_0001",
      3  => b"0111_0010",
      4  => b"0111_0100",
      5  => b"1000_1011",
      6  => b"1000_1101",
      7  => b"1000_1110",
      8  => b"1001_0011",
      9  => b"1001_0101",
      10 => b"1001_0110",
      11 => b"1001_1001",
      12 => b"1001_1010",
      13 => b"1001_1100",
      14 => b"1010_0011",
      15 => b"1010_0101",
      16 => b"1010_0110",
      17 => b"1010_1001",
      18 => b"1010_1010",
      19 => b"1010_1100",
      20 => b"1011_0001",
      21 => b"1011_0010",
      22 => b"1011_0100",
      23 => b"1100_0011",
      24 => b"1100_0101",
      25 => b"1100_0110",
      26 => b"1100_1001",
      27 => b"1100_1010",
      28 => b"1100_1100",
      29 => b"1101_0001",
      30 => b"1101_0010",
      31 => b"1101_0100");

   type StateType is (
      INIT_S,
      RDY_S);

   type RegType is record
      timer : slv(4 downto 0);
	  triggerTag1: slv(4 downto 0);
	  triggerTag2: slv(4 downto 0);
      init     : slv(7 downto 0);
      trigDet  : slv(7 downto 0);
      trigFrame  : sl; --need to adding "ECR frame" just after trigFrame
      trigCnt  : slv(31 downto 0);
      axilReadSlave   : AxiLiteReadSlaveType;
      axilWriteSlave  : AxiLiteWriteSlaveType;	  
      tluMaster: AxiStreamMasterType;
      state    : StateType;
   end record RegType;
   constant REG_INIT_C : RegType := (
      timer => (others => '0'),
	  triggerTag1 => (others => '0'),
	  triggerTag2 => (others => '0'),
      init     => x"FF",
      trigDet  => (others => '0'),
      trigFrame => '0',
      --trigCnt  => (others => '0'),
      trigCnt  => x"00110011",--system test
      axilReadSlave   => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave  => AXI_LITE_WRITE_SLAVE_INIT_C,	  
      tluMaster=> AXI_STREAM_MASTER_INIT_C,
      state    => INIT_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal vio_probe_in0: slv(31 downto 0):= (others => '0');
   signal vio_probe_in1: slv(31 downto 0):= (others => '0');
   signal vio_probe_out0: slv(0 downto 0):= (others => '0');
   signal vio_probe_out0_reg0: sl:='0';
   signal vio_trig: sl:='0';
   signal vio_trigTag1: slv(4 downto 0):= (others => '0');
   signal vio_trigTag2: slv(4 downto 0):= (others => '0');

--   component vio_extTrig is
--	port (
--				 clk: in sl;
--				 probe_in0 : in slv(31 downto 0);
--				 probe_in1 : in slv(31 downto 0);
--				 probe_in2 : in slv(0 downto 0);
--				 probe_in3 : in slv(14 downto 0);
--				 probe_out0: out slv( 0 downto 0);
--				 probe_out1: out slv( 4 downto 0); 
--				 probe_out2: out slv( 4 downto 0)); 
--   end component;

begin



	hitIn          <= not(hitInL);
	--hitOut         <= hitIn;
	hitOut         <= tluInt;

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


	comb : process (axilReadMaster, axilWriteMaster, r, rst160MHz, extTrigCombExtend128, eudaqdone, eudaqtrgword, tluBsy, tluSlave) is
		variable v        : RegType;
        variable axilEp : AxiLiteEndPointType;
		variable serPhase : natural;
	begin
		-- Latch the current value
		v := r;

		-- Determine the transaction type
		axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

		--axiSlaveRegister(axilEp, x"00", 0, v.trigger);
		axiSlaveRegister(axilEp, x"01", 0, v.triggerTag1);
		axiSlaveRegister(axilEp, x"02", 0, v.triggerTag2);
		axiSlaveRegisterR(axilEp, x"04", 0, eudaqtrgword);
        axiSlaveRegisterR(axilEp, x"06", 0, tluBsy);
        axiSlaveRegisterR(axilEp, x"08", 0, eudaqdone);
		axiSlaveRegisterR(axilEp, x"10", 0, r.trigCnt);

		-- Closeout the transaction
		axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);


		-- Increment the counter
		v.timer := r.timer + 1;


		-- AXI Stream flow control
		if (tluSlave.tReady = '1') then
			v.tluMaster.tValid := '0';
			v.tluMaster.tLast  := '0';
		end if;	  


		-- Calculate the serialization phase
		serPhase := conv_integer(r.timer(4 downto 2));

		-- Check for trigger
		if (extTrigCombExtend128 = '1') then
			-- Update the trigger detection mask
			v.trigDet(serPhase) := '1';
			v.trigCnt := r.trigCnt+1;
		end if;



		-- State Machine
		case r.state is
			----------------------------------------------------------------------
			when INIT_S =>
				-- Decrement the counter
				v.init := r.init -1;
				-- Check initialization completed
				if (r.init = 0) then
					-- Next state
					v.state := RDY_S;
				end if;
			----------------------------------------------------------------------
			when RDY_S =>
				if (r.timer = x"1F") then
					-- Check for triggers
					if (v.trigDet /= 0) then
						v.trigFrame:='1';

						if (v.tluMaster.tValid = '0') then
							v.tluMaster.tValid := '1';
							-- Going into the chip, the command bits go in first and the tag goes in second.
							-- tData(31 downto 16) be sent at first, then, tData(15 downto 0)

							if (v.trigDet(3 downto 0) /= 0) then
							    v.tluMaster.tData(31 downto 24) := TRIG_ROM_C(conv_integer(v.trigDet(3 downto 0)));
								--trigTag
							    --v.tluMaster.tData(23 downto 16) := DATA_ROM_C(conv_integer(v.trigDet(3 downto 0)));
							    v.tluMaster.tData(23 downto 16) := DATA_ROM_C(conv_integer(eudaqtrgword(4 downto 0)));
							    --v.tluMaster.tData(23 downto 16) := DATA_ROM_C(22);
							else
							    v.tluMaster.tData(31 downto 16) := x"6969";
							end if;

							if (v.trigDet(7 downto 4) /= 0) then
							    v.tluMaster.tData(15 downto  8) := TRIG_ROM_C(conv_integer(v.trigDet(7 downto 4)));
								--trigTag
							    --v.tluMaster.tData( 7 downto  0) := DATA_ROM_C(conv_integer(v.trigDet(7 downto 4)));
							    v.tluMaster.tData( 7 downto  0) := DATA_ROM_C(conv_integer(eudaqtrgword(4 downto 0)));
							    --v.tluMaster.tData( 7 downto  0) := DATA_ROM_C(22);
							else
							    v.tluMaster.tData(15 downto  0) := x"6969";
							end if;
						end if;
					end if;
            		-- Reset the masks
            		v.trigDet := x"00";
				end if;
		----------------------------------------------------------------------
		end case;

		-- Check if need to terminate frame
		if (v.tluMaster.tValid = '1') then
			-- Terminate the frame
			v.tluMaster.tLast := '1';
		end if;

		axilWriteSlave <= r.axilWriteSlave;
		axilReadSlave  <= r.axilReadSlave;
		tluMaster      <= r.tluMaster;

		-- Reset
		if (rst160MHz = '1') then
			v := REG_INIT_C;
		end if;

		-- Register the variable for next clock cycle
		rin <= v;


	end process comb;




	vio_probe_in1<=r.trigCnt;

--	--system debug
--	u_vio: vio_extTrig
--	port map (
--				 clk=> clk160MHz,
--				 probe_in0=>vio_probe_in0,
--				 probe_in1=>vio_probe_in1,
--				 probe_in2=>eudaqdone,
--				 probe_in3=>eudaqtrgword,
--				 probe_out0=> vio_probe_out0,
--				 probe_out1=> vio_trigTag1,
--				 probe_out2=> vio_trigTag2);






	--EUDAQ TLU trigger

   eudettrg: entity work.eudaqTrigger
   port map(
			   clk => clk40MHz,
			   rst => rst40MHz,
			   busyin => '0',
			   enabled =>eudaqenable,
			   l1a  => tluInt,
			   trg  => tluInt,
			   done => eudaqdone(0),
			   extbusy => tluBsy,
			   trgword => eudaqtrgword_out,
			   trgclk => eudaqclkout );

   tluTrgClk<= eudaqclkout or not eudaqenable;	
   tluTrig_out <= tluInt and not tluBsy;




	seq : process (clk160MHz) is
	begin
		if rising_edge(clk160MHz) then
			r <= rin after TPD_G;


--			if(rin.tluMaster.tValid='1')then
--				vio_probe_in0<=rin.tluMaster.tData(31 downto 0); 
--			end if;
			--trig from VIO
			if(vio_trig='1') then
				vio_trig<='0';
			elsif(vio_probe_out0(0)='1' and vio_probe_out0_reg0='0') then
				vio_trig<='1';
				vio_probe_out0_reg0<='1';
			elsif(vio_probe_out0(0)='0') then
				vio_probe_out0_reg0<='0';
			end if;


			--trig from TLU
			if(tluTrig='1') then
				tluTrig<='0';
			elsif( tluTrig_out='1' and tluTrig_reg0='0') then
				tluTrig<='1';
				tluTrig_reg0<='1';
			elsif( tluTrig_out='0') then
				tluTrig_reg0<='0';
			end if;

			if(extTrigCombExtendCnt="0000000") then
				--extTrigComb         <= not(trigInL) or vio_trig or tluTrig;
				extTrigComb         <= tluTrig;--only TLU trigger
				if(extTrigComb='1') then
					--extTrigCombExtendCnt<="1111100"; --so, only extend by 128-3, which will make sure that exactly 32 Trig sending out
					extTrigCombExtendCnt<="0111100"; --so, only extend by 64-3, which will make sure that exactly 16 Trig sending out
					extTrigCombExtend128<='1';
				else
					extTrigCombExtend128<='0';
				end if;

			else 
				extTrigCombExtendCnt<= extTrigCombExtendCnt-1;
			end if; 


			if(eudaqdone(0)='1') then 
				eudaqtrgword<=eudaqtrgword_out;
			end if;


		end if;
	end process seq;
	vio_probe_in0<=r.tluMaster.tData(31 downto 0);





end mapping;
