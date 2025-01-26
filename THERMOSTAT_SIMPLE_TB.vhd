library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity thermostat_simple_tb is
end thermostat_simple_tb;

architecture Behavioral of thermostat_simple_tb is

    component thermostat is
        port (
            clk             : in bit;
            rst             : in bit;
            current_temp    : in bit_vector(6 downto 0);
            desired_temp    : in bit_vector(6 downto 0);
            display_select  : in bit;
            cool            : in bit;  -- Switch that indicates when the operator wants the a/c to come on. 
            heat            : in bit;  -- This heat bit will come on when the operator wants the furnace to come on.
            temp_display    : out bit_vector(6 downto 0);
            a_c_on          : out bit;   -- The a/c only comes on if the current temperature is greater than the desired temperature.
            furnace_on      : out bit    -- The furnace should come on only if the current temperature is less than the desired temperature. 
        );
    end component;

    -- Input signal declarations            
    signal clk_i             : bit;
    signal rst_i             : bit := '0';
    signal current_temp_i    : bit_vector(6 downto 0) := "0000000";
    signal desired_temp_i    : bit_vector(6 downto 0) := "0000000";
    signal display_select_i  : bit := '0';
    signal cool_i            : bit := '0';
    signal heat_i            : bit := '0';

    -- Output signal declarations
    signal temp_display_o    : bit_vector(6 downto 0);
    signal a_c_on_o          : bit;
    signal furnace_on_o      : bit;

begin

    uut : thermostat
        port map (
            clk             => clk_i,
            rst             => rst_i,
            current_temp    => current_temp_i,
            desired_temp    => desired_temp_i,
            display_select  => display_select_i,
            cool            => cool_i,
            heat            => heat_i,
            temp_display    => temp_display_o,
            a_c_on          => a_c_on_o,
            furnace_on      => furnace_on_o
        );
    
    clk_gen : process
    begin
        while true loop
            clk_i <= '0';
            wait for 10 ns;
            clk_i <= '1';
            wait for 10 ns;
        end loop;
    end process;        
                 
    stimulus : process
    begin
        wait for 5 us;
        current_temp_i <= "1000001";
        
        wait for 1 us;
        display_select_i <= '1';
        
        wait for 3 us;
        desired_temp_i <= "1001010";
        
        wait for 70 us;
        display_select_i <= '0';
        
        wait for 15 us;
        current_temp_i <= "1000110";
        
        wait for 1 us;
        display_select_i <= '1';
        
        wait for 5 us;
        cool_i <= '1';
        
        wait for 10 us;
        current_temp_i <= "1010000";    -- 80 is greater than 74 degrees; thus, the a_c_on signal should be asserted. 
        
        wait for 70 us;
        cool_i <= '0';  -- Because this signal is deasserted, a_c_on should turn off (deasserted).
        
        wait for 6 us;
        heat_i <= '1';
        
        wait for 10 us;
        current_temp_i <= "0111100";    -- 60 is less than 74 degrees; thus, the heat signal should be asserted. 
        
        wait for 70 us;
        heat_i <= '0';  -- Because this signal is deasserted, furnace_on should turn off (deasserted).
        
        wait;   -- We need to add this wait statement, otherwise, the stimulus process will repeat over and over again. 
        
    end process;

end Behavioral;
