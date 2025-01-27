library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Sig_Clk_TB is
end Sig_Clk_TB;

architecture Behavioral of Sig_Clk_TB is

    component Sig_Clk is
        port (
            clk             : in bit;
            rst_f           : in bit;
            data_bus        : in bit_vector(15 downto 0);
            data_strobe     : in bit;
            registered_data : out bit_vector (15 downto 0)
        );
    end component;

    signal clk_i             : bit := '0';
    signal rst_f_i           : bit := '0';
    signal data_bus_i        : bit_vector(15 downto 0) := (others => '0');
    signal data_strobe_i     : bit := '0';
    signal reg_data_o        : bit_vector(15 downto 0);

begin

    uut : Sig_Clk
        port map (
            clk             => clk_i,
            rst_f           => rst_f_i,
            data_bus        => data_bus_i,
            data_strobe     => data_strobe_i,
            registered_data => reg_data_o
        );
                    
    -- Clock generation
    clk_process : process
    begin
        while true loop
            clk_i <= '0';
            wait for 10 ns;
            clk_i <= '1';
            wait for 10 ns;
        end loop;
    end process clk_process;

    -- Stimulus process
    stimulus : process
    begin
        -- Initial reset
        rst_f_i <= '0';
        data_bus_i <= "1000100100100010";
        
        wait for 20 us;
        rst_f_i <= '1';
        
        wait for 10 us;
        data_strobe_i <= '1';
        
        -- Apply input stimulus
        wait for 20 us;
        data_bus_i <= "0000111100101110";
        
        wait for 20 us;
        data_strobe_i <= '0';
        
        wait for 20 us;
        data_bus_i <= "0011000011110001";   
        
        wait for 10 us;
        data_strobe_i <= '1';
        
        wait for 10 us;
        data_strobe_i <= '0';     
       
        wait for 20 us;
        data_bus_i <= "1111000011110000";
    
        wait for 20 us;
        data_strobe_i <= '1';

        wait for 50 us;
        data_strobe_i <= '0';
        
        wait for 15 us;
        rst_f_i <= '0';
        
        -- End simulation
        wait;
    end process stimulus;

end Behavioral;
