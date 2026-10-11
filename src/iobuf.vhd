--========================================================
--  Project   : AYME0100
--  Outline   : 教育用8ビットマイコン(kue-chip2)FPGA
----------------------------------------------------------
--  File Name : iobuf.vhd
--  Function  : 入出力バッファの制御
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
entity IOBUF is
port(
	SYSCLK				: in std_logic;
	RESET					: in std_logic;
	OBUF_EN				: in std_logic;
	OBUF_FLG_SET		: in std_logic;
--	OBUF_FLG_CLR		: in std_logic;
	--
	OBUF_FLG_O			: out std_logic;								-- 送信時、バッファに送信データがあることを通知するフラグ
	REQ_STB_IN			: in std_logic;
	OBUF_STB_O			: out std_logic;								-- 送信時、相手（受信側）へ送信するストローブ信号
	OBUF					: out std_logic_vector(7 downto 0);
	--
--	OBUF_FLG_IN			: in std_logic;								-- 受信時、相手（送信側）に送信するデータがあることを知るためのフラグ
	REQ_STB				: out std_logic;								-- 受信時、相手（送信側）のフラグをクリアし、ストローブ信号の発出を要求する信号
	OBUF_STB_IN			: in std_logic;								-- 受信時、相手（送信側）からのデータを、受信バッファに取り込むための信号
	IBUF					: in std_logic_vector(7 downto 0);
	--
	IBUF_FLG				: out std_logic;								-- 受信バッファに受信データのあることを示すフラグ
	IBUF_FLG_CLR		: in std_logic;								-- 受信バッファをクリアする信号
	DBO					: in std_logic_vector(7 downto 0);
	IBUFO					: out std_logic_vector(7 downto 0)
);
end IOBUF;

-- 回路の記述
architecture rtl of IOBUF is

-- 内部信号の定義
signal EN 						: std_logic;
signal DFF 						: std_logic_vector(3 downto 0);
signal REQ_STB_COUNT 		: std_logic_vector(5 downto 0);
signal OBUF_STB_COUNT 		: std_logic_vector(5 downto 0);
signal OBUF_STB_IN_REDGE 	: std_logic;
signal IBUF_FLG_CLR_REDGE	: std_logic;
signal IBUF_FLG_CLR_FEDGE 	: std_logic;
signal OBUF_FLG_SET_REDGE 	: std_logic;
signal REQ_STB_IN_REDGE 	: std_logic;
signal START 					: std_logic;
signal COUNT2 					: std_logic_vector(1 downto 0);
signal IBUF_FLG_I 			: std_logic;

begin
	process(SYSCLK, RESET) begin
		if (RESET = '1') then
			OBUF <= "00000000";
			IBUFO <= "00000000";
		elsif (SYSCLK'event and SYSCLK='1') then
			if (en = '1') then
				OBUF <= DBO;
			elsif (OBUF_STB_IN = '0') then
				IBUFO <= IBUF;
			end if;
		end if;
	end process;
	

	process(SYSCLK, RESET) begin
		if (RESET = '1') then
			REQ_STB <= '1';
			REQ_STB_COUNT <= "000000";
		elsif (SYSCLK'event and SYSCLK='1') then
			if (IBUF_FLG_CLR_FEDGE = '1') then
				REQ_STB <= '0';
				REQ_STB_COUNT <= "000000";
			elsif (REQ_STB_COUNT = "101000") then
				REQ_STB <= '1';
			else
				REQ_STB_COUNT <= REQ_STB_COUNT + 1;
			end if;
		end if;
	end process;
	
	
	process(SYSCLK, RESET) begin
		if (RESET = '1') then
			OBUF_STB_O <= '1';
			OBUF_STB_COUNT <= "000000";
		elsif (SYSCLK'event and SYSCLK='1') then
			if (OBUF_FLG_SET_REDGE = '1') then
				OBUF_STB_O <= '0';
				OBUF_STB_COUNT <= "000000";
			elsif (OBUF_STB_COUNT = "101000") then
				OBUF_STB_O <= '1';
			else
				OBUF_STB_COUNT <= OBUF_STB_COUNT + 1;
			end if;
		end if;
	end process;
	
	process(SYSCLK, RESET) begin
		if (RESET = '1') then
			OBUF_FLG_O <= '0';
		elsif (SYSCLK'event and SYSCLK='1') then
			if (OBUF_FLG_SET_REDGE = '1') then
				OBUF_FLG_O <= '1';
			elsif (REQ_STB_IN_REDGE = '1') then
				OBUF_FLG_O <= '0';
			end if;
		end if;
	end process;
	
	process(SYSCLK, RESET) begin
		if (RESET = '1') then
			IBUF_FLG_I <= '0';
		elsif (SYSCLK'event and SYSCLK='1') then
			if (OBUF_STB_IN_REDGE = '1' and START = '1') then
				IBUF_FLG_I <= '1';
			elsif (IBUF_FLG_CLR_REDGE = '1') then
				IBUF_FLG_I <= '0';
			end if;
		end if;
	end process;
	
	process(SYSCLK, RESET) begin
		if (RESET = '1') then
			START <= '0';
			count2 <= "00";
		elsif (SYSCLK'event and SYSCLK='1') then
			if (COUNT2 = "11") then
				COUNT2 <= "11";
				START <= '1';
			else
				COUNT2 <= COUNT2 + 1;
			end if;
		end if;
	end process;
	
	process(SYSCLK, RESET) begin
		if (RESET = '1') then
			DFF <= "0000";
		elsif (SYSCLK'event and SYSCLK='1') then
			DFF(0) <= OBUF_STB_IN;
			DFF(1) <= IBUF_FLG_CLR;
			DFF(2) <= OBUF_FLG_SET;
			DFF(3) <= REQ_STB_IN;
		end if;
	end process;
	
	OBUF_STB_IN_REDGE <= OBUF_STB_IN and not DFF(0);
	IBUF_FLG_CLR_REDGE <= IBUF_FLG_CLR and not DFF(1);
	IBUF_FLG_CLR_FEDGE <= not IBUF_FLG_CLR and DFF(1);
	OBUF_FLG_SET_REDGE <= OBUF_FLG_SET and not DFF(2);
	REQ_STB_IN_REDGE <= REQ_STB_IN and not DFF(3);
	
	
	EN <= OBUF_EN;
	IBUF_FLG <= IBUF_FLG_I;
	
end rtl;