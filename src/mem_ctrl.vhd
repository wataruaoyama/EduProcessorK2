--========================================================
--  Project   : AYME0100
--  Outline   : 教育用8ビットマイコン(kue-chip2)FPGA
----------------------------------------------------------
--  File Name : mem_ctrl.vhd
--  Function  : プログラムRAM、データRAMのリード・ライト制御
--  Note      : 
--              
----------------------------------------------------------
--  Date      : Rev.0.9 2024.04.24 Wataru AOYAMA(ANR TECH)
--  Update    : Rev.1.1 2025.02.16 あおやまわたる(ANR TECH)
----------------------------------------------------------
--  Memo      : SELスイッチが"0001"でデータ領域からフェッチする仕
--            : 様を変更
--========================================================
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use WORK.all;

-- 入出力の宣言
entity MEM_CTRL is
port(
	CLK			: in std_logic;
	DEMO			: in std_logic;
	ADDR8			: in std_logic;
	ADDR8_SW		: in std_logic;	--
	ADR			: in std_logic_vector(7 downto 0);
	MEMWE			: in std_logic;
	DATA_I		: in std_logic_vector(7 downto 0);
	DATA_O		: out std_logic_vector(7 downto 0);
	DATA_RAM_O	: out std_logic_vector(7 downto 0);
	PROG_RAM_O	: out std_logic_vector(7 downto 0)
);
end MEM_CTRL;

-- 回路の記述
architecture rtl of MEM_CTRL is

-- 内部信号の定義
signal DATA_RAM_OUT : std_logic_vector(7 downto 0);
signal PROG_RAM_OUT : std_logic_vector(7 downto 0);
signal DATA_RAM_WEN : std_logic := '0';
signal PROG_RAM_WEN : std_logic := '0';

-- DATA_RAMコンポーネントの宣言
component DATA_RAM
port(
	ADDRESS	: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
	CLOCK		: IN STD_LOGIC  := '1';
	DATA		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
	WREN		: IN STD_LOGIC ;
	Q			: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
end component;

-- PROG_RAMコンポーネントの宣言
component PROG_RAM
port(
	ADDRESS	: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
	CLOCK		: IN STD_LOGIC  := '1';
	DATA		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
	WREN		: IN STD_LOGIC ;
	Q			: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
end component;

begin

-- DATA_RAMコンポーネントの実体化と入出力の相互接続
	ram1 : DATA_RAM port map(ADDRESS => ADR, CLOCK => CLK, DATA => DATA_I, WREN => DATA_RAM_WEN, q => DATA_RAM_OUT);

-- CLK_GENEコンポーネントの実体化と入出力の相互接続	
	ram2 : PROG_RAM port map(ADDRESS => ADR, CLOCK => CLK, DATA => DATA_I, WREN => PROG_RAM_WEN, q => PROG_RAM_OUT);
	
	process(DEMO, ADDR8, MEMWE, ADDR8_SW) begin
		if (DEMO = '1') then
			if ((ADDR8 = '1' or ADDR8_SW = '1') and MEMWE = '1') then
				DATA_RAM_WEN <= '1';
				PROG_RAM_WEN <= '0';
			else
				DATA_RAM_WEN <= '0';
				PROG_RAM_WEN <= '0';
			end if;
		else
			if ((ADDR8 = '1' or ADDR8_SW = '1') and MEMWE = '1') then
				DATA_RAM_WEN <= '1';
				PROG_RAM_WEN <= '0';
			elsif ((ADDR8 = '1' or ADDR8_SW = '1') and MEMWE = '0') then
				DATA_RAM_WEN <= '0';
				PROG_RAM_WEN <= '0';
			elsif ((ADDR8 = '0' or ADDR8_SW = '0') and MEMWE = '1') then
				DATA_RAM_WEN <= '0';
				PROG_RAM_WEN <= '1';
			else
				DATA_RAM_WEN <= '0';
				PROG_RAM_WEN <= '0';
			end if;
		end if;
	end process;
					
	process(DEMO, ADDR8, DATA_RAM_WEN, PROG_RAM_WEN, DATA_RAM_OUT, PROG_RAM_OUT) begin
		if (DEMO = '1') then
			if (ADDR8 = '1' and DATA_RAM_WEN = '0') then
				DATA_O <= DATA_RAM_OUT;
			else
				DATA_O <= "00000000";
			end if;
		else
			if (ADDR8 = '1' and DATA_RAM_WEN = '0') then
				DATA_O <= DATA_RAM_OUT;
			elsif (ADDR8 = '0' and PROG_RAM_WEN = '0') then
				DATA_O <= PROG_RAM_OUT;
			else
				DATA_O <= PROG_RAM_OUT;
			end if;
		end if;
	end process;
	
	DATA_RAM_O <= DATA_RAM_OUT;
	PROG_RAM_O <= PROG_RAM_OUT;
	
end rtl;