----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is
    type state is (clear_display, FirstOperand, SecondOperand, display);
    signal current_state, next_state: state;


begin

	-- State register ------------
	state_register : process(i_adv)
	begin
        if rising_edge(i_adv) then
           if i_reset = '1' then
               next_state <= clear_display;
           else
               case current_state is
                    when clear_display =>
                         next_state <= FirstOperand;
                    when FirstOperand =>
                         next_state <= SecondOperand;
                    when SecondOperand =>
                        next_state <= display;
                    when display => 
                        next_state <= clear_display;
               end case;
            end if;
        end if;
	end process state_register;
	
	current_state <= next_state;
	
	-- Output logic
    with current_state select
    o_cycle <= "0001" when clear_display,
               "0010" when FirstOperand,
               "0100" when SecondOperand,
               "1000" when display;
end FSM;
