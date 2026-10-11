--========================================================
--  Project   : AYME0100
--  Outline   : 教育用8ビットマイコン(kue-chip2)FPGA
----------------------------------------------------------
--  File Name : exe_ctrl.vhd
--  Function  : プログラム実行モードの切替・制御
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

entity EXE_CTRL is
port (
    CLK         : in std_logic;
    RESET       : in std_logic;
    CLKEN       : in std_logic;
    HALT        : in std_logic;
    ENDPHASE    : in std_logic;
    EXE         : in std_logic_vector(2 downto 0);
    SP          : out std_logic;
    SI          : out std_logic;
    SS          : out std_logic
    );
end EXE_CTRL;

architecture rtl of EXE_CTRL is

    signal SS_I     : std_logic;
    signal SI_I     : std_logic;
    signal DFF      : std_logic;
    signal STP_SI   : std_logic;
    signal SP_HOLD  : std_logic;

    type states is (IDLE, S0, S1);
    signal PRESENT_STATE : states;
    signal NEXT_STATE    : states;

begin

    ----------------------------------------------------------------
    -- 状態レジスタ（SS, SI 用）
    ----------------------------------------------------------------
    process(CLK, RESET)
    begin
        if (RESET = '1') then
            PRESENT_STATE <= IDLE;
        elsif (CLK'event and CLK = '1') then
            PRESENT_STATE <= NEXT_STATE;
        end if;
    end process;

    ----------------------------------------------------------------
    -- ENDPHASE 立上り検出
    ----------------------------------------------------------------
    process(CLK, RESET)
    begin
        if (RESET = '1') then
            DFF <= '0';
        elsif (CLK'event and CLK = '1') then
            DFF <= ENDPHASE;
        end if;
    end process;

    STP_SI <= ENDPHASE and not DFF;

    ----------------------------------------------------------------
    -- SS / SI 用FSM
    ----------------------------------------------------------------
    process(PRESENT_STATE, EXE, STP_SI, HALT)
    begin
        NEXT_STATE <= PRESENT_STATE;
        SS_I <= '0';
        SI_I <= '0';

        case PRESENT_STATE is
            when IDLE =>
                if (EXE(0) = '1') then
                    NEXT_STATE <= S0;
                elsif (EXE(1) = '1') then
                    NEXT_STATE <= S1;
                else
                    NEXT_STATE <= IDLE;
                end if;

            when S0 =>                          -- SSモード
                SS_I <= '1';
                if (HALT = '1') then
                    NEXT_STATE <= IDLE;
                elsif (EXE(0) = '1') then
                    NEXT_STATE <= S1;
                else
                    NEXT_STATE <= S0;
                end if;

            when S1 =>                          -- SIモード
                SI_I <= '1';
                if (STP_SI = '1') then
                    NEXT_STATE <= IDLE;
                else
                    NEXT_STATE <= S1;
                end if;

            when others =>
                NEXT_STATE <= IDLE;
        end case;
    end process;

    ----------------------------------------------------------------
    -- SP 制御
    --
    -- EXE(2)を受けたら SP_HOLD を立てる
    -- SP_HOLDは次のCLKEN立上りまで保持
    -- そのCLKEN立上りで下流CONTROLがSP='1'を見て1回だけ進む
    -- 同じSYSCLK立上りで SP_HOLD を0に戻す
    ----------------------------------------------------------------
    process(CLK, RESET)
    begin
        if (RESET = '1') then
            SP_HOLD <= '0';
        elsif (CLK'event and CLK = '1') then

            -- SP要求を保持
            if (EXE(2) = '1') then
                SP_HOLD <= '1';

            -- 次のCLKENで1回だけ実行して解除
            elsif (SP_HOLD = '1' and CLKEN = '1') then
                SP_HOLD <= '0';
            end if;

        end if;
    end process;

    SS <= SS_I;
    SI <= SI_I;
    SP <= SP_HOLD;

end rtl;

--library IEEE;
--use IEEE.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
--use work.all;
--
---- 入出力の宣言
--entity EXE_CTRL is
--port (
--	CLK		: in std_logic;
--	RESET		: in std_logic;
--	CLKEN		: in std_logic;
--	HALT		: in std_logic;
--	ENDPHASE	: in std_logic;
--	EXE		: in std_logic_vector(2 downto 0);
--	SP			: out std_logic;
--	SI			: out std_logic;
--	SS			: out std_logic
--	);
--end EXE_CTRL;
--
---- 回路の記述
--architecture rtl of EXE_CTRL is
--
---- 内部信号の定義
--signal SS_I 	: std_logic;
--signal STP_SI 	: std_logic;
--signal DFF 		: std_logic;
--
--type states is (IDLE, S0, S1, S2);
--signal PRESENT_STATE	: states;
--signal NEXT_STATE		: states;
--
--begin
--	process(CLK, RESET) begin
--		if (RESET = '1') then
--			PRESENT_STATE <= IDLE;
--		elsif(CLK'event and CLK='1') then
--			PRESENT_STATE <= NEXT_STATE;
--		end if;
--	end process;
--
--	process(PRESENT_STATE, NEXT_STATE, EXE, STP_SI, HALT, CLKEN) begin
--		case PRESENT_STATE is
--			when IDLE =>
--				SS_I <= '0';
--				SI <= '0';
--				SP <= '0';
--				if (EXE(0) = '1') then
--					NEXT_STATE <= S0;
--				elsif(EXE(1) = '1') then
--					NEXT_STATE <= S1;
--				elsif (EXE(2) = '1') then
--					NEXT_STATE <= S2;
--				else
--					NEXT_STATE <= IDLE;
--				end if;
--			
--			when S0 =>							-- SSモード
--				SS_I <= '1';
--				SI <= '0';
--				SP <= '0';
--				if (HALT = '1') then
--					NEXT_STATE <= IDLE;
--				elsif (EXE(0) = '1') then
--					NEXT_STATE <= S1;
--				else
--					NEXT_STATE <= S0;
--				end if;
--			
--			when S1 =>							-- SIモード
--				SS_I <= '0';
--				SI <= '1';
--				SP <= '0';
--				if (STP_SI = '1') then
--					NEXT_STATE <= IDLE;
--				else
--					NEXT_STATE <= S1;
--				end if;
--					
--			when S2 =>							-- SPモード
--				SS_I <= '0';
--				SI <= '0';
--				SP <= '1';
--				if (CLKEN = '1') then
--					NEXT_STATE <= IDLE;
--				else
--					NEXT_STATE <= S2;
--				end if;
--				
--			when others =>
--				null;
--		end case;
--	end process;
--	
--	process(CLK, RESET) begin
--		if (RESET = '1') then
--			DFF <= '0';
--		elsif (CLK'event and CLK='1') then
--			DFF <= ENDPHASE;
--		end if;
--	end process;
--	
--	STP_SI <= ENDPHASE and not DFF;
--
--	SS <= SS_I;
--	
--end rtl; 
                   
     
      
