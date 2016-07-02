--Author:Hutanu Ovidiu
--Module name:serial_tx

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity serial_tx is
	generic  ( M: integer := 2 ); --system clock/16/M=> baud rate 
    Port ( clk : in  STD_LOGIC;
			  index : in  STD_LOGIC;
			  begin_tx: in STD_LOGIC;
           input : in  STD_LOGIC_VECTOR(7 downto 0);
           serial : out  STD_LOGIC;
			  tx_busy : out STD_LOGIC;
			  flag : out STD_LOGIC;
			  start : out STD_LOGIC
			  );
end serial_tx;

architecture Behavioral of serial_tx is
type state_type is ( s_waiting_i, s_waiting, s_start, s_bit, s_stop, s_stop2 );
signal state : state_type; 
signal bit_pos: integer range 0 to 7 := 0;
signal output :std_logic := '0';
signal busy :std_logic := '1';
signal counter : integer range 0 to 61001 := 0;
signal rs_tick : std_logic;
signal cnt: integer range 0 TO M+1 := 0;
begin

tx_fsm : process (clk) is
begin
	if (rising_edge(clk)) then
		if (cnt < M - 1 ) then
			rs_tick <= '0';
			cnt <= cnt + 1;
		else
			rs_tick <='1';
			cnt <= 0;
		end if;	
	
		case state is
			when s_waiting_i =>
				busy <= '0';
				flag<='0';
				if (begin_tx='1') then
					busy <= '1';
					if(index='1') then flag<='1';
					start<='1';
				      end if;
					
					state <= s_waiting;
				end if;
			when s_waiting =>
				if (rs_tick='1') then
					counter <= 0;
					output <= '1'; -- default line high serial
					bit_pos <= 0;
					state <= s_start;
				end if;
			when s_start =>
				if (rs_tick='1') then
					bit_pos <= 0;
					output <= '0';
					if (counter=15) then
						state <= s_bit;
						counter <= 0;
					else
						counter <= counter + 1;
						state <= s_start;
					end if;
				end if;
				
			when s_bit =>
				if (rs_tick='1') then
					if (bit_pos = 7) then
						if (counter=15) then
							state <= s_stop;
							counter <= 0;
						else
							counter <= counter + 1;
							state <= s_bit;
						end if;
					else
						if (counter = 15) then
							bit_pos <= bit_pos + 1;
							counter <= 0;
						else
							counter <= counter + 1;
						end if;
							
					state <= s_bit;
							
					end if;
					output <= input(bit_pos);
				end if;
			when s_stop =>
				if (rs_tick='1') then
					bit_pos <= 0;
					output <= '1';
					if (counter=15) then
						state <= s_stop2; 
						counter <= 0;
					else
						counter <= counter +1;
						state <= s_stop;
					end if;
				end if;
			when s_stop2 =>
				output <= '1';
				start<='0';
				if(index='0') then flag<='1';
				end if;
						 
				if (rs_tick='1') then
					if (counter=900) then
						state <= s_waiting_i; 
						counter <= 0;
						
					else
						counter <= counter +1;
						state <= s_stop2;
					end if;
				end if;
			
			end case;
		end if; 
end process tx_fsm;


tx_busy <= busy OR begin_tx; --if begin_tx it has to be signaled busy 
serial <= output;		

end Behavioral;
