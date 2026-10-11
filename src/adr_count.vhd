--========================================================
--  Project   : AYME0100
--  Outline   : 教育用8ビットマイコン(kue-chip2)FPGA
----------------------------------------------------------
--  File Name : adr_count.vhd
--  Function  : 
--  Note      : 
--              
----------------------------------------------------------
--  Date      : Rev.0.9 2024.04.24 Wataru AOYAMA(ANT TECH)
--  Update    :
--========================================================
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use WORK.all;

-- 入出力の宣言
entity ADR_COUNT is
port(
	SYSCLK	: in std_logic;
	RESET		: in std_logic;
	MAR_EN	: in std_logic;--_vector(2 downto 0);
	SEL		: in std_logic;
	MEM_PC	: in std_logic;
	D_IN		: in std_logic_vector(7 downto 0);
	PC			: in std_logic_vector(7 downto 0);
	IX_REG	: in std_logic_vector(7 downto 0);
	ADIX		: in std_logic;
	SET		: in std_logic;
	INC		: in std_logic;
	DEC		: in std_logic;
	SEL_MAR	: in std_logic;
	DATA_SW	: in std_logic_vector(7 downto 0);
	ADR		: out std_logic_vector(7 downto 0)
);
end ADR_COUNT;

-- 回路の記述
architecture rtl of ADR_COUNT is

-- 内部信号の定義
signal MUXO 		: std_logic_vector(7 downto 0);
signal ADR_LATCH 	: std_logic;
signal SHIFT 		: std_logic_vector(3 downto 0);
signal SEL_MEM 	: std_logic;
signal ADR_COUNT 	: std_logic_vector(7 downto 0);

begin
	process(PC, D_IN, IX_REG, ADIX, SEL_MEM, SEL_MAR, DATA_SW, SET) begin
		if (SEL_MAR = '1' and SET = '1') then
			MUXO <= DATA_SW;
		elsif (SEL_MEM = '0') then
			MUXO <= PC;
		else
			if (ADIX = '1') then
				MUXO <= D_IN + IX_REG;
			else
				MUXO <= D_IN;
			end if;
		end if;
	end process;

	process(SYSCLK, RESET) begin
		if (RESET = '1') then
			ADR_COUNT <= "00000000";
		elsif (SYSCLK'event and SYSCLK='1') then
			if (ADR_LATCH = '1') then
				ADR_COUNT <= MUXO;
			elsif (SET = '1' and SEL_MAR = '1') then
				ADR_COUNT <= MUXO;
			elsif (INC = '1') then
				ADR_COUNT <= ADR_COUNT + 1;
			elsif (DEC = '1') then
				ADR_COUNT <= ADR_COUNT - 1;
			end if;
		end if;
	end process;
	
	ADR_LATCH <= MAR_EN;--MAR_EN(2) or MAR_EN(1) or MAR_EN(0);
	ADR <= ADR_COUNT;
	
	process(SYSCLK, RESET) begin
		if (RESET = '1') then
			SHIFT <= "0000";
		elsif (SYSCLK'event and SYSCLK='1') then
			SHIFT <= SHIFT(2 downto 0) & MEM_PC;
		end if;
	end process;
	
	SEL_MEM <= SHIFT(2);-- and MEM_PC;
	
end rtl;