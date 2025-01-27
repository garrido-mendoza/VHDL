library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Thermostat_Cntr_FSM_TB is
end Thermostat_Cntr_FSM_TB;

architecture Behavioral of Thermostat_Cntr_FSM_TB is

    component Thermostat is
        port (
            clk             : in std_logic;
            rst             : in std_logic;
            current_temp    : in std_logic_vector(6 downto 0);
            desired_temp    : in std_logic_vector(6 downto 0);
            display_select  : in std_logic;
            cool            : in std_logic;   
            heat            : in std_logic;   
            furnace_hot     : in std_logic;   
            ac_ready        : in std_logic;   
            temp_display    : out std_logic_vector(6 downto 0);
            a_c_on          : out std_logic;  
            furnace_on      : out std_logic;  
            fan_on          : out std_logic
        );
    end component;

    -- Input signal declarations            
    signal clk_i             : std_logic;
    signal rst_i             : std_logic := '0';
    signal current_temp_i    : std_logic_vector(6 downto 0) := "0000000";
    signal desired_temp_i    : std_logic_vector(6 downto 0) := "0000000";
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
        -- Procedure: Set Temps.
        procedure set_temps (current, desired : in integer) is
        begin
            current_temp_i <= std_logic_vector(to_unsigned(current, 7));
            desired_temp_i <= std_logic_vector(to_unsigned(desired, 7));
            return;
        end;     

        variable ac_on_event : time;
        variable ac_off_event : time;
        variable fan_on_event : time;
        variable fan_off_event : time;
        variable time_span : time;

    begin
        report "Starting the thermostat simulation.";
        rst_i <= '1';
        
        wait for 100 ns;
        rst_i <= '0';
        set_temps(current => 65, desired => 74);
        
        wait for 50 ns;
        display_select_i <= '1'; 
        
        wait for 50 ns;
        assert temp_display_o = desired_temp_i 
            report "Temp Display. Not the desired temperature displayed. " 
            severity warning;            
        display_select_i <= '0';
              
        wait for 50 ns;
        assert temp_display_o = current_temp_i 
            report "Temp Display. Not the current temperature displayed. Instead, desired temperature: " & integer'image(to_integer(unsigned(temp_display_o))) 
            severity warning; 

        wait for 100 us;
        heat_i <= '1';
        current_temp_i <= "0111100";    -- 60
        display_select_i <= '1';
         
        wait for 220 ns;
        heat_i <= '0'; 
        
        wait for 100 us;
        display_select_i <= '0';
        current_temp_i <= "1001010";    -- 74
          
        wait for 150 us;  
        furnace_hot_i <= '1';
        
        wait until fan_on_o'event and fan_on_o = '1';
        fan_on_event := now;    
        assert FALSE 
            report "FAN ON event: " & time'image(fan_on_event) 
            severity note;
        
        wait until fan_on_o'event and fan_on_o = '0';
        fan_off_event := now;
        assert FALSE 
            report "FAN OFF event: " & time'image(fan_off_event) 
            severity note;
        time_span := fan_off_event - fan_on_event;
        assert FALSE 
            report "FAN ON to FAN OFF time: " & time'image(time_span) 
            severity note;

        wait for 220 ns;
        furnace_hot_i <= '0';
        
        wait for 100 us;
        display_select_i <= '1';
        current_temp_i <= "1010000";    -- 80

        wait for 200 us;
        cool_i <= '1';
        
        wait until a_c_on_o'event and a_c_on_o = '1';
        ac_on_event := now; 
        assert FALSE 
            report "A/C ON event: " & time'image(ac_on_event) 
            severity note;
        time_span := ac_on_event - fan_on_event;
        assert FALSE 
            report "FAN ON to A/C ON time: " & time'image(time_span) 
            severity note;

        wait for 220 ns;
        cool_i <= '0';
        
        wait for 150 us;
        display_select_i <= '0';
        current_temp_i <= "0111100";    -- 60
        
        wait for 150 us;
        ac_ready_i <= '1';
                      
        -- Wait for A/C OFF event
        wait until a_c_on_o'event and a_c_on_o = '0';
        ac_off_event := now; 
        assert FALSE 
            report "A/C OFF event: " & time'image(ac_off_event) 
            severity note;
        time_span := ac_off_event - ac_on_event;
        assert FALSE 
            report "A/C ON to A/C OFF time: " & time'image(time_span) 
            severity note;
       
        wait for 220 ns;
        ac_ready_i <= '0';

        wait;   -- End of stimulus process to avoid repetition
            
    end process;

end Behavioral;
