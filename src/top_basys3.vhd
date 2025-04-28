--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(9 downto 2); -- operands and opcode  --gwpy, my swich(1) is bad, so migrating
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 

    -- signal declarations

    signal w_clk_tdm, w_sign: std_logic;
    signal w_cycle, w_hund, w_tens, w_ones, w_hex, w_sel, w_an  : std_logic_vector(3 downto 0);
    signal s_First_Operand, s_Second_Operand, w_result, w_bin : std_logic_vector(7 downto 0);
    signal w_sign_code, w_seg, w_7seg : std_logic_vector(6 downto 0);
   
	-- declare components and signals
	component clock_divider is
        generic ( constant k_DIV : natural := 2    ); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port (     i_clk    : in std_logic;
                i_reset  : in std_logic;           -- asynchronous
                o_clk    : out std_logic           -- divided (slow) clock
        );
    end component clock_divider;
    
    component controller_fsm is
        Port (
            i_reset : in STD_LOGIC;
            i_adv : in STD_LOGIC;
            o_cycle : out STD_LOGIC_VECTOR (3 downto 0)
            );
    end component controller_fsm;
    
    component ALU is
        Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
               i_B : in STD_LOGIC_VECTOR (7 downto 0);
               i_op : in STD_LOGIC_VECTOR (2 downto 0);
               o_result : out STD_LOGIC_VECTOR (7 downto 0);
               o_flags : out STD_LOGIC_VECTOR (3 downto 0));
    end component ALU;
    
    component twos_comp is
        port (
            i_bin: in std_logic_vector(7 downto 0);
            o_sign: out std_logic;
            o_hund: out std_logic_vector(3 downto 0);
            o_tens: out std_logic_vector(3 downto 0);
            o_ones: out std_logic_vector(3 downto 0)
        );
    end component twos_comp;

    component TDM4 is
	generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
    Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	);
    end component TDM4;

    component sevenseg_decoder is
    Port ( i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
           o_seg_n : out STD_LOGIC_VECTOR (6 downto 0));
    end component sevenseg_decoder;

begin
	-- PORT MAPS ----------------------------------------
    clk_divider_tdm : clock_divider 
    generic map ( k_DIV => 100000 )
    port map (
        i_clk    => clk,
        i_reset  => btnU,   -- or btnL?
        o_clk    => w_clk_tdm
    );

	my_controller_fsm : controller_fsm port map (
             i_reset => btnU,
             i_adv =>   btnC,
             o_cycle => w_cycle
    );          

    my_ALU : ALU port map (
               i_A => s_First_Operand,
               i_B => s_Second_Operand,
               i_op => sw(4 downto 2),
               o_result => w_result,
               o_flags => led(15 downto 12)
    );

    my_twos_comp : twos_comp port map (
            i_bin => w_bin,
            o_sign => w_sign,
            o_hund => w_hund,
            o_tens => w_tens,
            o_ones => w_ones
    );
    
    my_TDM : TDM4 port map (
           i_clk    => w_clk_tdm,
           i_reset  => btnU,
           i_D3     => "0000",  -- sign location?
           i_D2     => w_hund,
           i_D1     => w_tens,
           i_D0     => w_ones,
           o_data   => w_hex,
           o_sel    => w_sel
    );

    my_decoder : sevenseg_decoder port map (
           i_Hex => w_hex,
           o_seg_n => w_seg
     );
         
	-- Operand registers ------------
    First_Operand_register : process(w_cycle(1))
    begin
        if rising_edge(w_cycle(1)) then
           if btnU = '1' then
               s_First_Operand <= "00000000";
           else   -- "0010"
               s_First_Operand <= sw(9 downto 2);
           end if;
        end if;
    end process First_Operand_register;
    
    Second_Operand_register : process(w_cycle(2))
    begin
        if rising_edge(w_cycle(2)) then
           if btnU = '1' then
               s_Second_Operand <= "00000000";
           else   -- "0010"
               s_Second_Operand <= sw(9 downto 2);
           end if;
        end if;
    end process Second_Operand_register;
	
	-- CONCURRENT STATEMENTS ----------------------------
-- bin MUX
    w_bin <= "00000000"       when w_cycle = "0001" else  -- clear display
             s_First_Operand  when w_cycle = "0010" else  -- 1st operand
             s_Second_Operand when w_cycle = "0100" else  -- 2nd operand
             w_result         when w_cycle = "1000";  -- ALU result

-- positive or negative
    w_sign_code <= "1111111" when w_sign = '0' else -- positive
                   "1110111" ;   -- negative
-- mux to make sign symbol
    w_7seg <= w_sign_code when w_sel = "11" else
              w_seg;
    
-- mux to blank
    w_an <= "1111" when w_cycle = "0001" else
            w_sel;

	-- CONCURRENT STATEMENTS --------
    -- TODO: w_A, w_B, led(3 downto 0)
    led(5 downto 2) <= w_cycle;
    led(11 downto 6) <= (others => '0'); -- Ground unused LEDs
    led(1 downto 0) <= (others => '0'); -- Ground unused LEDs
    an <= w_an;
    seg <= w_7seg;
   
end top_basys3_arch;
