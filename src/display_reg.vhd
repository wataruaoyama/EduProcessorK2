--========================================================
--  Project   : AYME0100
--  Outline   : 教育用8ビットマイコン(kue-chip2)FPGA
----------------------------------------------------------
--  File Name : display_reg.vhd
--  Function  : 7セグLEDに表示するレジスタの選択、表示
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
entity DISPLAY_REG is
port(
	CLK				: in std_logic;
	RESET				: in std_logic;
	SEL_SW			: in std_logic_vector(3 downto 0);
	PRG_CNT			: in std_logic_vector(7 downto 0);
	FLAG_REG			: in std_logic_vector(7 downto 0);
	INST_REG			: in std_logic_vector(7 downto 0);
	ACC_REG			: in std_logic_vector(7 downto 0);
	IX_REG			: in std_logic_vector(7 downto 0);
	ADR_REG			: in std_logic_vector(7 downto 0);
	DBI				: in std_logic_vector(7 downto 0);
	DBO				: in std_logic_vector(7 downto 0);
	DATA_RAM_OUT	: in std_logic_vector(7 downto 0);
	PROG_RAM_OUT	: in std_logic_vector(7 downto 0);
	ADDRESS_IN		: in std_logic_vector(7 downto 0);
	ADDR8				: in std_logic;
	DIGIT_SEL		: in std_logic_vector(4 downto 0);
	SEG_O				: out std_logic_vector(6 downto 0)
);
end DISPLAY_REG;

-- 回路の記述
architecture rtl of DISPLAY_REG is

-- 内部信号の定義
signal ADDRESS_3RD 	: std_logic_vector(3 downto 0);
signal DATA 			: std_logic_vector(7 downto 0);
signal DTSEG1 			: std_logic_vector(6 downto 0);
signal DTSEG2 			: std_logic_vector(6 downto 0);
signal ADRSEG1 		: std_logic_vector(6 downto 0);
signal ADRSEG2 		: std_logic_vector(6 downto 0);
signal ADRSEG3 		: std_logic_vector(6 downto 0);

constant PROT			: integer := 0;

-- SEVEN_SEGDECコンポーネントの宣言
component SEVEN_SEGDEC
	port (
		DIN   : in	std_logic_vector( 3 downto 0);
		DOUT  : out std_logic_vector( 6 downto 0) 
		);
end component;

begin
	process(SEL_SW, PRG_CNT, FLAG_REG, INST_REG, ACC_REG, IX_REG, DBI, DBO, ADR_REG, PROG_RAM_OUT, DATA_RAM_OUT) begin
		case SEL_SW is
			when "0000" =>
				DATA <= PROG_RAM_OUT;
				
			when "0001" =>
				DATA <= DATA_RAM_OUT;
				
			when "0010" =>
				DATA <= PRG_CNT;
				
			when "0011" =>
				DATA <= FLAG_REG;
				
			when "0100" =>
				DATA <= ACC_REG;
				
			when "0101" =>
				DATA <= IX_REG;
				
			when "0110" =>
				DATA <= DBI;
				
			when "0111" =>
				DATA <= DBO;
				
			when "1000" =>
				DATA <= ADR_REG;
			
			when "1001" =>
				DATA <= INST_REG;
				
			when others =>
				DATA <= "00000000";
		end case;
	end process;
	
	process(ADDR8) begin
		if (ADDR8 = '0') then
			ADDRESS_3RD <= "0000";
		else
			ADDRESS_3RD <= "0001";
		end if;
	end process;
	
	PROTOTYPE: if PROT = 1 generate
		process(RESET, DIGIT_SEL, DTSEG1, DTSEG2, ADRSEG1, ADRSEG2, ADRSEG3) begin
			if (RESET = '1') then
				SEG_O <= "1111110";
			elsif (DIGIT_SEL = "00001") then
				SEG_O <= DTSEG1;
			elsif (DIGIT_SEL = "00010") then
				SEG_O <= DTSEG2;
			elsif (DIGIT_SEL = "00100") then
				SEG_O <= ADRSEG1;
			elsif (DIGIT_SEL = "01000") then
				SEG_O <= ADRSEG2;
			elsif (DIGIT_SEL = "10000") then
				SEG_O <= ADRSEG3;
			else
				SEG_O <= "0000000";
			end if;
		end process;
	end generate;
		
	COMPLETE: if PROT /= 1 generate
		process(RESET, DIGIT_SEL, DTSEG1, DTSEG2, ADRSEG1, ADRSEG2, ADRSEG3) begin	
			if (RESET = '1') then
				SEG_O <= "1111110";
			elsif (DIGIT_SEL = "11110") then
				SEG_O <= DTSEG1;
			elsif (DIGIT_SEL = "11101") then
				SEG_O <= DTSEG2;
			elsif (DIGIT_SEL = "11011") then
				SEG_O <= ADRSEG1;
			elsif (DIGIT_SEL = "10111") then
				SEG_O <= ADRSEG2;
			elsif (DIGIT_SEL = "01111") then
				SEG_O <= ADRSEG3;
			else
				SEG_O <= "0000000";
			end if;	
		end process;
	end generate;

-- SEVEN_SEGDECコンポーネント(1)の実体化と入出力の相互接続	
	s1: SEVEN_SEGDEC port map(DIN => DATA(3 downto 0), DOUT => DTSEG1);

-- SEVEN_SEGDECコンポーネント(2)の実体化と入出力の相互接続	
	s2: SEVEN_SEGDEC port map(DIN => DATA(7 downto 4), DOUT => DTSEG2);

-- SEVEN_SEGDECコンポーネント(3)の実体化と入出力の相互接続	
	s3: SEVEN_SEGDEC port map(DIN => ADDRESS_IN(3 downto 0), DOUT => ADRSEG1);

-- SEVEN_SEGDECコンポーネント(4)の実体化と入出力の相互接続	
	s4: SEVEN_SEGDEC port map(DIN => ADDRESS_IN(7 downto 4), DOUT => ADRSEG2);

-- SEVEN_SEGDECコンポーネント(5)の実体化と入出力の相互接続	
	s5: SEVEN_SEGDEC port map(DIN => ADDRESS_3RD, DOUT => ADRSEG3);
	
end rtl;