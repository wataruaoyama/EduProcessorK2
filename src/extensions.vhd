--========================================================
--  Project   : AYME0100
--  Outline   : 教育用8ビットマイコン(kue-chip2)FPGA
----------------------------------------------------------
--  File Name : extensions.vhd
--  Function  : 
--  Note      : 
--              
----------------------------------------------------------
--  Date      :  Wataru AOYAMA(ANR TECH)
--  Update    :
--========================================================
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.all;

-- 入出力の宣言
entity EXTENSIONS is
port (
	CLK				: in std_logic;
	RESET				: in std_logic;
	EN_EX				: in std_logic;
	AD_DT				: in std_logic;
	RD_WR				: in std_logic;
	ADR8				: in std_logic;
	AD_BUS			: in std_logic_vector(7 downto 0);
	EX_EN				: out std_logic;
	EX_WR_RD			: out std_logic;
	EX_ADR8			: out std_logic;
	EX_ADDR			: out std_logic_vector(7 downto 0);
	EX_DATA			: out std_logic_vector( 7 downto 0)
	);
end EXTENSIONS;

-- 回路の記述
architecture rtl of EXTENSIONS is

-- 内部信号の定義
signal DFF1 : std_logic_vector(11 downto 0);
signal DFF2 : std_logic_vector(11 downto 0);
signal DFF3 : std_logic;

begin
	process(CLK, RESET) begin
		if (RESET = '1') then
			DFF1 <= "000000000000";
			DFF2 <= "000000000000";
			DFF3 <= '0';
		elsif (CLK'event and CLK='1') then
			DFF1(11) <= EN_EX;
			DFF1(10) <= AD_DT;	-- アドレス／データの識別信号
			DFF1(9) <= RD_WR;		-- ライトイネーブル信号
			DFF1(8) <= ADR8;
			DFF1(7 downto 0) <= AD_BUS;
			DFF2(11 downto 0) <= DFF1(11 downto 0);
			DFF3 <= DFF2(10);
		end if;
	end process;
	
	EX_WR_RD <= DFF2(9);
	EX_EN <= DFF2(11);
	
	process(CLK, RESET) begin
		if (RESET = '1') then
			EX_ADR8 <= '0';
			EX_ADDR <= "00000000";
		elsif (CLK'event and CLK='1') then
			if ((DFF2(10) and not DFF3) = '1') then
				EX_ADR8 <= ADR8;
				EX_ADDR <= AD_BUS(7 downto 0);
			elsif (AD_DT = '0') then
				EX_DATA <= AD_BUS(7 downto 0);
			end if;
		end if;
	end process;
	
end rtl; 
                   
     
      
