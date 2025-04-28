----------------------------------------------------------------------------------
-- Full Adder
-- See Digital Design and Computer Architecture, RISC-V Figure 5.3 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity full_adder is
    Port ( i_A : in  STD_LOGIC;
           i_B : in  STD_LOGIC;
           i_Cin : in  STD_LOGIC;
           o_S : out  STD_LOGIC;
           o_Cout : out  STD_LOGIC);
end full_adder;

architecture Behavioral of full_adder is
begin

        o_S <= i_A XOR i_B XOR i_Cin;
        o_Cout <= (i_A AND i_B) OR (i_B AND i_Cin) OR (i_A AND i_Cin);
        
end Behavioral;
