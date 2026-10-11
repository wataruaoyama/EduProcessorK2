--========================================================
--  Project   : AYME0100
--  Outline   : 教育用8ビットマイコン(kue-chip2)FPGA
----------------------------------------------------------
--  File Name : flag_reg.vhd
--  Function  : フラグレジスタ
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
entity FLAG_REG is
port(
	SYSCLK	: in std_logic;
	RESET		: in std_logic;
	CKEN		: in std_logic;
	EXE_ALU	: in std_logic;
	SHFT_EN	: in std_logic;
	ROT_EN	: in std_logic;
	CF_ALU	: in std_logic;
	VF_ALU	: in std_logic;
	NF_ALU	: in std_logic;
	ZF_ALU	: in std_logic;
	RCF		: in std_logic;
	SCF		: in std_logic;
	CF_SHFT	: in std_logic;
	VF_SHFT	: in std_logic;
	NF_SHFT	: in std_logic;
	ZF_SHFT	: in std_logic;
	OP_CODE	: in std_logic_vector(3 downto 0);
	CFOUT		: out std_logic;
	D_OUT		: out std_logic_vector(7 downto 0)
);
end FLAG_REG;

-- 回路の記述
architecture rtl of FLAG_REG is

-- 内部信号の定義
signal FLG_REG : std_logic_vector(3 downto 0);
signal EN 		: std_logic;
signal DFF4 	: std_logic_vector(3 downto 0);

begin
	process(SYSCLK, RESET) begin
		if (RESET = '1') then
			FLG_REG <= "0000";
		elsif (SYSCLK'event and SYSCLK='1') then
			if (EN = '1') then
				if (EXE_ALU = '1') then
					if (OP_CODE = "1000" or OP_CODE = "1001") then
						FLG_REG(3) <= CF_ALU;							-- CF from ALU
					else
						FLG_REG(3) <= CF_ALU;-- or CF_SHFT;
					end if;
					FLG_REG(2) <= VF_ALU; 								-- VF from ALU
					FLG_REG(1) <= NF_ALU;								-- NF from ALU
					FLG_REG(0) <= ZF_ALU;								-- ZF from ALLU
				elsif (SHFT_EN = '1' or ROT_EN = '1') then
					FLG_REG(3) <= CF_SHFT;								-- CF from SHIFTER
					FLG_REG(2) <= VF_SHFT;								-- VF from SHIFTER
					FLG_REG(1) <= NF_SHFT;								-- NF from SHIFTER
					FLG_REG(0) <= ZF_SHFT;								-- ZF from SHIFTER
				end if;
			end if;
			
			if (RCF = '1') then
				FLG_REG(3) <= '0';
			elsif (SCF = '1') then
				FLG_REG(3) <= '1';
			end if;
			
		end if;
	end process;
	
	process(SYSCLK, RESET) begin
		if (RESET = '1') then
			DFF4 <= "0000";
		elsif(SYSCLK'event and SYSCLK='1') then
			DFF4 <= DFF4(2 downto 0) & CKEN;
		end if;
	end process;
	
	EN <= not DFF4(3) and DFF4(2);
	D_OUT <= '0' & '0' & '0' & '0' & FLG_REG;
	CFOUT <= FLG_REG(3);
	
end RTL;