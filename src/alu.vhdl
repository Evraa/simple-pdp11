library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--temp0 and B are the two operands for the alu
--mode is the operation
--en: enable
--flagIn: input the flag register
--F is the output of the two operations
--flagOut: the output condition of the flags
entity alu is
    generic (n : integer := 16);

    port (
        temp0 , B : in std_logic_vector(n-1 downto 0);
        mode : in std_logic_vector(3 downto 0);
        clk,en: in std_logic;
        flagIn: in std_logic_vector(4 downto 0);
        IR_Check: in std_logic;
        F : out std_logic_vector(15 downto 0);
        flagOut : out std_logic_vector(4 downto 0)
    );
end entity;

architecture archALU of alu is
begin
    
    process (temp0, B, mode, en, flagIn, clk)
        variable ALUOUT: std_logic_vector(n DOWNTO 0);
        variable carryInput: std_logic_vector(n-1 DOWNTO 0);
        variable secInput: std_logic_vector(n-1 DOWNTO 0);
        variable temp_flag_out: std_logic_vector(4 DOWNTO 0);
        variable temp0Bar: std_logic_vector(n-1 DOWNTO 0);
    begin
        if en='1' and clk = '1' then
            case mode is
                when "0000" =>
                    --ADD
                    --Won't check on the carry's state as it gets added any ways
                    if (IR_Check = '1' and flagIn(0) = '1') then
                        carryInput := "0000000000000001";
                    else
                        carryInput := (OTHERS => '0');
                    end if;

                    ALUOUT := std_logic_vector (resize(signed(B),17) + resize(signed(temp0),17) + resize(signed(carryInput),17) );
                    if(ALUOUT(n) = '1') then
                        temp_flag_out(0) :='1';
                    else
                        temp_flag_out(0) :='0';
                    end if;

                    --P + P = N
                    if (B(n-1) = '0' and temp0(n-1) = '0' and ALUOUT(n-1) = '1') then
                        temp_flag_out(4) := '1';
                    --N+N = P
                    ELSIF (B(n-1) = '1' and temp0(n-1) = '1' and ALUOUT(n-1) = '0') then 
                        temp_flag_out(4) := '1';
                    else
                        temp_flag_out(4) := '0';
                    end if;
                when "0001" =>
                    --SUB
                    --NOTE: A - B == A + (B)` + 1 
                    --NOTE: A - B - C == A - (B+C) == A + (B+C)` + 1
                    --SO, temp0Bar = (B+C), whether C = 0 or 1

                    if (IR_Check = '1' and flagIn(0) = '1') then
                        carryInput := "0000000000000001"; 
                    else
                        carryInput := (OTHERS => '0');
                    end if;

                    ALUOUT := std_logic_vector (resize(signed(temp0),17) - resize(signed(B),17) - resize(signed(carryInput),17) );
                    
                    if(ALUOUT(n) = '1') then
                        temp_flag_out(0) :='1';
                    else
                        temp_flag_out(0) :='0';
                    end if;

                    --P - N = N
                    if (B(n-1) = '0' and temp0(n-1) = '1' and ALUOUT(n-1) = '1') then
                        temp_flag_out(4) := '1';
                    --N-P = P
                    ELSIF (B(n-1) = '1' and temp0(n-1) = '0' and ALUOUT(n-1) = '0') then 
                        temp_flag_out(4) := '1';
                    else
                        temp_flag_out(4) := '0';
                    end if;
                when "0010" =>
                    --AND
                    ALUOUT(15 downto 0) := temp0 and B;
                    temp_flag_out(0) := flagIn(0);
                    temp_flag_out(4) := '0';
                when "0011" =>
                    --OR
                    ALUOUT(15 downto 0) := temp0 or B;
                    temp_flag_out(0) := flagIn(0);
                    temp_flag_out(4) := '0';
                when "0100" =>
                    --NOT
                    ALUOUT(15 downto 0) := not B;
                    temp_flag_out(0) := flagIn(0);
                    temp_flag_out(4) := '0';
                when "0101" =>
                    --XNOR
                    ALUOUT(15 downto 0) := temp0 XNOR B;
                    temp_flag_out(0) := flagIn(0);
                    temp_flag_out(4) := '0';
                when "0110" =>
                    --LSR: Logical shift Right
                    ALUOUT(15 downto 0) := '0' & B(n-1 downto 1);
                    temp_flag_out(0) := B(0);
                    temp_flag_out(4) := flagIn(0) XOR flagIn(2);
                when "0111" =>
                    --ROR
                    ALUOUT(15 downto 0) := B(0) & B(n-1 downto 1);
                    temp_flag_out(0) := B(0);
                    temp_flag_out(4) := flagIn(0) XOR flagIn(2);
                when "1000" =>
                    --RRC
                    ALUOUT(15 downto 0) := flagIn(0) & B(n-1 downto 1);
                    temp_flag_out(0) := B(0);
                    temp_flag_out(4) := flagIn(0) XOR flagIn(2);
                when "1001" =>
                    --ASR: Arithmetic shift right
                    ALUOUT(15 downto 0) := B(n-1) & B(n-1 downto 1);
                    temp_flag_out(0) := B(0);
                    temp_flag_out(4) := flagIn(0) XOR flagIn(2);
                when "1010" =>
                    --LSL: Logical Shift Left
                    ALUOUT(15 downto 0) :=  B(n-2 downto 0) & '0'; 
                    temp_flag_out(0) := B(n-1);
                    temp_flag_out(4) := flagIn(0) XOR flagIn(2);
                when "1011" =>
                    --ROL
                    ALUOUT(15 downto 0) :=  B(n-2 downto 0) & B(n-1);
                    temp_flag_out(0) := B(n-1);
                    temp_flag_out(4) := flagIn(0) XOR flagIn(2);
                when "1100" =>
                    --RLC
                    ALUOUT(15 downto 0) :=  B(n-2 downto 0) & flagIn(0);
                    temp_flag_out(0) := B(n-1);
                    temp_flag_out(4) := flagIn(0) XOR flagIn(2);
                when "1101" =>
                    --DEC
                    --F = B - 1 == (B + 1), not 001 but 111
                    carryInput := "0000000000000001";
                    ALUOUT := std_logic_vector (resize(signed(B),17) - resize(signed(carryInput),17) );

                    if(B = "0000000000000000") then
                        temp_flag_out(0) := '1';
                    else
                        temp_flag_out(0) := '0';
                    end if;
                    
                    if (B="1000000000000000") then
                        temp_flag_out(4) := '1';
                    else
                        temp_flag_out(4) := '0';
                    end if;
                when "1110" =>
                    --INC
                    --F = B + 1 == B + 0 and carry = 1
                    carryInput := "0000000000000001";
                    ALUOUT := std_logic_vector (resize(signed(B),17) + resize(signed(carryInput),17) );
                    if (B="1111111111111111") then
                        temp_flag_out(0) := '1';
                    else
                        temp_flag_out(0) := '0';
                    end if;
                    
                    if (B="0111111111111111") then
                        temp_flag_out(4) := '1';
                    else
                        temp_flag_out(4) := '0';
                    end if;
                when OTHERS =>
                    --CLR
                    ALUOUT := "00000000000000000";
                    temp_flag_out(0) := '0'; --Carry
                    temp_flag_out(4) := '0'; --Overflow
            end case;
            
            --Show new output on F
            --Check on the zero flag
            F <= ALUOUT(15 downto 0);
            flagOut(0) <= temp_flag_out(0);
            flagOut(4) <= temp_flag_out(4);
            if (ALUOUT(15 downto 0)="0000000000000000") then
                flagOut(1) <= '1';
            else
                flagOut(1) <= '0';
            end if;

            --Check on Negative flag
            if (ALUOUT(n-1)='1') then
                flagOut(2) <= '1';
            else
                flagOut(2) <= '0';
            end if;

            --Parity Flag
            flagOut(3) <= ALUOUT(0) xor (ALUOUT(1) xor (ALUOUT(2) xor (ALUOUT(3) xor (ALUOUT(4) xor (ALUOUT(5) xor (ALUOUT(6) xor (ALUOUT(7) xor (ALUOUT(8) xor (ALUOUT(9) xor (ALUOUT(10) xor (ALUOUT(11) xor (ALUOUT(12) xor (ALUOUT(13) xor ( ALUOUT(14)  xor ALUOUT(15) ) )   ))))))))))) );
        else
            F <= "ZZZZZZZZZZZZZZZZ";
            flagOut <= "ZZZZZ";
        end if;
    end process;
end architecture;
