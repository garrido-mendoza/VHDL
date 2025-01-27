library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Thermostat_FSM_TB is
end Thermostat_FSM_TB;

architecture Behavioral of Thermostat_FSM_TB is

    component Thermostat is
        port (
            clk             : in std_logic;
            rst             : in std_logic;
            current_temp    : in std_logic_vector(6 downto 0);
            desired_temp    : in std_logic_vector(6 downto 0);
            display_select  : in std_logic;
            cool            : in std_logic;   -- Switch that indicates when the operator wants the a/c to come on. 
            heat            : in std_logic;   -- This heat std_logic will come on when the operator wants the furnace to come on.
            furnace_hot     : in std_logic;   -- Input signal that's coming from the furnace to tell us that the furnace is hot after we turned it on. We now can turn on the fan and blow hot air. 
            ac_ready        : in std_logic;   -- Signal that comes from the A/C to tell us that the A/C is cold, and that's okay to turn on the fan to blow cold air. 
            temp_display    : out std_logic_vector(6 downto 0);
            a_c_on          : out std_logic;  -- The a/c only comes on if the current temperature is greater than the desired temperature.
            furnace_on      : out std_logic;  -- The furnace should come on only if the current temperature is less than the desired temperature.
            fan_on          : out std_logic   -- Output that controls the fan.
        );
    end component;

    -- Input signal declarations            
    signal clk_i             : std_logic;
    signal rst_i             : std_logic := '0';
    signal current_temp_i    : std_logic_vector(6 downto 0) := "0000000";
    signal desired_temp_i    : std_logic_vector(6 downto 0) := "1001010";  -- 74
    signal display_select_i  : std_logic := '0';
    signal cool_i            : std_logic := '0';
    signal heat_i            : std_logic := '0';
    signal furnace_hot_i     : std_logic := '0'; 
    signal ac_ready_i        : std_logic := '0';

    -- Output signal declarations
    signal temp_display_o    : std_logic_vector(6 downto 0);
    signal a_c_on_o          : std_logic;
    signal furnace_on_o      : std_logic;
    signal fan_on_o          : std_logic;

begin

    uut : Thermostat
        port map (
            clk             => clk_i,
            rst             => rst_i,
            current_temp    => current_temp_i,
            desired_temp    => desired_temp_i,
            display_select  => display_select_i,
            cool            => cool_i,
            heat            => heat_i,
            furnace_hot     => furnace_hot_i,
            ac_ready        => ac_ready_i,   
            temp_display    => temp_display_o,
            a_c_on          => a_c_on_o,
            furnace_on      => furnace_on_o,
            fan_on          => fan_on_o
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
        wait for 100 us;
        heat_i <= '1';
        current_temp_i <= "0111100";    -- 60
        
        wait for 100 us;
--            heat_i <= '0';
        heat_i <= '1';
        furnace_hot_i <= '1';
--            current_temp_i <= "0111100";    -- 60
        current_temp_i <= "1001010";    -- 74
         
        wait for 100 us;
        furnace_hot_i <= '0';
        
        wait for 100 us;
        heat_i <= '0';
        current_temp_i <= "1010000";    -- 80
        
        wait for 50 us;
        cool_i <= '1';
        
        wait for 50 us;
        cool_i <= '0';
        
        wait for 50 us;
        current_temp_i <= "0111100";    -- 60
        
        wait for 100 us;
        ac_ready_i <= '1';
        
        wait for 100 us;
        cool_i <= '0';
        
        wait for 100 us;
        ac_ready_i <= '0';
        
        wait;   -- We need to add this wait statement, otherwise, the stimulus process will repeat over and over again. 
            
    end process;

end Behavioral;
