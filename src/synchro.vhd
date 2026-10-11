--========================================================
--  Project   : AYME0100
--  Outline   : 教育用8ビットマイコン(kue-chip2)FPGA
----------------------------------------------------------
--  File Name : synchro.vhd
--  Function  : 非同期入力信号の同期化
--  Note      : 
--              
----------------------------------------------------------
--  Date      : Rev.0.9 2024.04.24 Wataru AOYAMA(ANT TECH)
--  Update    :
--========================================================
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.all;

-- 入出力の宣言
entity SYNCHRO is
port (
	CLK				: in std_logic;
	RESET				: in std_logic;
	IBUF_STB			: in std_logic;
	REQ_STB_IN		: in std_logic;
	IBUF				: in std_logic_vector(7 downto 0);
	SW_IN				: in std_logic_vector(18 downto 0);
	DATA_SW			: out std_logic_vector(7 downto 0);
	SEL_SW			: out std_logic_vector(3 downto 0);
	EXE				: out std_logic_vector(2 downto 0);
	INC				: out std_logic;
	DEC				: out std_logic;
	SET				: out std_logic;
	DEMO				: out std_logic;
	SEL_MAR			: out std_logic;
	ADDR8_SW			: out std_logic;
	SW_DATA_WE		: out std_logic;
	IBUF_STB_S		: out std_logic;
	REQ_STB_IN_S	: out std_logic;
	IBUF_S			: out std_logic_vector(7 downto 0)
	);
end SYNCHRO;

-- 回路の記述
architecture rtl of SYNCHRO is

-- 内部信号の定義
signal DFF1 : std_logic_vector(28 downto 0);
signal DFF2 : std_logic_vector(28 downto 0);
signal DELAY : std_logic_vector(5 downto 0);
signal EXE_SW : std_logic_vector(2 downto 0);
signal INC_SW : std_logic;
signal DEC_SW : std_logic;
signal SET_SW : std_logic;
signal DEMO_SW : std_logic;
signal SEL : std_logic_vector(3 downto 0);

begin
	process(CLK, RESET) begin
		if (RESET = '1') then
			DFF1 <= "00000000111111111000000000000";
			DFF2 <= "00000000111111111000000000000";
		elsif (CLK'event and CLK='1') then
			DFF1(28 downto 21) <= IBUF;
			DFF1(20) <= IBUF_STB;
			DFF1(19) <= REQ_STB_IN;
			DFF1(18 downto 0) <= SW_IN;
			DFF2(28 downto 0) <= DFF1(28 downto 0);
		end if;
	end process;
		
	DATA_SW <= DFF2(7 downto 0);
	SEL <= DFF2(11 downto 8);

	EXE_SW <= DFF2(12) & DFF2(13) & DFF2(14);
	
	INC_SW <= DFF2(15);
	DEC_SW <= DFF2(16);
	SET_SW <= DFF2(17);

	DEMO_SW <= not DFF2(18);

	process(CLK, RESET) begin
		if (RESET ='1') then
			DELAY <= "111111";
		elsif (CLK'event and CLK='1') then
			DELAY(0) <= INC_SW;
			DELAY(1) <= DEC_SW;
			DELAY(2) <= SET_SW;
			DELAY(5 downto 3) <= EXE_SW(2 downto 0);
		end if;
	end process;
	
	INC <= not INC_SW and DELAY(0);
	DEC <= not DEC_SW and DELAY(1);
	SET <= not SET_SW and DELAY(2);
	EXE <= not EXE_SW and DELAY(5 downto 3);
	DEMO <= DEMO_SW;
	SEL_MAR <= '1' when SEL = "1000" else '0';
	ADDR8_SW <= '1' when SEL = "0001" else '0';
	SEL_SW <= SEL;
	SW_DATA_WE <= '1' when (SET_SW = '0' and SEL < "0010") else '0';
	IBUF_STB_S <= DFF2(20);
	REQ_STB_IN_S <= DFF2(19);
	IBUF_S <= DFF2(28 downto 21);
	
end rtl; 
                   
     
      
