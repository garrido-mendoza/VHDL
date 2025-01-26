library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- This signal clocking logic allows us to capture data from a data bus using a data strobe.
entity sigclk is
    port (  clk             : in bit;
            rst_f           : in bit;
            data_bus        : in bit_vector(15 downto 0);   -- Data in this bus is captured when the data strobe is asserted
            data_strobe     : in bit;
            registered_data : out bit_vector (15 downto 0));    
end sigclk;

architecture Behavioral of sigclk is

signal reg_data_o : bit_vector(15 downto 0);

begin
    
    process (clk, rst_f)
    begin
        if rst_f = '0' then
            reg_data_o <= (others => '0');
        elsif clk'event and clk = '1' then
            if data_strobe = '1' then   -- When the data strobe is asserted, the captured data is registered and sent out through the output bus of this circuit, 
                reg_data_o <= data_bus; 
            else 
                reg_data_o <= reg_data_o;
            end if;
        end if;
     end process;
     
     registered_data <= reg_data_o;

end Behavioral;
