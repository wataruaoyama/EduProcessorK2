-- SP phase handshake fix, 2026-10-13; base be0d30e.
--========================================================
--  Project   : AYME0100
--  Outline   : 教育用8ビットマイコン(kue-chip2)FPGA
----------------------------------------------------------
--  File Name : mcu.vhd
--  Function  : マイコンのコアとなるコンポーネント
--  Note      : 
--              
----------------------------------------------------------
--  Date      : Rev.0.9 2024.04.24 Wataru AOYAMA(ANT TECH)
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
entity MCU is
port(
	SYSCLK				: in std_logic;
	RESET					: in std_logic;
	FREQ_SEL				: in std_logic_vector(3 downto 0);
	CEN					: in std_logic;
	DEMO					: in std_logic;
	SP						: in std_logic;
	SP_ACCEPT       : out std_logic;
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
end MCU;

-- 回路の記述
architecture rtl of MCU IS

-- 内部信号の定義
signal CLKEN 			: std_logic;
signal IR_EN 			: std_logic;
signal ACC_EN 			: std_logic;
signal IX_EN 			: std_logic;
signal FLG_EN 			: std_logic;
signal SEL_ALU 		: std_logic;
signal OBUF_EN 		: std_logic;
signal IX_SEL 			: std_logic;
signal MAR_EN			: std_logic;

signal MEMWE 			: std_logic;
signal ADDR8 			: std_logic;

signal IX_ACC 			: std_logic;
signal CIN 				: std_logic;
signal CRRY_FLG 		: std_logic;
signal CFOUT 			: std_logic;
signal FLG_O 			: std_logic_vector(7 downto 0);
signal ADR_MODE 		: std_logic_vector(2 downto 0);
signal OP_CODE 		: std_logic_vector(3 downto 0);
signal CC 				: std_logic_vector(3 downto 0);
signal DBI 				: std_logic_vector(7 downto 0);
signal DBO 				: std_logic_vector(7 downto 0);
signal DBM 				: std_logic_vector(7 downto 0);
signal PC 				: std_logic_vector(7 downto 0);
signal ADR 				: std_logic_vector(7 downto 0);
signal D_IN 			: std_logic_vector(7 downto 0);
signal IR_REG 			: std_logic_vector(7 downto 0);
signal ALU_A 			: std_logic_vector(7 downto 0);
signal ALU_B 			: std_logic_vector(7 downto 0);
signal IX_REG 			: std_logic_vector(7 downto 0);
signal ADR_EN 			: std_logic;--_vector(2 downto 0);
signal SR_MODE 		: std_logic_vector(1 downto 0);
signal MO 				: std_logic_vector(7 downto 0);
signal SHFTO 			: std_logic_vector(7 downto 0);
signal ALUO 			: std_logic_vector(7 downto 0);
signal FETCH_O 		: std_logic_vector(7 downto 0);
signal RAM_O 			: std_logic_vector(7 downto 0);
signal EXE_ALU 		: std_logic;
signal MEM_PC 			: std_logic;
signal ADIX 			: std_logic;
signal RCF 				: std_logic;
signal SCF 				: std_logic;
signal SHFT_EN 		: std_logic;
signal ROT_EN			: std_logic;
signal CFIN				: std_logic;
signal IBUF_FLG_CLR 	: std_logic;
signal IBUF_FLG 		: std_logic;
signal CF_ALU			: std_logic;
signal VF_ALU			: std_logic;
signal NF_ALU			: std_logic;
signal ZF_ALU 			: std_logic;
signal CF_SHFT			: std_logic;
signal VF_SHFT			: std_logic;
signal NF_SHFT			: std_logic;
signal ZF_SHFT 		: std_logic;
signal RAM_WE 			: std_logic;
signal OBUF_FLG_O 	: std_logic;
signal OBUF_FLG_SET 	: std_logic;
signal I_IBUFO 		: std_logic_vector(7 downto 0);
signal IBUF_EN 		: std_logic;
signal DBI_I 			: std_logic_vector(7 downto 0);

signal ADDR8_I			: std_logic;
signal ADDR8_SW_I		: std_logic;
signal ADR_I			: std_logic_vector(7 downto 0);
signal DBM_I			: std_logic_vector(7 downto 0);
signal RAM_WE_I		: std_logic;


-- CLK_GENEコンポーネントの宣言
component CLK_GENE
port(
	SYSCLK	: in std_logic;
	RESET		: in std_logic;
	FREQ_SEL	: in std_logic_vector(3 downto 0);
	CEN		: in std_logic;
	CLK_EN	: out std_logic;
	DIGIT_SEL: out std_logic_vector(4 downto 0)
);
end component;

-- CONTROLコンポーネントの宣言
component CONTROL
port(
	RESET				: in std_logic;                     	-- SYSTEM RESET
	SYSCLK			: in std_logic;
	CLKEN				: in std_logic;
	SP					: in std_logic;
	SP_ACCEPT       : out std_logic;
	SI					: in std_logic;
	SS					: in std_logic;
	CRRY_FLG			: in std_logic;
	OV_FLG			: in std_logic;
	ZERO_FLG			: in std_logic;
	NEG_FLG			: in std_logic;
	OBUF_FLG_O		: in std_logic;
	IBUF_FLG			: in std_logic;
	IX_ACC			: in std_logic;
	ADR_MODE			: in std_logic_vector(2 downto 0);
	OP_CODE			: in std_logic_vector(3 downto 0);
	CC					: in std_logic_vector(3 downto 0);
	DBI				: in std_logic_vector(7 downto 0);
	IR_EN				: out std_logic;
	IX_EN				: out std_logic;
	ACC_EN			: out std_logic;
	FLG_EN			: out std_logic;
	OBUF_EN			: out std_logic;
	IBUF_EN			: out std_logic;
	HALT				: out std_logic;
	MEMWE				: out std_logic;
	ENDPHASE			: out std_logic;
	RCF				: out std_logic;
	SCF				: out std_logic;
	ADDR8				: out std_logic;
	SHFT_EN			: out std_logic;
	ROT_EN			: out std_logic;
	OBUF_FLG_SET	: out std_logic;
	IBUF_FLG_CLR	: out std_logic;
--	OBUF_FLG_CLR	: out std_logic;
	SEL_ALU			: out std_logic;
	EXE_ALU			: out std_logic;
	PC					: out std_logic_vector(7 downto 0);
	ADR_EN			: out std_logic;--_vector(2 downto 0);
	MEM_PC			: out std_logic;
	PHASE_LED		: out std_logic_vector(4 downto 0);
	OP_LED			: out std_logic;
	PC_CEN			: out std_logic
);
end component;

-- ADR_COUNTコンポーネントの宣言
component ADR_COUNT
port(
	SYSCLK	: in std_logic;
	RESET		: in std_logic;
	MAR_EN	: in std_logic;--_vector(2 downto 0);
	SEL		: in std_logic;
	MEM_PC	: in std_logic;
	D_IN		: in std_logic_vector(7 downto 0);
	PC			: in std_logic_vector(7 downto 0);
	IX_REG	: in std_logic_vector(7 downto 0);
	ADIX		: in std_logic;
	SET		: in std_logic;
	INC		: in std_logic;
	DEC		: in std_logic;
	SEL_MAR	: in std_logic;
	DATA_SW	: in std_logic_vector(7 downto 0);
	ADR		: out std_logic_vector(7 downto 0)
);
end component;

-- FETCHコンポーネントの宣言
component FETCH
port(
	SYSCLK	: in std_logic;
	RESET		: in std_logic;
	ADR		: in std_logic_vector(7 downto 0);
	D_OUT		: out std_logic_vector(7 downto 0)
);
end component;

-- INST_REGコンポーネントの宣言
component INST_REG
port(
	SYSCLK	: in std_logic;
	RESET		: in std_logic;
	EN			: in std_logic;
	D_IN		: in std_logic_vector(7 downto 0);
	D_OUT		: out std_logic_vector(7 downto 0)
);
end component;

-- instrDCコンポーネントの宣言
component instrDC
port(
	D			: in std_logic_vector(7 downto 0);
	OP_CODE	: out std_logic_vector(3 downto 0);
	A			: out std_logic;
	B			: out std_logic;
	ADR_MODE	: out std_logic_vector(2 downto 0);
	SR_MODE	: out std_logic_vector(1 downto 0);
	CC			: out std_logic_vector(3 downto 0);
	ADI		: out std_logic
);
end component;

-- USR_REGコンポーネントの宣言
component USR_REG
port(
	CLK		: in std_logic;
	RESET		: in std_logic;
	ACC_EN	: in std_logic;
	IX_EN		: in std_logic;
	SEL1		: in std_logic;	-- IX_ACC
	SEL2		: in std_logic;	-- IX_SEL
	SEL3		: in std_logic;	-- SEL_ALU
	SEL4		: in std_logic;	-- EXE_ALU
	MEMWE		: in std_logic;
	D_IN		: in std_logic_vector(7 downto 0);
	ALU_IN	: in std_logic_vector(7 downto 0);
	A_OUT		: out std_logic_vector(7 downto 0);
	B_OUT		: out std_logic_vector(7 downto 0);
	IREG		: out std_logic_vector(7 downto 0);
	ACCREG	: out std_logic_vector(7 downto 0);
	MO			: out std_logic_vector(7 downto 0)
);
end component;

-- ALUコンポーネントの宣言
component ALU
port(
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
end component;

-- FLAG_REGコンポーネントの宣言
component FLAG_REG
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
end component;

-- SHIFTERコンポーネントの宣言
component SHIFTER
port(
	SYSCLK	: in std_logic;
	RESET		: in std_logic;
	SHFT_EN	: in std_logic;
	ROT_EN	: in std_logic;
	CFIN		: in std_logic;
	DATA_IN	: in std_logic_vector(7 downto 0);
	SR_MODE	: in std_logic_vector(1 downto 0);
	DATA_OUT	: out std_logic_vector(7 downto 0);
	CF_SHFT	: out std_logic;
	VF_SHFT	: out std_logic;
	NF_SHFT	: out std_logic;
	ZF_SHFT	: out std_logic
);
end component;

-- IOBUFコンポーネントの宣言
component IOBUF
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
end component;

-- MEM_CTRLコンポーネントの宣言
component MEM_CTRL
port(
	CLK			: in std_logic;
	DEMO			: in std_logic;
	ADDR8			: in std_logic;
	ADDR8_SW		: in std_logic;
	ADR			: in std_logic_vector(7 downto 0);
	MEMWE			: in std_logic;
	DATA_I		: in std_logic_vector(7 downto 0);
	DATA_O		: out std_logic_vector(7 downto 0);
	DATA_RAM_O	: out std_logic_vector(7 downto 0);
	PROG_RAM_O	: out std_logic_vector(7 downto 0)
);
end component;

begin

-- CLK_GENEコンポーネントの実体化と入出力の相互接続
	u1: CLK_GENE port map(
		SYSCLK => SYSCLK, 
		RESET => RESET, 
		FREQ_SEL => FREQ_SEL, 
		CEN => CEN, 
		CLK_EN => CLKEN, 
		DIGIT_SEL => DIGIT_SEL
		);

-- CONTROLコンポーネントの実体化と入出力の相互接続		
	u2: CONTROL port map(
		RESET => RESET, 
		SYSCLK => SYSCLK, 
		CLKEN => CLKEN, 
		SP => SP,
		SP_ACCEPT => SP_ACCEPT, 
		SI => SI, 
		SS => SS,
		CRRY_FLG => CFOUT, 
		OV_FLG => FLG_O(2),
		ZERO_FLG => FLG_O(0), 
		NEG_FLG => FLG_O(1), 
		OBUF_FLG_O => OBUF_FLG_O,
		IBUF_FLG => IBUF_FLG,
		IX_ACC => IX_ACC, 
		ADR_MODE => ADR_MODE, 
		OP_CODE => OP_CODE, 
		CC => CC,
		DBI => DBI, 
		IR_EN => IR_EN, 
		IX_EN => IX_EN,
		ACC_EN => ACC_EN, 
		FLG_EN => FLG_EN, 
		OBUF_EN => OBUF_EN, 
		IBUF_EN => IBUF_EN,
		HALT => HALT, 
		MEMWE => MEMWE, 
		ENDPHASE => ENDPHASE, 
		RCF => RCF, 
		SCF => SCF, 
		ADDR8 => ADDR8, 
		SHFT_EN => SHFT_EN,
		ROT_EN => ROT_EN, 
		OBUF_FLG_SET => OBUF_FLG_SET,
		IBUF_FLG_CLR => IBUF_FLG_CLR, 
		SEL_ALU => SEL_ALU, 
		EXE_ALU => EXE_ALU, 
		PC => PC, 
		ADR_EN => ADR_EN,
		MEM_PC => MEM_PC, 
		PHASE_LED => PHASE_LED,
		OP_LED => OP_LED,
		PC_CEN => PC_CEN
		);

-- ADR_COUNTコンポーネントの実体化と入出力の相互接続		
	u3: ADR_COUNT port map(
		SYSCLK => SYSCLK, 
		RESET => RESET, 
		MAR_EN => ADR_EN, 
		SEL => SEL_ALU, 
		MEM_PC => MEM_PC,
		D_IN => DBI,
		PC => PC, 
		IX_REG => IX_REG, 
		ADIX => ADIX, 
		SET => SET, 
		INC => INC,
		DEC => DEC, 
		SEL_MAR => SEL_MAR, 
		DATA_SW => DATA_SW, 
		ADR => ADR
		);

-- FETCHコンポーネントの実体化と入出力の相互接続		
	u4: FETCH port map(
		SYSCLK => SYSCLK, 
		RESET => RESET, 
		ADR => ADR, 
		D_OUT => FETCH_O
		);

-- INST_REGコンポーネントの実体化と入出力の相互接続	
	u5: INST_REG port map(
		SYSCLK => SYSCLK, 
		RESET => RESET, 
		EN => IR_EN, 
		D_IN => DBI, 
		D_OUT => IR_REG
		);

-- instrDCコンポーネントの実体化と入出力の相互接続	
	u6: instrDC port map(
		D => IR_REG, 
		OP_CODE => OP_CODE, 
		A => IX_ACC, 
		B => IX_SEL, 
		ADR_MODE => ADR_MODE, 
		SR_MODE => SR_MODE, 
		CC => CC, 
		ADI => ADIX
		);

-- USR_REGコンポーネントの実体化と入出力の相互接続		
	u7: USR_REG port map(
		CLK => SYSCLK, 
		RESET => RESET, 
		ACC_EN => ACC_EN, 
		IX_EN => IX_EN, 
		SEL1 => IX_ACC, 
		SEL2 => IX_SEL,
		SEL3 => SEL_ALU, 
		SEL4 => EXE_ALU, 
		MEMWE => MEMWE, 
		D_IN => DBI, 
		ALU_IN => DBO, 
		A_OUT => ALU_A, 
		B_OUT => ALU_B, 
		IREG => IX_REG, 
		ACCREG => ACC_REG, 
		MO => MO
		);

-- ALUコンポーネントの実体化と入出力の相互接続		
	u8: ALU port map(
		CLK => SYSCLK, 
		RESET => RESET, 
		CLKEN => CLKEN, 
		A => ALU_A, 
		B => ALU_B, 
		M => OP_CODE, 
		ADR_MODE => ADR_MODE, 
		CIN => FLG_O(3), 
		O => ALUO, 
		CF_ALU => CF_ALU, 
		VF_ALU => VF_ALU, 
		NF_ALU => NF_ALU, 
		ZF_ALU => ZF_ALU
		);

-- FLAG_REGコンポーネントの実体化と入出力の相互接続		
	u9: FLAG_REG port map(
		SYSCLK => SYSCLK, 
		RESET => RESET, 
		CKEN => FLG_EN, 
		EXE_ALU => EXE_ALU, 
		SHFT_EN => SHFT_EN, 
		ROT_EN => ROT_EN,
		CF_ALU => CF_ALU, 
		VF_ALU => VF_ALU,
		NF_ALU => NF_ALU, 
		ZF_ALU => ZF_ALU,
		RCF => RCF, 
		SCF => SCF, 
		CF_SHFT => CF_SHFT, 
		VF_SHFT => VF_SHFT, 
		NF_SHFT => NF_SHFT, 
		ZF_SHFT => ZF_SHFT,
		OP_CODE => OP_CODE,
		CFOUT => CFOUT, 
		d_OUT => FLG_O
		);

-- SHIFTERコンポーネントの実体化と入出力の相互接続		
	u10: SHIFTER port map(
		SYSCLK => SYSCLK, 
		RESET => RESET, 
		SHFT_EN => SHFT_EN, 
		ROT_EN => ROT_EN, 
		CFIN=> CFOUT, 
		DATA_in => mo, 
		SR_MODE => SR_MODE,
		DATA_OUT => SHFTO, 
		CF_SHFT => CF_SHFT, 
		VF_SHFT => VF_SHFT, 
		NF_SHFT => NF_SHFT, 
		ZF_SHFT => ZF_SHFT
		);

-- IOBUFコンポーネントの実体化と入出力の相互接続		
	u11: IOBUF port map(
		SYSCLK => SYSCLK,
		RESET	=> RESET,
		OBUF_EN => OBUF_EN,
		OBUF_FLG_SET => OBUF_FLG_SET,
--		OBUF_FLG_clr => OBUF_FLG_clr,
		--
		OBUF_FLG_O => OBUF_FLG_O,
		REQ_STB_IN => REQ_STB_IN,
		OBUF_STB_O => OBUF_STB,
		OBUF => OBUF,
		--
--		OBUF_FLG_in => OBUF_FLG_in,
		REQ_STB => REQ_STB,
		OBUF_STB_IN => IBUF_STB,
		IBUF => IBUF,
		--
		IBUF_FLG => IBUF_FLG,
		IBUF_FLG_CLR => IBUF_FLG_CLR,
		DBO => DBO,
		IBUFO => I_IBUFO
		);

-- MEM_CTRLコンポーネントの実体化と入出力の相互接続		
	u12: MEM_CTRL port map(
		CLK => SYSCLK,
		DEMO => DEMO,
		ADDR8 => ADDR8_I,
		ADDR8_SW => ADDR8_SW_I,
		ADR => ADR_I,
		MEMWE => RAM_WE_I,
		DATA_I => DBM_I,
		DATA_O => RAM_O,
		DATA_RAM_O => DATA_RAM_O,
		PROG_RAM_O => PROG_RAM_O
		);

	-- 拡張モジュールの選択回路
	ADDR8_I <= ADDR8 when EX_EN = '1' else EX_ADR8;
	ADDR8_SW_I <= ADDR8_SW when EX_EN = '1' else '0';
	ADR_I <= ADR when EX_EN = '1' else EX_ADDR;
	DBM_I <= DBM when EX_EN ='1' else EX_DATA;
	RAM_WE_I <= RAM_WE when EX_EN ='1' else EX_WR_RD;
	--
	
	RAM_WE <= MEMWE or SW_DATA_WE;

	DBO <= SHFTO when (SHFT_EN = '1' or ROT_EN = '1') else ALUO;
	DBM <= DATA_SW when SW_DATA_WE = '1' else DBO;
	DBI_I <= FETCH_O when (DEMO = '1' and ADDR8 = '0') else 
			 RAM_O;
	DBI <= I_IBUFO when IBUF_EN = '1' else
			 DBI_I;
	
	IBUF_FLG_LED <= IBUF_FLG;
	
	ADDR8_O <= ADDR8 or ADDR8_SW;
	PRG_CNT <= PC;
	FLG_REG <= FLG_O;
	INS_REG <= IR_REG;
	IXREG <= IX_REG;
	ADR_REG <= ADR;
	DBI_O <= DBI;
	DBO_O <= DBM;
	
	OBUF_FLG <= OBUF_FLG_O;
	IBUFO <= I_IBUFO;
	
end rtl;