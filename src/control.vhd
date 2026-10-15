-- SP phase handshake fix, 2026-10-13; base be0d30e.
--========================================================
--  Project   : AYME0100
--  Outline   : 教育用8ビットマイコン(kue-chip2)FPGA
----------------------------------------------------------
--  File Name : control.vhd
--  Function  : 制御信号を生成するコンポーネント
--  Note      : 
--              
----------------------------------------------------------
--  Date      : Rev.0.9 2024.04.24 Wataru AOYAMA(ANR TECH)
--  Update    :
--========================================================
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use WORK.all;

-- 入出力の宣言
entity CONTROL is
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
	SEL_ALU			: out std_logic;
	EXE_ALU			: out std_logic;
	PC					: out std_logic_vector(7 downto 0);
	ADR_EN			: out std_logic;
	MEM_PC			: out std_logic;
	PHASE_LED		: out std_logic_vector(4 downto 0);
	OP_LED			: out std_logic;
	PC_CEN			: out std_logic
);
end CONTROL;

-- 回路の記述
architecture rtl OF CONTROL is

-- 内部信号の定義
signal PC_COUNT		: std_logic_vector(7 downto 0);
signal PC_EN			: std_logic;
signal HLT				: std_logic;
signal PHASECUT		: std_logic;
signal PC_LATCH_EN	: std_logic;
signal DELAY			: std_logic;
signal DFF				: std_logic_vector(2 downto 0);
signal PHASE_RUN    : std_logic;
signal ACCEPT_I     : std_logic;
signal MAR_EN			: std_logic;
signal PC_CEN_i		: std_logic;

type states IS (IDLE,P0,P1,P2,P3,P4);
signal PRESENT_PHASE: states;
signal NEXT_PHASE: states;

begin
	-----------------
	-- State machine
	-----------------
    -- CLKEN is a SYSCLK-domain enable, never a clock.
    -- Keep the accepted grant through the delayed PC/MAR update.
    ACCEPT_I <= CLKEN and (SP or SI or SS);
    SP_ACCEPT <= CLKEN and SP;

    process(SYSCLK, RESET)
    begin
        if RESET = '1' then
            PRESENT_PHASE <= IDLE;
            PHASE_RUN <= '0';
        elsif rising_edge(SYSCLK) then
            if CLKEN = '1' then
                PHASE_RUN <= ACCEPT_I;
                if ACCEPT_I = '1' then
                    PRESENT_PHASE <= NEXT_PHASE;
                end if;
            end if;
        end if;
    end process;

	process(PRESENT_PHASE, PHASECUT, HLT) begin
		case PRESENT_PHASE is
			when IDLE =>
				NEXT_PHASE <= P0;
			when P0 =>
				NEXT_PHASE <= P1;

			when P1 =>
				NEXT_PHASE <= P2;
				
			when P2 =>
				if (PHASECUT = '1') then
					NEXT_PHASE <= P0;
				else
					NEXT_PHASE <= P3;
				end if;
				
			when P3 =>
				if (PHASECUT = '1') then
					NEXT_PHASE <= P0;
				else
					NEXT_PHASE <= P4;
				end if;
				
			when P4 =>
				if (HLT = '1') then
					NEXT_PHASE <= P4;
				else
					NEXT_PHASE <= P0;
				end if;

			when others =>
				null;
		end case;
	end process;

	process(SYSCLK, RESET) begin
		if (RESET = '1') then
			MAR_EN <= '0';
			HLT <= '0';
			IR_EN	<= '0';
			ACC_EN <= '0';
			IX_EN <= '0';
			FLG_EN <= '0';
			OBUF_EN <= '0';
			IBUF_EN <= '0';
			RCF <= '0';
			SCF <= '0';
			PHASECUT <= '0';
			SHFT_EN <= '0';
			ROT_EN <= '0';
			SEL_ALU <= '1';
			MEM_PC <= '0';
			EXE_ALU <= '0';
			PC_EN <= '0';
			MEMWE <= '0';
			ADDR8 <= '0';
			OBUF_FLG_SET <= '0';
			IBUF_FLG_CLR <= '0';
			
		elsif (SYSCLK'event and SYSCLK = '1') then
				if (PRESENT_PHASE = P0) then
					MAR_EN <= '1';
					PHASECUT <= '0';
					FLG_EN <= '0';
					RCF <= '0';
					SCF <= '0';
					ACC_EN <= '0';
					IX_EN <= '0';
					SEL_ALU <= '1';
					ADDR8 <= '0';
					EXE_ALU <= '0';
					PC_EN <= '0';
					SHFT_EN <= '0';
					ROT_EN <= '0';
					MEM_PC <= '0';
					MEMWE <= '0';
					HLT <= '0';
					OBUF_FLG_SET <= '0';
					IBUF_FLG_CLR <= '0';
				end if;
				
				
				if (PRESENT_PHASE = P1) then
					MAR_EN <= '0';
					IR_EN <= '1';
					case OP_CODE is
						when "0110" =>
							if (ADR_MODE = "000" or ADR_MODE = "001") then
								SEL_ALU <= '1';
							end if;
						
						when "1000" =>
							if (ADR_MODE = "001" or ADR_MODE = "010") then
								SEL_ALU <= '1';
								EXE_ALU <= '0';
							end if;
							
						when "1001" =>
							if (ADR_MODE = "001" or ADR_MODE = "010") then
								SEL_ALU <= '1';
								EXE_ALU <= '0';
							end if;
							
						when "1010" =>
							if (ADR_MODE = "001" or ADR_MODE = "010") then
								SEL_ALU <= '1';
								EXE_ALU <= '0';
							end if;
							
						when "1011" =>
							if (ADR_MODE = "001" or ADR_MODE = "010") then
								SEL_ALU <= '1';
								EXE_ALU <= '0';
							end if;
							
						when "1100" =>
							if (ADR_MODE = "001" or ADR_MODE = "010") then
								SEL_ALU <= '1';
								EXE_ALU <= '0';
							end if;
							
						when "1101" =>
							if (ADR_MODE = "001" or ADR_MODE = "010") then
								SEL_ALU <= '1';
								EXE_ALU <= '0';
							end if;
							
						when "1110" =>
							if (ADR_MODE = "001" or ADR_MODE = "010") then
								SEL_ALU <= '1';
								EXE_ALU <= '0';
							end if;
							
						when "1111" =>
							if (ADR_MODE = "001" or ADR_MODE = "010") then
								SEL_ALU <= '1';
								EXE_ALU <= '0';
							end if;
							
						when others =>
							SEL_ALU <= '1';
							EXE_ALU <= '0';
					end case;
				end if;
				
				
				if (PRESENT_PHASE = P2) then
					IR_EN <= '0';
					case OP_CODE is
						when "0000" =>
							if (IX_ACC = '0') then		-- NOP
								PHASECUT <= '1';
							else								-- HLT
								HLT <= '1';
							end if;
							
						when "0001" =>
							if (IX_ACC = '0') then		-- OUT
								OBUF_EN <= '1';
								SEL_ALU <= '0';
							else								-- IN
								ACC_EN <= '1';
								IBUF_EN <= '1';
							end if;
							
						when "0010" =>
							if (IX_ACC = '0') then		-- RCF
								RCF <= '1';
							else								-- SCF
								SCF <= '1';
							end if;
							PHASECUT <= '1';
							
						when "0011" =>						-- Bcc
							MAR_EN <= '1';
							
						when "0100" =>
							if (ADR_MODE(2) = '0') then	-- shft
								SHFT_EN <= '1';
								if(IX_ACC = '0') then
									ACC_EN <= '1';
								else
									IX_EN <= '1';
								end if;
							else								-- ROTATE
								ROT_EN <= '1';
								if (IX_ACC = '0') then
									ACC_EN <= '1';
								else
									IX_EN <= '1';
								end if;
							end if;
							
						when "0110" =>						-- LD
							if (ADR_MODE = "000" or ADR_MODE = "001") then
								SEL_ALU <= '0';
								if (IX_ACC = '0') then
									ACC_EN <= '1';
								else
									IX_EN <= '1';
								end if;
								PHASECUT <= '1';
							elsif (ADR_MODE = "010" or ADR_MODE = "011") then
								SEL_ALU <= '1';
								MAR_EN <= '1';
							elsif (ADR_MODE > "011") then
								MEM_PC <= '1';
								MAR_EN <= '1';
								EXE_ALU <= '0';
								SEL_ALU <= '1';
							end if;
							
						when "0111" =>						-- ST
							MAR_EN <= '1';
							if (ADR_MODE = "100" or ADR_MODE = "101") then
								MEM_PC <= '1';
							elsif (ADR_MODE = "110" or ADR_MODE = "111") then
								MEM_PC <= '1';
								EXE_ALU <= '0';
								SEL_ALU <= '1';
							end if;
							
						-- SBC, ADC, SUB, ADD
						when "1000" =>						-- SBC
							if (ADR_MODE = "000" or ADR_MODE = "001") then
								EXE_ALU <= '1';
								SEL_ALU <= '0';
								FLG_EN <= '1';
								if (IX_ACC = '0') then
									ACC_EN <= '1';
								else
									IX_EN <= '1';
								end if;
								PHASECUT <= '1';
							elsif (ADR_MODE = "010" or ADR_MODE = "011") then
								MAR_EN <= '1';
--								MEM_PC <= '0';
							elsif (ADR_MODE > "011") then
								MAR_EN <= '1';
								MEM_PC <= '1';
							end if;
							
						when "1001" =>						-- ADC
							if (ADR_MODE = "000" or ADR_MODE = "001") then
								EXE_ALU <= '1';
								SEL_ALU <= '0';
								FLG_EN <= '1';
								if (IX_ACC = '0') then
									ACC_EN <= '1';
								else
									IX_EN <= '1';
								end if;
								PHASECUT <= '1';
							else
								MAR_EN <= '1';
								MEM_PC <= '1';
							end if;
							
						when "1010" =>						-- SUB
							if (ADR_MODE = "000" or ADR_MODE = "001") then
								EXE_ALU <= '1';
								SEL_ALU <= '0';
								FLG_EN <= '1';
								if (IX_ACC = '0') then
									ACC_EN <= '1';
								else
									IX_EN <= '1';
								end if;
								PHASECUT <= '1';
							else
								MAR_EN <= '1';
								MEM_PC <= '1';
							end if;
							
						when "1011" =>						-- ADD
							if (ADR_MODE = "000" or ADR_MODE = "001") then
								EXE_ALU <= '1';
								SEL_ALU <= '0';
								FLG_EN <= '1';
								if (IX_ACC = '0') then
									ACC_EN <= '1';
								else
									IX_EN <= '1';
								end if;
								PHASECUT <= '1';
							else
								MAR_EN <= '1';
								MEM_PC <= '1';
							end if;
							
						-- EOR, OR, AND, CMP
						when "1100" =>						-- EOR
							if (ADR_MODE = "000" or ADR_MODE = "001") then
								EXE_ALU <= '1';
								SEL_ALU <= '0';
								FLG_EN <= '1';
								if (IX_ACC = '0') then
									ACC_EN <= '1';
								else
									IX_EN <= '1';
								end if;
								PHASECUT <= '1';
							else
								MAR_EN <= '1';
								MEM_PC <= '1';
							end if;

						when "1101" =>						-- OR
							if (ADR_MODE = "000" or ADR_MODE = "001") then
								EXE_ALU <= '1';
								SEL_ALU <= '0';
								FLG_EN <= '1';
								if (IX_ACC = '0') then
									ACC_EN <= '1';
								else
									IX_EN <= '1';
								end if;
								PHASECUT <= '1';
							else
								MAR_EN <= '1';
								MEM_PC <= '1';
							end if;

						when "1110" =>						-- AND
							if (ADR_MODE = "000" or ADR_MODE = "001") then
								EXE_ALU <= '1';
								SEL_ALU <= '0';
								FLG_EN <= '1';
								if (IX_ACC = '0') then
									ACC_EN <= '1';
								else
									IX_EN <= '1';
								end if;
								PHASECUT <= '1';
							else
								MAR_EN <= '1';
								MEM_PC <= '1';
							end if;

						when "1111" =>						-- CMP
							if (ADR_MODE = "000" or ADR_MODE = "001") then
								EXE_ALU <= '1';
								SEL_ALU <= '0';
								FLG_EN <= '1';
								PHASECUT <= '1';
							else
								MAR_EN <= '1';
								MEM_PC <= '1';
							end if;

						when others =>
							null;
					end case;
				end if;
					
					
				if (PRESENT_PHASE = P3) then
					MEM_PC <= '0';
					case OP_CODE is
						when "0001" =>
							if (IX_ACC = '0') then						-- OUT
								OBUF_FLG_SET <= '1';
								OBUF_EN <= '0';
								SEL_ALU <= '1';
							else												-- IN
								IBUF_FLG_CLR <= '1';
								ACC_EN <= '0';
								IBUF_EN <= '0';
							end if;
							PHASECUT <= '1';
							
						when "0011" =>										-- Bcc
							MAR_EN <= '0';
							if (cc = "0000") then							-- Always(A)
								PC_EN <= '1';
								MEM_PC <= '1';
							elsif (cc = "1000") then						-- on oVer Flow(VF)
								if (OV_FLG = '1') then
									PC_EN <= '1';
									MEM_PC <= '1';
								end if;
							elsif (cc = "0001") then						-- on Not Zero(NZ)
								if (ZERO_FLG = '0') then
									PC_EN <= '1';
									MEM_PC <= '1';
								end if;
							elsif (cc = "1001") then						-- on Zero(Z)
								if (ZERO_FLG = '1') then
									PC_EN <= '1';
									MEM_PC <= '1';
								end if;
							elsif (cc = "0010") then						-- on Zero or Positive(ZP)
								if (NEG_FLG = '0') then
									PC_EN <= '1';
									MEM_PC <= '1';
								end if;
							elsif (cc = "1010") then						-- on Negative(N)
								if (NEG_FLG = '1') then
									PC_EN <= '1';
									MEM_PC <= '1';
								end if;
							elsif (cc = "0011") then						-- on Positive(P)
								if ((NEG_FLG or ZERO_FLG) = '0') then
									PC_EN <= '1';
									MEM_PC <= '1';
								end if;
							elsif (cc = "1011") then						-- on Zero or Negative(ZN)
								if((NEG_FLG or ZERO_FLG) = '1') then
									PC_EN <= '1';
									MEM_PC <= '1';
								end if;
							elsif (cc = "0100") then						-- on No Input
								if (IBUF_FLG = '0') then
									PC_EN <= '1';
									MEM_PC <= '1';
								end if;
							elsif (cc = "1100") then						-- on No Output
								if (OBUF_FLG_O = '1') then
									PC_EN <= '1';
									MEM_PC <= '1';
								end if;
							elsif (cc = "0101") then						-- on No Carry
								if (CRRY_FLG = '0') then
									PC_EN <= '1';
									MEM_PC <= '1';
								end if;
							elsif (cc = "1101") then						-- on Carry
								if (CRRY_FLG = '1') then
									PC_EN <= '1';
									MEM_PC <= '1';
								end if;
							elsif (cc = "0110") then						-- on Greater than or Equal
								if ((OV_FLG xor NEG_FLG) = '0') then
									PC_EN <= '1';
									MEM_PC <= '1';
								end if;
							elsif (cc = "1110") then						-- on LeSS than
								if ((OV_FLG xor NEG_FLG) = '1') then
									PC_EN <= '1';
									MEM_PC <= '1';
								end if;
							elsif (cc = "0111") then						-- on Greater than
								if (((OV_FLG xor NEG_FLG) or ZERO_FLG) = '0') then
									PC_EN <= '1';
									MEM_PC <= '1';
								end if;
							elsif (cc = "1111") then						-- on LeSS than or Equal
								if (((OV_FLG xor NEG_FLG) or ZERO_FLG) = '1') then
									PC_EN <= '1';
									MEM_PC <= '1';
								end if;
							end if;
							PHASECUT <= '1';
							
						when "0100" =>										-- shft/ROTATE
							FLG_EN <= '1';
							PHASECUT <= '1';
							
						when "0110" =>										-- LD
							MEM_PC <= '0';
							if (ADR_MODE = "000" or ADR_MODE = "001") then
								SEL_ALU <= '1';
							elsif (ADR_MODE = "010" or ADR_MODE = "011") then
								MAR_EN <= '0';
								PHASECUT <= '1';
								if (IX_ACC = '0') then
									ACC_EN <= '1';
								else
									IX_EN <= '1';
								end if;
							elsif (ADR_MODE = "100") then
							elsif (ADR_MODE = "101") then
							elsif (ADR_MODE = "110") then
								EXE_ALU <= '0';
							elsif (ADR_MODE = "111") then
								EXE_ALU <= '0';
							end if;
							
						when "0111" =>										-- ST
							MEM_PC <= '0';
							if (ADR_MODE = "100") then
							elsif (ADR_MODE = "101") then
							elsif (ADR_MODE = "110") then
								SEL_ALU <= '1';
								EXE_ALU <= '0';
							elsif (ADR_MODE = "111") then
								EXE_ALU <= '0';
							end if;
							
						-- SBC, ADC, SUB, ADD
						when "1000"  =>
							EXE_ALU <= '1';
							if (ADR_MODE = "000" or ADR_MODE = "001") then
								SEL_ALU <= '0';
							elsif (ADR_MODE = "010" or ADR_MODE = "011") then
								MAR_EN <= '0';
								FLG_EN <= '1';
								PHASECUT <= '1';
								EXE_ALU <= '1';
								if (IX_ACC = '0') then
									ACC_EN <= '1';
								else
									IX_EN <= '1';
								end if;
							elsif (ADR_MODE = "100") then
							elsif (ADR_MODE = "101") then
							elsif (ADR_MODE = "110") then
							elsif (ADR_MODE = "111") then
							end if;
							
						when "1001" =>
							EXE_ALU <= '1';
							if (ADR_MODE = "000" or ADR_MODE = "001") then
								SEL_ALU <= '0';
							elsif (ADR_MODE = "010" or ADR_MODE = "011") then
								MAR_EN <= '0';
								FLG_EN <= '1';
								PHASECUT <= '1';
								EXE_ALU <= '1';
								if (IX_ACC = '0') then
									ACC_EN <= '1';
								else
									IX_EN <= '1';
								end if;
							elsif (ADR_MODE = "100") then
							elsif (ADR_MODE = "101") then
							elsif (ADR_MODE = "110") then
							elsif (ADR_MODE = "111") then
							end if;
							
						when "1010" =>
							EXE_ALU <= '1';
							if (ADR_MODE = "000" or ADR_MODE = "001") then
								SEL_ALU <= '0';
							elsif (ADR_MODE = "010" or ADR_MODE = "011") then
								MAR_EN <= '0';
								FLG_EN <= '1';
								PHASECUT <= '1';
								EXE_ALU <= '1';
								if (IX_ACC = '0') then
									ACC_EN <= '1';
								else
									IX_EN <= '1';
								end if;
							elsif (ADR_MODE = "100") then
							elsif (ADR_MODE = "101") then
							elsif (ADR_MODE = "110") then
							elsif (ADR_MODE = "111") then
							end if;
							
						when "1011" =>
							EXE_ALU <= '1';
							if (ADR_MODE = "000" or ADR_MODE = "001") then
								SEL_ALU <= '0';
							elsif (ADR_MODE = "010" or ADR_MODE = "011") then
								MAR_EN <= '0';
								FLG_EN <= '1';
								PHASECUT <= '1';
								EXE_ALU <= '1';
								if (IX_ACC = '0') then
									ACC_EN <= '1';
								else
									IX_EN <= '1';
								end if;
							elsif (ADR_MODE = "100") then
							elsif (ADR_MODE = "101") then
							elsif (ADR_MODE = "110") then
							elsif (ADR_MODE = "111") then
							end if;
							
						-- EOR, OR, AND, CMP	
						when "1100" =>
							EXE_ALU <= '1';
							if (ADR_MODE = "010" or ADR_MODE = "011") then
								MAR_EN <= '0';
								FLG_EN <= '1';
								PHASECUT <= '1';
								EXE_ALU <= '1';
								if (IX_ACC = '0') then
									ACC_EN <= '1';
								else
									IX_EN <= '1';
								end if;
							elsif (ADR_MODE = "100") then
							elsif (ADR_MODE = "101") then
							elsif (ADR_MODE = "110") then
							elsif (ADR_MODE = "111") then
							end if;
							
						when "1101" =>
							EXE_ALU <= '1';
							if (ADR_MODE = "010" or ADR_MODE = "011") then
								MAR_EN <= '0';
								FLG_EN <= '1';
								PHASECUT <= '1';
								EXE_ALU <= '1';
								if (IX_ACC = '0') then
									ACC_EN <= '1';
								else
									IX_EN <= '1';
								end if;
							elsif (ADR_MODE = "100") then
							elsif (ADR_MODE = "101") then
							elsif (ADR_MODE = "110") then
							elsif (ADR_MODE = "111") then
							end if;
							
						when "1110" =>
							EXE_ALU <= '1';
							if (ADR_MODE = "010" or ADR_MODE = "011") then
								MAR_EN <= '0';
								FLG_EN <= '1';
								PHASECUT <= '1';
								EXE_ALU <= '1';
								if (IX_ACC = '0') then
									ACC_EN <= '1';
								else
									IX_EN <= '1';
								end if;
							elsif (ADR_MODE = "100") then
							elsif (ADR_MODE = "101") then
							elsif (ADR_MODE = "110") then
							elsif (ADR_MODE = "111") then
							end if;
							
						when "1111" =>
							EXE_ALU <= '1';
							if (ADR_MODE = "010" or ADR_MODE = "011") then
								MAR_EN <= '0';
								FLG_EN <= '1';
								PHASECUT <= '1';
								EXE_ALU <= '1';
							elsif (ADR_MODE = "100") then
							elsif (ADR_MODE = "101") then
							elsif (ADR_MODE = "110") then
							elsif (ADR_MODE = "111") then
							end if;
							
						when others =>
							null;
					end case;
				end if;
					
					
				if (PRESENT_PHASE = P4) then
					PHASECUT <= '1';
					case OP_CODE is
						when "0110" =>							-- LD
							MAR_EN <= '0';
							EXE_ALU <= '0';
							if (IX_ACC = '0') then
								ACC_EN <= '1';
							else
								IX_EN <= '1';
							end if;
							if (ADR_MODE = "101" or ADR_MODE = "111") then
								ADDR8 <= '1';
							elsif (ADR_MODE = "100" or ADR_MODE = "110") then
								ADDR8 <= '0';
							end if;
							
						when "0111" =>							-- ST
							MEMWE <= '1';
							MAR_EN <= '0';
							EXE_ALU <= '0';
							SEL_ALU <= '0';
							if (ADR_MODE = "111" or ADR_MODE = "101") then
								ADDR8 <= '1';
							end if;
						
						-- SBC, ADC, SUB, ADD
						when "1000" =>												-- SBC
							FLG_EN <= '1';
							MAR_EN <= '0';
							EXE_ALU <= '1';
							if (IX_ACC = '0') then
								ACC_EN <= '1';
							else
								IX_EN <= '1';
							end if;
							if (ADR_MODE = "100" or ADR_MODE = "110") then
								ADDR8 <= '0';
							elsif (ADR_MODE = "101" or ADR_MODE = "111") then
								ADDR8 <= '1';
							end if;
							
						when "1001" =>												-- ADC
							FLG_EN <= '1';
							MAR_EN <= '0';
							EXE_ALU <= '1';
							if (IX_ACC = '0') then
								ACC_EN <= '1';
							else
								IX_EN <= '1';
							end if;
							if (ADR_MODE = "100" or ADR_MODE = "110") then
								ADDR8 <= '0';
							elsif (ADR_MODE = "101" or ADR_MODE = "111") then
								ADDR8 <= '1';
							end if;
							
						when "1010" =>												-- SUB
							FLG_EN <= '1';
							MAR_EN <= '0';
							EXE_ALU <= '1';
							if (IX_ACC = '0') then
								ACC_EN <= '1';
							else
								IX_EN <= '1';
							end if;
							if (ADR_MODE = "100" or ADR_MODE = "110") then
								ADDR8 <= '0';
							elsif (ADR_MODE = "101" or ADR_MODE = "111") then
								ADDR8 <= '1';
							end if;
							
						when "1011" =>												-- ADD
							FLG_EN <= '1';
							MAR_EN <= '0';
							EXE_ALU <= '1';
							if (IX_ACC = '0') then
								ACC_EN <= '1';
							else
								IX_EN <= '1';
							end if;
							if (ADR_MODE = "100" or ADR_MODE = "110") then
								ADDR8 <= '0';
							elsif (ADR_MODE = "101" or ADR_MODE = "111") then
								ADDR8 <= '1';
							end if;
							
						-- EOR, OR, AND, CMP
						when "1100" =>												-- EOR
							FLG_EN <= '1';
							MAR_EN <= '0';
							EXE_ALU <= '1';
							if (IX_ACC = '0') then
								ACC_EN <= '1';
							else
								IX_EN <= '1';
							end if;
							if (ADR_MODE = "100" or ADR_MODE = "110") then
								ADDR8 <= '0';
							elsif (ADR_MODE = "101" or ADR_MODE = "111") then
								ADDR8 <= '1';
							end if;
							
						when "1101" =>												-- OR
							FLG_EN <= '1';
							MAR_EN <= '0';
							EXE_ALU <= '1';
							if (IX_ACC = '0') then
								ACC_EN <= '1';
							else
								IX_EN <= '1';
							end if;
							if (ADR_MODE = "100" or ADR_MODE = "110") then
								ADDR8 <= '0';
							elsif (ADR_MODE = "101" or ADR_MODE = "111") then
								ADDR8 <= '1';
							end if;
							
						when "1110" =>												-- AND
							FLG_EN <= '1';
							MAR_EN <= '0';
							EXE_ALU <= '1';
							if (IX_ACC = '0') then
								ACC_EN <= '1';
							else
								IX_EN <= '1';
							end if;
							if (ADR_MODE = "100" or ADR_MODE = "110") then
								ADDR8 <= '0';
							elsif (ADR_MODE = "101" or ADR_MODE = "111") then
								ADDR8 <= '1';
							end if;
							
						when "1111" =>												-- CMP
							FLG_EN <= '1';
							MAR_EN <= '0';
							EXE_ALU <= '1';
							if (ADR_MODE = "100" or ADR_MODE = "110") then
								ADDR8 <= '0';
							elsif (ADR_MODE = "101" or ADR_MODE = "111") then
								ADDR8 <= '1';
							end if;
							
						when others =>
							null;
					end case;
				end if;
		end if;
	end process;
	
	ENDPHASE <= PHASECUT;
	HALT <= HLT;
	
    -- One extra stage preserves phase-to-PC/MAR timing after
    -- moving phase advancement onto the following SYSCLK edge.
    process(SYSCLK, RESET)
    begin
        if RESET = '1' then
            DFF <= "000";
        elsif rising_edge(SYSCLK) then
            DFF <= DFF(1 downto 0) & CLKEN;
        end if;
    end process;

    ADR_EN <= MAR_EN and PC_CEN_i and PHASE_RUN;
    PC_CEN_i <= DFF(2);
    PC_CEN <= PC_CEN_i;

	process(SYSCLK, RESET) begin
		if (RESET = '1') then
			DELAY <= '0';
		elsif(SYSCLK'event and SYSCLK='1') then
			DELAY <= PC_EN;
		end if;
	end process;
	
	PC_LATCH_EN <= PC_EN and not DELAY;


-----------------------------------------
-- プログラムカウンター
-----------------------------------------
	process(SYSCLK, RESET) begin
		if (RESET = '1') then
			PC_COUNT <= "00000000";
		elsif (SYSCLK'event and SYSCLK='1') then
			if (PC_LATCH_EN = '1') then
				PC_COUNT <= DBI;
			end if;
			
			if ((PC_CEN_i = '1') and (PHASE_RUN = '1')) then
				if (PRESENT_PHASE = P0) then
					if (OP_CODE = "0011") then							-- Bcc
						PC_COUNT <= PC_COUNT + 1;
					else
						PC_COUNT <= PC_COUNT + 1;	
					end if;
				elsif (PRESENT_PHASE = P2) then
					case OP_CODE is
						when "0011" =>						-- Branch
							PC_COUNT <= PC_COUNT + 1;
														
						when "0110" =>						-- LD
							if (ADR_MODE > "001") then
								PC_COUNT <= PC_COUNT + 1;
							end if;
							
						when "0111" =>						-- ST
							PC_COUNT <= PC_COUNT + 1;

						-- SBC, ADC, SUB, ADD
						when "1000" =>
							if (ADR_MODE > "001") then
								PC_COUNT <= PC_COUNT + 1;
							end if;

						when "1001" =>
							if (ADR_MODE > "001") then
								PC_COUNT <= PC_COUNT + 1;
							end if;

						when "1010" =>
							if (ADR_MODE > "001") then
								PC_COUNT <= PC_COUNT + 1;
							end if;

						when "1011" =>
							if (ADR_MODE > "001") then
								PC_COUNT <= PC_COUNT + 1;
							end if;

							-- EOR, OR, AND, CMP
						when "1100" =>
							if (ADR_MODE > "001") then
								PC_COUNT <= PC_COUNT + 1;
							end if;
							
						when "1101" =>
							if (ADR_MODE > "001") then
								PC_COUNT <= PC_COUNT + 1;
							end if;
							
						when "1110" =>
							if (ADR_MODE > "001") then
								PC_COUNT <= PC_COUNT + 1;
							end if;
							
						when "1111" =>
							if (ADR_MODE > "001") then
								PC_COUNT <= PC_COUNT + 1;
							end if;
							
						when others =>
							null;
					end case;
				end if;
			end if;
		end if;
	end process;
	
	process(SYSCLK) begin
		if (SYSCLK'event and SYSCLK='1') then
			if ((PRESENT_PHASE = IDLE) or (HLT = '1')) then
				OP_LED <= '0';
				PHASE_LED <= "00001";
			elsif (PRESENT_PHASE = P0) then
				OP_LED <= '1';
				PHASE_LED <= "00010";
			elsif (PRESENT_PHASE = P1) then
				PHASE_LED <= "00100";
			elsif (PRESENT_PHASE = P2) then
				if (PHASECUT = '1') then
					PHASE_LED <= "00001";
				else
					PHASE_LED <= "01000";
				end if;
			elsif (PRESENT_PHASE = p3) then
				if (PHASECUT = '1') then
					PHASE_LED <= "00001";
				else
					PHASE_LED <= "10000";
				end if;
			elsif (PRESENT_PHASE = p4) then
				PHASE_LED <= "00001";
			end if;
		end if;
	end process;
			
	PC <= PC_COUNT;
	
end rtl;