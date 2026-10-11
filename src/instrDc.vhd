--========================================================
--  Project   : AYME0100
--  Outline   : 教育用8ビットマイコン(kue-chip2)FPGA
----------------------------------------------------------
--  File Name : instr_DC.vhd
--  Function  : 命令デコーダー
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
entity instrDC is
port(
	D			: in std_logic_vector(7 downto 0);
	OP_CODE	: out std_logic_vector(3 downto 0);
	A			: out std_logic;
	B			: out std_logic;
	ADR_MODE	: out std_logic_vector(2 downto 0);
	SR_MODE	: out std_logic_vector(1 downto 0);
	CC			: out std_logic_vector(3 downto 0);
	ADI		: out std_logic
);
end instrDC;

-- 回路の記述
architecture rtl of instrDC is

-- 内部信号の定義
signal addix : std_logic;

begin
	OP_CODE <= D(7 downto 4);
	A <= D(3);
	ADR_MODE <= D(2 downto 0);
	CC <= D(3 downto 0);
	SR_MODE <= D(1 downto 0);

	process(D(7 downto 0)) begin
		if (D(2 downto 0) = "000") then
			B <= '0';
		elsif(D(2 downto 0) = "001") then
			B <= '1';
		else
			B <= '1';
		end if;
	end process;
	
	process(D(7 downto 0)) begin
		if (D(7 downto 4) > "0101") then
			if (D(2 downto 0) > "101") then
				addix <= '1';
			else
				addix <= '0';
			end if;
		else
			addix <= '0';
		end if;
	end process;
	
	ADI <= addix;
	
end rtl;