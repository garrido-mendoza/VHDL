library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity async_rst_tb is
end async_rst_tb;

architecture Behavioral of async_rst_tb is

    component async_rst is
        port (
            clk    : in bit;
            rst_f  : in bit;
            count  : out integer
        );
    end component;

    signal clk_i    : bit;
    signal rst_f_i  : bit;
    signal count_o  : integer;

begin

    -- Unit under test instantiation
    uut : async_rst 
        port map (
            clk    => clk_i,
            rst_f  => rst_f_i,
            count  => count_o
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
        
        wait for 10 us;
        rst_f_i <= '1';
        
        wait for 100 us;
        rst_f_i <= '0';
        
        wait;    
    end process;
            
end Behavioral;
