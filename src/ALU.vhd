----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

    
architecture Behavioral of ALU is
    component full_adder is
port (
    i_A     : in std_logic;
    i_B     : in std_logic;
    i_Cin   : in std_logic;
    o_S     : out std_logic;
    o_Cout  : out std_logic
    );
end component full_adder;
signal w_A, w_B, w_Bin, w_Sum, w_And, w_Or : STD_LOGIC_VECTOR(7 downto 0); -- for sw inputs to operands
signal w_carry  : STD_LOGIC_VECTOR(7 downto 0); -- for ripple between adders
begin
	-- PORT MAPS --------------------
w_A <= i_A;
w_B <= i_B;

full_adder_0: full_adder
port map(
    i_A     => w_A(0),
    i_B     => w_Bin(0),
    i_Cin   => i_op(0),  
    o_S     => w_Sum(0),
    o_Cout  => w_carry(0)
);

full_adder_1: full_adder
port map(
    i_A     => w_A(1),
    i_B     => w_Bin(1),
    i_Cin   => w_carry(0),
    o_S     => w_Sum(1),
    o_Cout  => w_carry(1)
);  

full_adder_2: full_adder
port map(
        i_A     => w_A(2),
        i_B     => w_Bin(2),
        i_Cin   => w_carry(1),
        o_S     => w_Sum(2),
        o_Cout  => w_carry(2)
 );  
 
full_adder_3: full_adder
 port map(
         i_A     => w_A(3),
         i_B     => w_Bin(3),
         i_Cin   => w_carry(2),
         o_S     => w_Sum(3),
         o_Cout  => w_carry(3)
  ); 
full_adder_4: full_adder
   port map(
           i_A     => w_A(4),
           i_B     => w_Bin(4),
           i_Cin   => w_carry(3),
           o_S     => w_Sum(4),
           o_Cout  => w_carry(4)
    ); 
full_adder_5: full_adder
       port map(
               i_A     => w_A(5),
               i_B     => w_Bin(5),
               i_Cin   => w_carry(4),
               o_S     => w_Sum(5),
               o_Cout  => w_carry(5)
        ); 
full_adder_6: full_adder
               port map(
                       i_A     => w_A(6),
                       i_B     => w_Bin(6),
                       i_Cin   => w_carry(5),
                       o_S     => w_Sum(6),
                       o_Cout  => w_carry(6)
                );    
full_adder_7: full_adder
                               port map(
                                       i_A     => w_A(7),
                                       i_B     => w_Bin(7),
                                       i_Cin   => w_carry(6),
                                       o_S     => w_Sum(7),
                                       o_Cout  => w_carry(7)
                                );    
                       
 -- mux for add vs subtract
 w_Bin  <= w_B when i_op(0) = '0' else
           not(w_B);
w_And <= w_A and w_B;
w_Or <= w_A or w_B;

-- mux for 4 ALU choices
o_result <= w_Sum when i_op(1) = '0' and i_op(0) = '0' else   -- Add
            w_Sum when i_op(1) = '0' and i_op(0) = '1' else   -- Subtract
            w_And when i_op(1) = '1' and i_op(0) = '0' else   -- And
            w_Or  when i_op(1) = '1' and i_op(0) = '1';       -- Or

-- Do the Flags
-- Overflow
o_flags(0) <= (i_op(0) xnor w_A(7) xnor w_B(7)) and (w_A(7) xor w_B(7)) and (not (i_op(1)));
-- carry
o_flags(1) <= w_carry(7) and not (i_op(1));
-- Zero
o_flags(2) <= not(w_Sum(7)) and not(w_Sum(6))and not(w_Sum(5))and not(w_Sum(4))and not(w_Sum(3))and not(w_Sum(2))and not(w_Sum(1))and not(w_Sum(0));
-- Negative
o_flags(3) <= w_Sum(7);

end Behavioral;
