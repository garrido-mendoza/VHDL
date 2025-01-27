library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Clken_TB is
end Clken_TB;

architecture Behavioral of Clken_TB is

    component Clken is
        port (
            clk      : in bit;
            rst_f    : in bit;
            data     : in bit;
            enable   : in bit;
            data_out : out bit
        );
    end component;

    signal clk_i        : bit;
    signal rst_f_i      : bit;
    signal data_i       : bit;
    signal enable_i     : bit;
    signal data_out_o   : bit;

begin

    -- Unit under test instantiation
    uut : Clken 
        port map (
            clk      => clk_i,
            rst_f    => rst_f_i,
            data     => data_i,
            enable   => enable_i,
            data_out => data_out_o
        );
    
    -- Clock generation
    clk_gen : process
    begin
        while true loop
            clk_i <= '0';
            wait for 10 ns;
            clk_i <= '1';
            wait for 10 ns;
        end loop;
    end process;
    
    -- Stimulus process
    stimulus : process
    begin
        rst_f_i <= '0';
        
        wait for 20 us;
        data_i <= '1';

        wait for 20 us;
        rst_f_i <= '1';
        
        wait for 5 us;
        enable_i <= '1';
        
        wait for 10 us;
        data_i <= '0';
        
        wait for 20 us;
        data_i <= '1';
        
        wait for 5 us;
        enable_i <= '0';
        
        wait for 20 us;
        data_i <= '0';
        
        wait for 20 us;
        enable_i <= '1';    
        
        wait for 10 us;
        data_i <= '1';    

        wait for 30 us;
        rst_f_i <= '0';
        
        wait for 70 us;
        data_i <= '0'; 
        
        wait;
    end process;

end Behavioral;
