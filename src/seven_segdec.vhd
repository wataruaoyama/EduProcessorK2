--========================================================
--  Project   : AYME0100
--  Outline   : 教育用8ビットマイコン(kue-chip2)FPGA
----------------------------------------------------------
--  File Name : seven_segdec.vhd
--  Function  : 7セグメントデコーダー
--  Note      : 
--              
----------------------------------------------------------
--  Date      : Rev.0.9 2024.04.24 Wataru AOYAMA(ANT TECH)
--  Update    :
--========================================================
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.all;

-- 入出力の宣言
entity SEVEN_SEGDEC is
	port (
		DIN   : in	std_logic_vector( 3 downto 0);
		DOUT  : out std_logic_vector( 6 downto 0) );
end SEVEN_SEGDEC;

-- 回路の記述
architecture rtl of SEVEN_SEGDEC is

begin
	process( DIN ) begin
		case  DIN is
	--						High active
			when "0000" => DOUT <= "1111110";
			when "0001" => DOUT <= "0110000";
			when "0010" => DOUT <= "1101101";
			when "0011" => DOUT <= "1111001";
			when "0100" => DOUT <= "0110011";
			when "0101" => DOUT <= "1011011";
			when "0110" => DOUT <= "1011111";
			when "0111" => DOUT <= "1110000";
			when "1000" => DOUT <= "1111111";
			when "1001" => DOUT <= "1111011";
			when "1010" => DOUT <= "1110111";
			when "1011" => DOUT <= "0011111";
			when "1100" => DOUT <= "1001110";
			when "1101" => DOUT <= "0111101";
			when "1110" => DOUT <= "1001111";
			when "1111" => DOUT <= "1000111";
			when others => DOUT <= "0000000";
	--										abcdefg
	end case;
  end process;
end rtl; 
                   
     
      
