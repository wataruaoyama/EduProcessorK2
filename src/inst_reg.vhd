--========================================================
--  Project   : AYME0100
--  Outline   : 教育用8ビットマイコン(kue-chip2)FPGA
----------------------------------------------------------
--  File Name : inst_reg.vhd
--  Function  : 命令レジスタ
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
entity INST_REG is
port(
	SYSCLK	: in std_logic;
	RESET		: in std_logic;
	EN			: in std_logic;
	D_IN		: in std_logic_vector(7 downto 0);
	D_OUT		: out std_logic_vector(7 downto 0)
);
end INST_REG;

-- 回路の記述
architecture rtl of INST_REG is

begin
	process(SYSCLK, RESET) begin
		if (RESET = '1') then
			D_OUT <= "00000000";
		elsif (SYSCLK'event and SYSCLK='1') then
			if (EN = '1') then
				D_OUT <= D_IN;
			end if;
		end if;
	end process;
	
end rtl;