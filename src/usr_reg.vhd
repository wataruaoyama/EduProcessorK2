--========================================================
--  Project   : AYME0100
--  Outline   : 教育用8ビットマイコン(kue-chip2)FPGA
----------------------------------------------------------
--  File Name : usr_reg.vhd
--  Function  : ユーザーレジスタ(ACC/IX)の制御
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
entity USR_REG is
port(
	CLK		: in std_logic;
	RESET		: in std_logic;
	ACC_EN	: in std_logic;
	IX_EN		: in std_logic;
	SEL1		: in std_logic;	-- ix_acc
	SEL2		: in std_logic;	-- ix_SEL
	SEL3		: in std_logic;	-- SEL_alu
	SEL4		: in std_logic;	-- exe_alu
	MEMWE		: in std_logic;
	D_IN		: in std_logic_vector(7 downto 0);
	ALU_IN	: in std_logic_vector(7 downto 0);
	A_OUT		: out std_logic_vector(7 downto 0);
	B_OUT		: out std_logic_vector(7 downto 0);
	IREG		: out std_logic_vector(7 downto 0);
	ACCREG	: out std_logic_vector(7 downto 0);
	MO			: out std_logic_vector(7 downto 0)
);
end USR_REG;

-- 回路の記述
architecture rtl of USR_REG is

signal MUX1 	: std_logic_vector(7 downto 0);
signal MUX2 	: std_logic_vector(7 downto 0);
signal MUX3 	: std_logic_vector(7 downto 0);
signal ACC_REG : std_logic_vector(7 downto 0);
signal IX_REG 	: std_logic_vector(7 downto 0);
signal EN_ACC 	: std_logic;
signal EN_IX 	: std_logic;
signal SHIFT4 	: std_logic_vector(3 downto 0);
signal DFF4 	: std_logic_vector(3 downto 0);

begin
	process(CLK, RESET) begin
		if (RESET = '1') then
			ACC_REG <= "00000000";
			IX_REG <= "00000000";
		elsif (CLK'event and CLK = '1') then
			if (EN_ACC = '1') then
				ACC_REG <= ALU_IN;
			elsif (EN_IX = '1') then
				IX_REG <= ALU_IN;
			end if;
		end if;
	end process;
	
	----------------------------------------------
	-- 演算命令以外の場合、0データを選択
	----------------------------------------------
	MUX3 <= "00000000" when (SEL4 = '0') else MUX1;
	
	----------------------------------------------
	-- 第1オペランドで指定されるレジスタ選択
	----------------------------------------------
	MUX1 <= ACC_REG when SEL1 = '0' else IX_REG;
	
	----------------------------------------------
	-- 第2オペランドで指定されるレジスタと
	-- メモリリードデータの選択
	----------------------------------------------
	process(SEL1, SEL2, SEL3, ACC_REG, MEMWE, IX_REG, D_IN) begin
		if (MEMWE = '1') then
			if (SEL1 = '1') then
				MUX2 <= IX_REG;
			else
				MUX2 <= ACC_REG;
			end if;
		elsif (SEL3 = '1') then
			MUX2 <= D_IN;
		else
			if (SEL2 = '0') then
				MUX2 <= ACC_REG;
			else
				MUX2 <= IX_REG;
			end if;
		end if;
	end process;
	
	process(CLK, RESET) begin
		if (RESET = '1') then
			SHIFT4 <= "0000";
		elsif (CLK'event and CLK='1') then
			SHIFT4 <= SHIFT4(2 downto 0) & ACC_EN;
		end if;
	end process;
		
	process(CLK, RESET) begin
		if (RESET = '1') then
			DFF4 <= "0000";
		elsif (CLK'event and CLK='1') then
			DFF4 <= DFF4(2 downto 0) & IX_EN;
		end if;
	end process;
		
	EN_ACC <= not SHIFT4(3) and SHIFT4(2);
	EN_IX <= not DFF4(3) and DFF4(2);
	
	A_OUT <= MUX3;
	B_OUT <= MUX2;
	ACCREG <= ACC_REG;
	IREG <= IX_REG;
	MO <= MUX1;
	
end rtl;