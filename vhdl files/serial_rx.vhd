--Author:Hutanu Ovidiu
--Module name:serial_rx

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity serial_rx is
	generic  ( M: integer := 2 );  --system clock/16/M=> baud rate
    Port ( input1 : in  STD_LOGIC;
           clk : in  STD_LOGIC;
			  d_avail : out STD_LOGIC;
           d_out : out  STD_LOGIC_VECTOR (7 downto 0));
end serial_rx;

architecture Behavioral of serial_rx is
type state_type is ( s_waiting, s_start, s_bit, s_stop );
signal state : state_type; 
signal counter: integer range 0 to 15 := 0; 
signal out_bits : std_logic_vector ( 7 downto 0 ) := "00000000";
signal bit_pos: integer range 0 to 7 := 0;
signal rs_tick : std_logic;
signal cnt: integer range 0 TO M+1  := 0;

begin

fsm : process (clk)
begin
	if (rising_edge(clk)) then
		if (cnt < M - 1 ) then
			rs_tick <= '0';
			cnt <= cnt + 1;
		else
			rs_tick <='1';
			cnt <= 0;
		end if;	
		
		d_avail <= '0'; -- default state
		case state is
			when s_waiting =>
				bit_pos <= 0;
				counter <= 0;
				out_bits <= "00000000";
				if ( input1 = '0' ) then -- 0 = the start bit
					state <= s_start ;
				else
					state <= s_waiting;
				end if;
		
			when s_start =>
				bit_pos <= 0;
				out_bits <= "00000000";
				if ( rs_tick = '1' ) then
--					if ( input1 = '0' ) then
						if (counter = 7 ) then 
							state <= s_bit;
							counter <= 0;
						else
							state <= s_start;
							counter <= counter + 1;
						end if;
--					end if;
				else
					state <= s_start;
				end if;
		
			when s_bit =>
				if ( rs_tick = '1' ) then 
					if ( counter = 15 ) then 
						out_bits <= input1 & out_bits (7 downto 1); 
						if (bit_pos = 7 ) then 
							state <= s_stop;
							bit_pos <= 0;
							counter <= 0;
						else
							state <= s_bit;
							bit_pos <= bit_pos + 1;
							counter <= 0;
						end if;
					else
						state <= s_bit;
						counter <= counter + 1;
					end if;
				else
						state <= s_bit;
				end if;
			
			when s_stop =>
				bit_pos <= 0;
				if ( rs_tick = '1') then
					if ( counter = 15 ) then 
						state <= s_waiting;
						counter <= 0;
						d_avail <= '1';
					else
						state <= s_stop;
						counter <= counter + 1;
					end if;
				else
					state <= s_stop;
				end if;
		end case;
	
		d_out <= out_bits;
		end if;
end process;	
	

end Behavioral;
