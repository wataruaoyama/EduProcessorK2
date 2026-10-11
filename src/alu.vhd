--========================================================
--  Project   : AYME0100
--  Outline   : 教育用8ビットマイコン(kue-chip2)FPGA
----------------------------------------------------------
--  File Name : alu.vhd
--  Function  : シフト・ローテート命令以外の算術論理演算の実行
--  Note      : 
--              
----------------------------------------------------------
--  Date      : Rev.0.9 2024.04.24 Wataru AOYAMA(ANT TECH)
--  Update    :
--========================================================
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
--use IEEE.std_logic_signed.all;
use IEEE.std_logic_arith.all;
use WORK.all;

-- 入出力の宣言
entity ALU is
PORT(
	CLK		: in std_logic;
	RESET		: in std_logic;
	CLKEN		: in std_logic;
	A			: in std_logic_vector(7 downto 0);
	B			: in std_logic_vector(7 downto 0);
	M			: in std_logic_vector(3 downto 0);
	ADR_MODE	: in std_logic_vector(2 downto 0);
	CIN		: in std_logic;
	O			: out std_logic_vector(7 downto 0);
	CF_ALU	: out std_logic;
	VF_ALU	: out std_logic;
	NF_ALU	: out std_logic;
	ZF_ALU	: out std_logic
);
end ALU;

-- 回路の記述
architecture rtl OF ALU is

-- 内部信号の定義
signal RES : std_logic_vector(8 downto 0);
signal VF : std_logic;
signal CF : std_logic;
signal ZF : std_logic;
signal NF : std_logic;

begin
	process(CLK, RESET) begin
		if (RESET = '1') then
			RES <= "000000000";
			VF <= '0';
			CF <= '0';
			NF <= '0';
			ZF <= '0';
		elsif(CLK'event and CLK='1') then
			case M is
						
				when "1000" =>		-- SBC
					RES <= ('0' & A) + ((not ('0' & B)) + 1) - CIN;
					if (((not A(7) and B(7) and RES(7)) = '1') or (((A(7) and not B(7) and not RES(7))) = '1')) then
						VF <= '1';
					else
						VF <= '0';
					end if;
					if (RES(8) = '1') then
						CF <= '1';
					else
						CF <= '0';
					end if;
					if ( RES(7) = '1') then
						NF <= '1';
					else
						NF <= '0';
					end if;
					if (RES(7 downto 0) = "00000000") then
						ZF <= '1';
					else
						ZF <= '0';
					end if;
					
				when "1001" =>		-- ADC
					RES <= ('0'  & A) + ('0' & B) + CIN;
					if (((not A(7) and not B(7) and RES(7)) = '1') or ((A(7) and B(7) and not RES(7)) = '1')) then
						VF <= '1';
					else
						VF <= '0';
					end if;
					if (RES(8) = '1') then
						CF <= '1';
					else
						CF <= '0';
					end if;
					if ( RES(7) = '1') then
						NF <= '1';
					else
						NF <= '0';
					end if;
					if (RES(7 downto 0) = "00000000") then
						ZF <= '1';
					else
						ZF <= '0';
					end if;
					
				when "1010" =>		-- SUB
					RES <= (A(7) & A) + not (B(7) & B)+ 1;
					if (((not A(7) and B(7) and RES(7)) = '1') or (((A(7) and not B(7) and not RES(7))) = '1')) then
						VF <= '1';
					else
						VF <= '0';
					end if;
					if ( RES(7) = '1') then
						NF <= '1';
					else
						NF <= '0';
					end if;
					if (RES(7 downto 0) = "00000000") then
						ZF <= '1';
					else
						ZF <= '0';
					end if;
					CF <= CIN;

				when "1011" =>		-- ADD
					RES <= (A(7) & A) + (B(7) & B);
					if (((not A(7) and not B(7) and RES(7)) = '1') or ((A(7) and B(7) and not RES(7)) = '1')) then
						VF <= '1';
					else
						VF <= '0';
					end if;
					if ( RES(7) = '1') then
						NF <= '1';
					else
						NF <= '0';
					end if;
					if (RES(7 downto 0) = "00000000") then
						ZF <= '1';
					else
						ZF <= '0';
					end if;
					CF <= CIN;
					
				when "1100" =>		-- EOR
					RES <= '0' & A xor '0' & B;
					VF <= '0';
					if ( RES(7) = '1') then
						NF <= '1';
					else
						NF <= '0';
					end if;
					if (RES(7 downto 0) = "00000000") then
						ZF <= '1';
					else
						ZF <= '0';
					end if;
					CF <= CIN;
					
				when "1101" =>		-- OR
					RES <= '0' & A or '0' & B;
					VF <= '0';
					if ( RES(7) = '1') then
						NF <= '1';
					else
						NF <= '0';
					end if;
					if (RES(7 downto 0) = "00000000") then
						ZF <= '1';
					else
						ZF <= '0';
					end if;
					CF <= CIN;
					
				when "1110" =>		-- AND
					RES <= '0' & A and '0' & B;
					VF <= '0';
					if ( RES(7) = '1') then
						NF <= '1';
					else
						NF <= '0';
					end if;
					if (RES(7 downto 0) = "00000000") then
						ZF <= '1';
					else
						ZF <= '0';
					end if;
					
					CF <= CIN;
					
				when "1111" =>		-- CMP
					RES <= ('0' & A) + not ('0' & B) + 1;
					if (((not A(7) and B(7) and RES(7)) = '1') or (((A(7) and not B(7) and not RES(7))) = '1')) then
						VF <= '1';
					else
						VF <= '0';
					end if;
					if ( RES(7) = '1') then
						NF <= '1';
					else
						NF <= '0';
					end if;
					if (RES(7 downto 0) = "00000000") then
						ZF <= '1';
					else
						ZF <= '0';
					end if;
					CF <= CIN;
					
				when others =>
					RES <= (A(7) & A) + (B(7) & B);
				
			end case;
		end if;
	end process;
	
	o <= RES(7 downto 0);
	
	CF_ALU <= CF;
	VF_ALU <= VF;
	NF_ALU <= NF;
	ZF_ALU <= ZF;
	
end rtl;