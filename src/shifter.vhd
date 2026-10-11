--========================================================
--  Project   : AYME0100
--  Outline   : 教育用8ビットマイコン(kue-chip2)FPGA
----------------------------------------------------------
--  File Name : shifter.vhd
--  Function  : シフト・ローテート命令の実行
--  Note      : 
--              
----------------------------------------------------------
--  Date      : Rev.0.9 2024.04.24 Wataru AOYAMA(ANT TECH)
--  Update    :
--========================================================
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use WORK.all;

-- 入出力の宣言
entity SHIFTER is
port(
	SYSCLK	: in std_logic;
	RESET		: in std_logic;
	SHFT_EN	: in std_logic;
	ROT_EN	: in std_logic;
	CFIN		: in std_logic;
	DATA_IN	: in std_logic_vector(7 downto 0);
	SR_MODE	: in std_logic_vector(1 downto 0);
	DATA_OUT	: out std_logic_vector(7 downto 0);
	CF_SHFT	: out std_logic;
	VF_SHFT	: out std_logic;
	NF_SHFT	: out std_logic;
	ZF_SHFT	: out std_logic
);
end SHIFTER;

-- 回路の記述
architecture rtl of SHIFTER is

-- 内部信号の定義
signal SHIFT	: std_logic_vector(8 downto 0);
signal A 		: std_logic_vector(8 downto 0);
signal DFF 		: std_logic_vector(1 downto 0);
signal EN_SHFT : std_logic;
signal EN_ROT 	: std_logic;
signal CF 		: std_logic;
signal OV 		: std_logic;
signal NF 		: std_logic;
signal ZF 		: std_logic;

begin
	A <= CFIN & DATA_IN;
	
	process(SYSCLK, RESET) begin
		if (RESET = '1') then
			SHIFT <= "000000000";
			CF <= '0';
			OV <= '0';
		elsif (SYSCLK'event and SYSCLK='1') then					-- SRA
			if (EN_SHFT = '1') then
				if( SR_MODE = "00") then
					SHIFT(7 downto 0) <= A(7) & A(7 downto 1);
					CF <= A(0);
					OV <= '0';
				elsif (SR_MODE = "01") then							-- SLA
					SHIFT(7 downto 0) <= A(6 downto 0) & '0';
					CF <= A(7);
					if (A(7) /= A(6)) then
						OV <= '1';
					else
						OV <= '0';
					end if;
				elsif (SR_MODE = "10") then							-- SRL
					SHIFT(7 downto 0) <= '0' & A(7 downto 1);
					CF <= A(0);
					OV <= '0';
				elsif (SR_MODE = "11") then							-- SLL
					SHIFT(7 downto 0) <= A(6 downto 0) & '0';
					CF <= A(7);
					OV <= '0';
				end if;
			elsif (EN_ROT = '1') then
				if (SR_MODE = "00") then								-- RRA
					SHIFT <= A(0) & A(8 downto 1);
					CF <= A(0);
					OV <= '0';
				elsif (SR_MODE = "01") then							-- RLA
					SHIFT <= A(7 downto 0) & A(8);
					CF <= A(7);
					if (A(7) /= A(6)) then
						OV <= '1';
					else
						OV <= '0';
					end if;
				elsif (SR_MODE = "10") then							-- RRL
					SHIFT(7 downto 0) <= A(0) & A(7 downto 1);
					CF <= A(0);
					OV <= '0';
				elsif (SR_MODE = "11") then							-- RLL
					SHIFT(7 downto 0) <= A(6 downto 0) & A(7);
					CF <= A(7);
					OV <= '0';
				end if;
			end if;
		end if;
	end process;
	
	process(SYSCLK, RESET) begin
		if (RESET = '1') then
			DFF <= "00";
		elsif (SYSCLK'event and SYSCLK='1') then
			DFF(1) <= SHFT_EN;
			DFF(0) <= ROT_EN;
		end if;
	end process;
	
	process(SYSCLK, RESET) begin
		if (RESET = '1') then
			NF <= '0';
			ZF <= '0';
		elsif (SYSCLK'event and SYSCLK='1') then
			if (SHIFT(7) = '1') then
				NF <= '1';
				ZF <= '0';
			elsif (SHIFT(7 downto 0) = "00000000") then
				NF <= '0';
				ZF <= '1';
			else
				NF <= '0';
				ZF <= '0';
			end if;
		end if;
	end process;
	
	EN_SHFT <= not DFF(1) and SHFT_EN;
	EN_ROT <= not DFF(0) and ROT_EN;
	DATA_OUT <= SHIFT(7 downto 0);
	
	CF_SHFT <= CF;
	VF_SHFT <= OV;
	NF_SHFT <= NF;
	ZF_SHFT <= ZF;
	
end rtl;