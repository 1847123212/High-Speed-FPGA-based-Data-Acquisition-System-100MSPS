
--Author:Hutanu Ovidiu
--Module name:read_adc

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
library work;
USE work.defs.ALL;


entity read_adc is
	generic  ( M: integer := 2  --variqable for dividing the clock
				);

    Port ( clk : in  STD_LOGIC;                            --system clock
			  adc_enable: in STD_LOGIC;                       --signal from top module 
			  clk_adc: out STD_LOGIC;                         --out clock adc  	 
			  bites_read : in  STD_LOGIC_VECTOR(9 downto 0);  --pins adc conection
			  adc_pwdn: out STD_LOGIC;                        --output for enable/disable adc
			  data_read: out STD_LOGIC_VECTOR (9 downto 0)    -- out  adc data to tx
			  
			);
end read_adc;

architecture Behavioral of read_adc is
signal cnt: integer range 0 to M+1 := 0;
signal clk_div: STD_LOGIC; 

begin

process (clk)
begin
	if (rising_edge(clk)) then  
      
		
		
		     if (cnt < M - 1 ) then
				if (cnt < M / 2) then
					clk_div <= '0';
				else
					clk_div <= '1';
				end if;
				cnt <= cnt + 1;
			     else
				clk_div <='1';
				cnt <= 0;
			    end if;	
		     if (adc_enable ='1') then
		      adc_pwdn<= '1';
		      clk_adc <= clk_div;
		      --take data
				data_read<= bites_read; 
		    
		       else
		       clk_adc <= '0';
		       adc_pwdn<= '0';
				 data_read<= (others=> '0');
		      end if;
				
		  end if;
		
end process;

end Behavioral;

