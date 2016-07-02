--Author:Hutanu Ovidiu
--Module name:serialt

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
--library work;
--USE work.defs.ALL;


entity serialt is
 PORT( 
		clk		: IN		std_logic;
		en			: IN		std_logic;
      status   : IN     STD_LOGIC_VECTOR (15 downto 0);
		serial_out : OUT std_logic;
		flag : OUT std_logic;
		start : OUT std_logic;
		res	: IN		std_logic
		   );
end serialt;

architecture Behavioral of serialt is
signal start_tx, tx_busy : std_logic := '0';
signal counter : std_logic := '0';
signal data_in_serial : std_logic_vector (7 downto 0) := "00000000";

	component serial_tx is
    Port ( clk : in  STD_LOGIC;
	        index : in  STD_LOGIC;
			  begin_tx: in STD_LOGIC;
           input : in  STD_LOGIC_VECTOR(7 downto 0);
           serial : out  STD_LOGIC;
			  tx_busy : out STD_LOGIC;
			  flag : out STD_LOGIC;
			  start : OUT std_logic
			 
			  );
	end component;
	
begin
		phy_serial_tx: serial_tx
			port map( clk => clk,
			  index=>counter,
			  begin_tx => start_tx, 
           input => data_in_serial, 
           serial => serial_out,
			  tx_busy => tx_busy,
			  flag=>flag,
			  start=>start
			  );

	process (clk)
	begin
		if (rising_edge(clk)) then
		if (tx_busy = '0' AND en = '1') then
				start_tx <= '1';
				if (counter = '1') then
					counter <= '0';
				else
					counter <= counter xor '1';
				end if;
			else
				start_tx <= '0';
			end if;
			 if(res= '1') then counter <= '0';
			    end if;
		end if;
	end process;
	
data_in_serial <= status(15 downto 8) WHEN (counter='0') ELSE
                  status(7 downto 0);

end Behavioral;

