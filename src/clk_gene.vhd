--========================================================
--  Project   : AYME0100
--  Outline   : 教育用8ビットマイコン(kue-chip2)FPGA
----------------------------------------------------------
--  File Name : clk_gene.vhd
--  Function  : クロック信号ジェネレーター
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
entity CLK_GENE is
PORT(
	SYSCLK		: in std_logic;
	RESET			: in std_logic;
	FREQ_SEL		: in std_logic_vector(3 downto 0);
	CEN			: in std_logic;
	CLK_EN		: out std_logic;
	DIGIT_SEL	: out std_logic_vector(4 downto 0)
);
end CLK_GENE;

-- 回路の記述
architecture rtl of CLK_GENE is

-- 内部信号の定義
signal CLK_O				: std_logic;
signal DFF					: std_logic;
signal COUNT32				: std_logic_vector(31 downto 0);
signal SET_VALUE 			: std_logic_vector(31 downto 0);
--signal DISPLAY_COUNTER 	: std_logic_vector(11 downto 0) := "000000000000";
signal DISPLAY_COUNTER 	: std_logic_vector(14 downto 0) := "000000000000000";
--signal DISPLAY_COUNTER 	: std_logic_vector(18 downto 0) := "0000000000000000000";
signal DIGI_ADR1 			: std_logic := '0';
signal DIGI_ADR2 			: std_logic := '0';
signal DIGI_ADR3 			: std_logic := '0';
signal DIGI_DAT1 			: std_logic := '0';
signal DIGI_DAT2 			: std_logic := '0';
signal CLKFRQ 				: std_logic_vector(3 downto 0);

constant PROT				: integer := 0;
constant SIM				: integer := 0;

begin
	CLKFRQ <= not FREQ_SEL;
	
	process(SYSCLK, RESET, SET_VALUE) begin
		if (RESET = '1') then 
			COUNT32 <= x"FFFFFFFF";
		elsif(SYSCLK'event and SYSCLK='1') then
			if (CEN = '1') then
				if (COUNT32 = x"FFFFFFFF") then
					COUNT32 <= SET_VALUE;
				else
					COUNT32 <= COUNT32 + 1;
				end if;
			end if;
		end if;
	end process;
	
	process(CLKFRQ) begin
		case CLKFRQ is
--			when "0000" =>
--				SET_VALUE <= x"FFFFFFFF" - x"00000002";	-- 1/3 = 10MHz
			when "0000" =>
				SET_VALUE <= x"FFFFFFFF" - x"00000008";	-- 1/9 = 3.3Mhz
			when "0001" =>
				SET_VALUE <= x"FFFFFFFF" - x"0000001D";	-- 1/30 = 1MHz
			when "0010" =>
				SET_VALUE <= x"FFFFFFFF" - x"00000059";	-- 1/90 = 330kHz
			when "0011" =>
				SET_VALUE <= x"FFFFFFFF" - x"0000012B";	-- 1/300 = 100kHz
			when "0100" =>
				SET_VALUE <= x"FFFFFFFF" - x"00000383";	-- 1/900 = 33kHz
			when "0101" =>
				SET_VALUE <= x"FFFFFFFF" - x"00000BB7";	-- 1/3000 = 10kHz
			when "0110" =>
				SET_VALUE <= x"FFFFFFFF" - x"00002327";	-- 1/9000 = 3.3kHz
			when "0111" =>
				SET_VALUE <= x"FFFFFFFF" - x"0000752F";	-- 1/30000 = 1kHz
			when "1000" =>
				SET_VALUE <= x"FFFFFFFF" - x"00015F8F";	-- 1/90000 = 330Hz
			when "1001" =>
				SET_VALUE <= x"FFFFFFFF" - x"000493DF";	-- 1/300000 = 100Hz
			when "1010" =>
				SET_VALUE <= x"FFFFFFFF" - x"000DBB9F";	-- 1/900000 = 33Hz
			when "1011" =>
				SET_VALUE <= x"FFFFFFFF" - x"002DC6BF";	-- 1/3000000 = 10Hz
			when "1100" =>
				SET_VALUE <= x"FFFFFFFF" - x"0089543F";	-- 1/9000000 = 3.3Hz
			when "1101" =>
				SET_VALUE <= x"FFFFFFFF" - x"01C9C37F";	-- 1/30000000 = 1Hz
			when "1110" =>
				SET_VALUE <= x"FFFFFFFF" - x"055D4A7F";	-- 1/90000000 = 0.33Hz
			when "1111" =>
				SET_VALUE <= x"FFFFFFFF" - x"11E1A2FF";	-- 1/300000000 = 0.1Hz
			when others =>
				SET_VALUE <= x"FFFFFFFF" - x"FFFFFFFF";
		end case;
	end process;
	
	process(SYSCLK, RESET) begin
		if (RESET = '1') then
			CLK_O <= '0';
		elsif (SYSCLK'event and SYSCLK='1') then
			if (COUNT32 = x"FFFFFFFF") then
				CLK_O <= '1';
			else
				CLK_O <= '0';
			end if;
		end if;
	end process;
	
	CLK_EN <= CLK_O;

	COMPILE: if SIM /=1 generate
		process(SYSCLK) begin
			if (SYSCLK'event and SYSCLK='1') then
				DISPLAY_COUNTER <= DISPLAY_COUNTER + 1;
--				if (DISPLAY_COUNTER = "000000000001") then
				if (DISPLAY_COUNTER = "000000000000001") then
--				if (DISPLAY_COUNTER = "0000000000000000001") then
					DIGI_ADR3 <= '1';
--				elsif (DISPLAY_COUNTER = "001001011000") then	-- 0x258
				elsif (DISPLAY_COUNTER = "001011101110110") then	-- 0x1776
--				elsif (DISPLAY_COUNTER = "0001110101001100000") then	-- 0x0EA60
					DIGI_ADR3 <= '0';
					DIGI_ADR2 <= '1';
--				elsif (DISPLAY_COUNTER = "010010110000") then	-- 0x4B0
				elsif (DISPLAY_COUNTER = "010111011101100") then	-- 0x2EEC
--				elsif (DISPLAY_COUNTER = "0011101010011000000") then	-- 0x1D4C0
					DIGI_ADR2 <= '0';
					DIGI_ADR1 <= '1';
--				elsif (DISPLAY_COUNTER = "011100001000") then	-- 0x708
				elsif (DISPLAY_COUNTER = "100011001100010") then	-- 0x4662
--				elsif (DISPLAY_COUNTER = "0101011111100100000") then	-- 0x2BF20
					DIGI_ADR1 <= '0';
					DIGI_DAT2 <= '1';
--				elsif (DISPLAY_COUNTER = "100101100000") then	-- 0x960
				elsif (DISPLAY_COUNTER = "101110111011000") then	-- 0x5DD8
--				elsif (DISPLAY_COUNTER = "0111010100110000000") then	-- 0x3A980
					DIGI_DAT2 <= '0';
					DIGI_DAT1 <= '1';
--				elsif (DISPLAY_COUNTER = "101110111000") then	-- 0xBB8
				elsif (DISPLAY_COUNTER = "111010101001110") then	-- 0x754E
--				elsif (DISPLAY_COUNTER = "1001001001111100000") then	-- 0x493E0
--					DISPLAY_COUNTER <= "000000000000";				
					DISPLAY_COUNTER <= "000000000000000";				
--					DISPLAY_COUNTER <= "0000000000000000000";				
					DIGI_DAT1 <= '0';
				end if;
			end if;
		end process;
	end generate;
	
	SIMULATEION: if SIM = 1 generate
		process(SYSCLK) begin
			if (SYSCLK'event and SYSCLK='1') then
				DISPLAY_COUNTER <= DISPLAY_COUNTER + 1;
				if (DISPLAY_COUNTER = "000000000000001") then
					DIGI_ADR3 <= '1';
				elsif (DISPLAY_COUNTER = "000000000001000") then
					DIGI_ADR3 <= '0';
					DIGI_ADR2 <= '1';
				elsif (DISPLAY_COUNTER = "000000000010000") then
					DIGI_ADR2 <= '0';
					DIGI_ADR1 <= '1';
				elsif (DISPLAY_COUNTER = "000000000011000") then
					DIGI_ADR1 <= '0';
					DIGI_DAT2 <= '1';
				elsif (DISPLAY_COUNTER = "000000000100000") then
					DIGI_DAT2 <= '0';
					DIGI_DAT1 <= '1';
				elsif (DISPLAY_COUNTER = "000000000101000") then
					DISPLAY_COUNTER <= "000000000000000";				
					DIGI_DAT1 <= '0';
				end if;
			end if;
		end process;
	end generate;

	DIGIT_SEL <= not DIGI_ADR3 & not DIGI_ADR2 & not DIGI_ADR1 & not DIGI_DAT2 & not DIGI_DAT1;
	
end RTL;