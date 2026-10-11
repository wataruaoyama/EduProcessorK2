--========================================================
--  Project   : AYME0900
--  Outline   : 教育用8ビットマイコン(kue-chip2)FPGA
----------------------------------------------------------
--  File Name : AYME0900.vhd
--  Function  : トップレベルエンティティ
--  Note      : 
--              
----------------------------------------------------------
--  Date      : Rev.0.9 2024.04.24 Wataru AOYAMA(ANT TECH)
--  Update    :
--========================================================
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unSIgned.all;
use work.all;

-- 入出力の宣言
entity AYME0900 is
port (
	SYSCLK				: in std_logic;
	XRESET				: in std_logic;
	XFPGA_RST			: in std_logic;
	FREQ_SEL				: in std_logic_vector(3 downto 0);
	IBUF_STB				: in std_logic;
	REQ_STB_IN			: in std_logic;
	IBUF					: in std_logic_vector(7 downto 0);
	IBUF_FLG_LED		: out std_logic;
	OBUF_FLG				: out std_logic;
	REQ_STB				: out std_Logic;
	OBUF_STB				: out std_logic;
	OBUF					: out std_logic_vector(7 downto 0);
	IBUFO_LED			: out std_logic_vector(7 downto 0);
	IBUFO_P				: out std_logic_vector(7 downto 0);
	SW_IN					: in std_logic_vector(18 downto 0);
	SEG_O					: out std_logic_vector(6 downto 0);
	PHASE_LED			: out std_logic_vector(4 downto 0);
	OP_LED				: out std_logic;
	SEL_DIGIT			: out std_logic_vector(7 downto 0);
	OBUF_LED				: out std_logic_vector(7 downto 0);
	OBUF_P				: out std_logic_vector(7 downto 0);
	EN_EX				: in std_logic;
	AD_DT				: in std_logic;
	RD_WR				: in std_logic;
	ADR8				: in std_logic;
	AD_BUS			: in std_logic_vector(7 downto 0)	
	);
end AYME0900;

-- 回路の記述
architecture rtl of AYME0900 is

-- MCUコンポーネントの宣言
component MCU
port(
	SYSCLK				: in std_logic;
	RESET					: in std_logic;
	FREQ_SEL				: in std_logic_vector(3 downto 0);
	CEN					: in std_logic;
	DEMO					: in std_logic;
	SP						: in std_logic;
	SI						: in std_logic;
	SS						: in std_logic;
	SET					: in std_logic;
	INC					: in std_logic;
	DEC					: in std_logic;
	SEL_MAR				: in std_logic;
	SW_DATA_WE			: in std_logic;
	ADDR8_SW				: in std_logic;
	DATA_SW				: in std_logic_vector(7 downto 0);
	IBUF_STB				: in std_logic;
	REQ_STB_IN			: in std_logic;
	IBUF					: in std_logic_vector(7 downto 0);
	IBUF_FLG_LED		: out std_logic;
	OBUF_FLG				: out std_logic;
	REQ_STB				: out std_logic;
	OBUF_STB				: out std_logic;
	OBUF					: out std_logic_vector(7 downto 0);
	IBUFO					: out std_logic_vector(7 downto 0);
	HALT					: out std_logic;
	ENDPHASE				: out std_logic;
	PC_CEN				: out std_logic;
	ADDR8_O				: out std_logic;
	PRG_CNT				: out std_logic_vector(7 downto 0);
	FLG_REG				: out std_logic_vector(7 downto 0);
	INS_REG				: out std_logic_vector(7 downto 0);
	ACC_REG				: out std_logic_vector(7 downto 0);
	IXREG					: out std_logic_vector(7 downto 0);
	ADR_REG				: out std_logic_vector(7 downto 0);
	DBI_O					: out std_logic_vector(7 downto 0);
	DBO_O					: out std_logic_vector(7 downto 0);
	DATA_RAM_O			: out std_logic_vector(7 downto 0);
	PROG_RAM_O			: out std_logic_vector(7 downto 0);
	PHASE_LED			: out std_logic_vector(4 downto 0);
	OP_LED				: out std_logic;
	DIGIT_SEL			: out std_logic_vector(4 downto 0);
	EX_EN					: in std_logic;
	EX_WR_RD				: in std_logic;
	EX_ADR8				: in std_logic;
	EX_ADDR				: in std_logic_vector(7 downto 0);
	EX_DATA				: in std_logic_vector(7 downto 0)
	);
end component;

-- SYNCHROコンポーネントの宣言
component SYNCHRO
port (
	CLK				: in std_logic;
	RESET				: in std_logic;
	IBUF_STB			: in std_logic;
	REQ_STB_IN		: in std_logic;
	IBUF				: in std_logic_vector(7 downto 0);
	SW_IN				: in std_logic_vector(18 downto 0);
	DATA_SW			: out std_logic_vector(7 downto 0);
	SEL_SW			: out std_logic_vector(3 downto 0);
	EXE				: out std_logic_vector(2 downto 0);
	INC				: out std_logic;
	DEC				: out std_logic;
	SET				: out std_logic;
	DEMO				: out std_logic;
	SEL_MAR			: out std_logic;
	ADDR8_SW			: out std_logic;
	SW_DATA_WE		: out std_logic;
	IBUF_STB_S		: out std_logic;
	REQ_STB_IN_S	: out std_logic;
	IBUF_S			: out std_logic_vector(7 downto 0)
	);
end component;

-- EXE_CTRLコンポーネントの宣言
component EXE_CTRL
port (
	CLK		: in std_logic;
	RESET		: in std_logic;
	CLKEN		: in std_logic;
	HALT		: in std_logic;
	ENDPHASE	: in std_logic;
	EXE		: in std_logic_vector(2 downto 0);
	SP			: out std_logic;
	SI			: out std_logic;
	SS			: out std_logic
	);
end component;

-- DISPLAY_REGコンポーネントの宣言
component DISPLAY_REG
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
	DATA_RAM_Out	: in std_logic_vector(7 downto 0);
	PROG_RAM_Out	: in std_logic_vector(7 downto 0);
	ADDRESS_IN		: in std_logic_vector(7 downto 0);
	ADDR8				: in std_logic;
	DIGIT_SEL		: in std_logic_vector(4 downto 0);
	SEG_O				: out std_logic_vector(6 downto 0)
);
end component;

component EXTENSIONS
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
end component;

-- 内部信号の定義
signal RESET				: std_logic;
signal SP 					: std_logic;
signal SI 					: std_logic;
signal SS 					: std_logic;
signal HALT 				: std_logic;
signal ENDPHASE 			: std_logic;
signal INC 					: std_logic;
signal DEC 					: std_logic;
signal SET 					: std_logic;
signal DEMO 				: std_logic;
signal SEL_MAR 			: std_logic;
signal ADDR8_SW 			: std_logic;
signal CEN					: std_logic;
signal EXE 					: std_logic_vector(2 downto 0);
signal SEL_SW 				: std_logic_vector(3 downto 0);
signal DATA_SW 			: std_logic_vector(7 downto 0);
signal PRG_CNT 			: std_logic_vector(7 downto 0);
signal FLG_REG 			: std_logic_vector(7 downto 0);
signal INS_REG 			: std_logic_vector(7 downto 0);
signal ACC_REG 			: std_logic_vector(7 downto 0);
signal IXREG 				: std_logic_vector(7 downto 0);
signal ADR_REG 			: std_logic_vector(7 downto 0);
signal DBI_O				: std_logic_vector(7 downto 0);
signal DBO_O 				: std_logic_vector(7 downto 0);
signal DATA_RAM_O 		: std_logic_vector(7 downto 0);
signal PROG_RAM_O 		: std_logic_vector(7 downto 0);
signal ADDRESS_IN 		: std_logic_vector(7 downto 0);
signal ADDR8 				: std_logic;
signal SW_DATA_WE			: std_logic;
signal DIGIT_SEL			: std_logic_vector(4 downto 0);
signal IBUF_STB_S 		: std_logic;
signal OBUF_FLG_CLR_S 	: std_logic;
signal IBUF_S 				: std_logic_vector(7 downto 0);
signal REQ_STB_IN_S 		: std_logic;
signal FREQ_CHG 			: std_logic_vector(3 downto 0);
signal PC_CEN				: std_logic;
signal EX_EN				: std_logic;
signal EX_WR_RD			: std_logic;
signal EX_ADR8				: std_logic;
signal EX_ADDR				: std_logic_vector(7 downto 0);
signal EX_DATA				: std_logic_vector(7 downto 0);
signal OBUF_i				: std_logic_vector(7 downto 0);
signal IBUFO_i				: std_logic_vector(7 downto 0);

begin

-- MCUコンポーネントの実体化と入出力の相互接続
	k1: MCU port map(
			SYSCLK => SYSCLK,
			RESET => RESET,
			FREQ_SEL => FREQ_CHG,
			CEN => CEN, 
			DEMO => DEMO,
			SP => SP,
			SI => SI,
			SS => SS,
			SET => SET,
			INC => INC,
			DEC => DEC,
			SEL_MAR => SEL_MAR,
			SW_DATA_WE => SW_DATA_WE,
			DATA_SW => DATA_SW,
			ADDR8_SW => ADDR8_SW,
			IBUF_STB => IBUF_STB_S,
			REQ_STB_IN => REQ_STB_IN_S,
			IBUF => IBUF_S,
			IBUF_FLG_LED => IBUF_FLG_LED,
			OBUF_FLG => OBUF_FLG,
			REQ_STB => REQ_STB,
			OBUF_STB => OBUF_STB,
			OBUF => OBUF_i,
			IBUFO => IBUFO_i,
			HALT => HALT,
			ENDPHASE => ENDPHASE,
			PC_CEN => PC_CEN,
			ADDR8_O => ADDR8,
			PRG_CNT => PRG_CNT,
			FLG_REG => FLG_REG,
			INS_REG => INS_REG,
			ACC_REG => ACC_REG,
			IXREG => IXREG,
			ADR_REG => ADR_REG,
			DBI_O => DBI_O,
			DBO_O => DBO_O,
			DATA_RAM_O => DATA_RAM_O,
			PROG_RAM_O => PROG_RAM_O,
			PHASE_LED => PHASE_LED,
			OP_LED => OP_LED,
			DIGIT_SEL => DIGIT_SEL,
			EX_EN	=> EX_EN,
			EX_WR_RD	=> EX_WR_RD,
			EX_ADR8 => EX_ADR8,
			EX_ADDR => EX_ADDR,
			EX_DATA => EX_DATA			
			);

-- SYNCHROコンポーネントの実体化と入出力の相互接続
	k2: SYNCHRO port map(
			CLK => SYSCLK, 
			RESET => RESET, 
			IBUF_STB	=> IBUF_STB,
			REQ_STB_IN => REQ_STB_IN,
			IBUF => IBUF,
			SW_IN => SW_IN, 
			DATA_SW => DATA_SW, 
			SEL_SW => SEL_SW,
			EXE => EXE, 
			INC => INC, 
			DEC => DEC, 
			SET => SET, 
			DEMO => DEMO, 
			SEL_MAR => SEL_MAR, 
			ADDR8_SW => ADDR8_SW,
			SW_DATA_WE => SW_DATA_WE,
			IBUF_STB_S => IBUF_STB_S,
			REQ_STB_IN_S => REQ_STB_IN_S,
			IBUF_S => IBUF_S
			);

-- EXE_CTRLコンポーネントの実体化と入出力の相互接続			
	k3: EXE_CTRL port map(
			CLK => SYSCLK, 
			RESET => RESET, 
			CLKEN => PC_CEN, 
			HALT => HALT, 
			ENDPHASE => ENDPHASE,
			EXE => EXE, 
			SP => SP, 
			SI => SI, 
			SS => SS
			);

-- DISPLAY_REGコンポーネントの実体化と入出力の相互接続			
	k4: DISPLAY_REG port map(
			CLK => SYSCLK, 
			RESET => RESET, 
			SEL_SW => SEL_SW, 
			PRG_CNT => PRG_CNT, 
			FLAG_REG => FLG_REG,
			INST_REG => INS_REG, 
			ACC_REG => ACC_REG, 
			IX_REG => IXREG, 
			ADR_REG => ADR_REG, 
			DBI => DBI_O,
			DBO => DBO_O, 
			DATA_RAM_OUT => DATA_RAM_O, 
			PROG_RAM_OUT => PROG_RAM_O, 
			ADDRESS_IN => ADR_REG,
			ADDR8 => ADDR8, 
			DIGIT_SEL => DIGIT_SEL, 
			SEG_O => SEG_O
			);

-- EXTENSIONSコンポーネントの実体化と入出力の相互接続
	k5: EXTENSIONS port map(
			CLK => SYSCLK,
			RESET => RESET,
			EN_EX	=> EN_EX,
			AD_DT	=> AD_DT,
			RD_WR	=> RD_WR,
			ADR8 => ADR8,
			AD_BUS => AD_BUS,
			EX_EN	=> EX_EN,
			EX_WR_RD	=> EX_WR_RD,
			EX_ADR8 => EX_ADR8,
			EX_ADDR => EX_ADDR,
			EX_DATA => EX_DATA
			);
	
	RESET <= not (XRESET and XFPGA_RST);
	CEN <= '1';
	FREQ_CHG <= FREQ_SEL(3) & FREQ_SEL(1) & FREQ_SEL(2) & FREQ_SEL(0);
	OBUF <= OBUF_i;
	OBUF_LED <= OBUF_i;
	OBUF_P <= OBUF_i;
	IBUFO_LED <= IBUFO_i;
	IBUFO_P <= IBUFO_i;
	
	-- Inverse digit signal
	SEL_DIGIT(6) <= not DIGIT_SEL(4);
	SEL_DIGIT(5) <= not DIGIT_SEL(3);
	SEL_DIGIT(4) <= not DIGIT_SEL(2);
	SEL_DIGIT(1) <= not DIGIT_SEL(1);
	SEL_DIGIT(0) <= not DIGIT_SEL(0);
	SEL_DIGIT(7) <= '0';
	SEL_DIGIT(3) <= '0';
	SEL_DIGIT(2) <= '0';
	
end rtl; 