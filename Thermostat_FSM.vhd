library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Thermostat is
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
end Thermostat;

architecture rtl of Thermostat is

    -- Type declaration for state machine
    type state_type is (state_idle, state_heat_on, state_furnace_hot, state_furnace_cool, state_cool_on, state_ac_ready, state_ac_done);    -- Enumerated data type.

    -- Signal declaration for state machine
    signal current_state_reg : state_type;
    signal next_state_reg    : state_type;

    -- Input register signals
    signal current_temp_reg      : std_logic_vector(6 downto 0);
    signal desired_temp_reg      : std_logic_vector(6 downto 0);
    signal display_select_reg    : std_logic;
    signal cool_reg              : std_logic;
    signal heat_reg              : std_logic;
    signal furnace_hot_reg       : std_logic; 
    signal ac_ready_reg          : std_logic;

    -- Output register signals
    signal temp_display_reg      : std_logic_vector(6 downto 0);
    signal a_c_on_reg            : std_logic;
    signal furnace_on_reg        : std_logic;
    signal fan_on_reg            : std_logic;

begin
    
    -- Thermostat input signal registers.
    cool_reg <= cool;
    heat_reg <= heat;
    furnace_hot_reg <= furnace_hot;
    ac_ready_reg <= ac_ready;
    
    -- Clocked combinatorial logic for the temperature display.
    thermostat_clk : process (clk, rst)
    begin
        if rst = '1' then
            temp_display_reg <= (others => '0');
        elsif clk'event and clk = '1' then  -- Any signal assignment done inside a clocked process will result in a flip-flop (register).
            current_temp_reg <= current_temp;
            desired_temp_reg <= desired_temp;
            display_select_reg <= display_select;        
            if display_select_reg = '1' then
                temp_display_reg <= current_temp_reg;
            else 
                temp_display_reg <= desired_temp_reg;
            end if;
        end if;
    end process;   
    
    -- Thermostat display output register
    temp_display <= temp_display_reg;
    
    -- Clocked combinatorial logic for the next state register.
    next_state_reg_clk : process (clk, rst)
    begin
        if rst = '1' then
            current_state_reg <= state_idle;
        elsif clk'event and clk = '1' then
            current_state_reg <= next_state_reg;
        end if;
    end process;    
    
    -- Thermostat FSM.
    fsm : process (current_state_reg, heat_reg, cool_reg, current_temp_reg, desired_temp_reg, ac_ready_reg, furnace_hot_reg)
    begin
        furnace_on_reg <= '0';
        a_c_on_reg <= '0';
        fan_on_reg <= '0';
        
        if rst = '1' then 
            next_state_reg <= state_idle;
        else
            case current_state_reg is
                when state_idle =>
                    if heat_reg = '1' and (current_temp_reg < desired_temp_reg) then
                        next_state_reg <= state_heat_on;
                    elsif cool_reg = '1' and (current_temp_reg > desired_temp_reg) then
                        next_state_reg <= state_cool_on;
                        furnace_on_reg <= '0';
                        a_c_on_reg <= '0';
                        fan_on_reg <= '0';    
                    else 
                        next_state_reg <= state_idle;
                    end if;
                when state_cool_on =>
                    if ac_ready_reg = '1' then
                        next_state_reg <= state_ac_ready;
                        furnace_on_reg <= '0';
                        a_c_on_reg <= '1';
                        fan_on_reg <= '0';     
                    else
                        next_state_reg <= state_cool_on;
                    end if;
                when state_ac_ready =>
--                    if not(cool_reg = '1' and (current_temp_reg > desired_temp_reg)) then
                    if cool_reg /= '1' or current_temp_reg <= desired_temp_reg then   
                        next_state_reg <= state_ac_done;
                        furnace_on_reg <= '0';
                        a_c_on_reg <= '1';
                        fan_on_reg <= '1';
                    else
                        next_state_reg <= state_ac_ready;
                    end if;
                when state_ac_done =>
                    if ac_ready_reg = '0' then
                        next_state_reg <= state_idle;
                        furnace_on_reg <= '0';
                        a_c_on_reg <= '0';
                        fan_on_reg <= '1';
                    else
                        next_state_reg <= state_ac_done;
                    end if;
                when state_heat_on =>
                    if furnace_hot_reg = '1' then
                        next_state_reg <= state_furnace_hot;     
                        furnace_on_reg <= '1';
                        a_c_on_reg <= '0';
                        fan_on_reg <= '0';
                    else
                        next_state_reg <= state_heat_on;
                    end if;
                when state_furnace_hot =>
--                    if not(heat_reg = '1' and (current_temp_reg < desired_temp_reg)) then 
                    if heat_reg /= '1' or current_temp_reg >= desired_temp_reg then   
                        next_state_reg <= state_furnace_cool;
                        furnace_on_reg <= '1';
                        a_c_on_reg <= '0';
                        fan_on_reg <= '1';
                    else
                        next_state_reg <= state_furnace_hot;
                    end if;
                when state_furnace_cool =>
                    if furnace_hot_reg = '0' then
                        next_state_reg <= state_idle;
                        furnace_on_reg <= '0';
                        a_c_on_reg <= '0';
                        fan_on_reg <= '1';                        
                    else
                        next_state_reg <= state_furnace_cool;
                    end if; 
                when others =>
                    next_state_reg <= state_idle;
            end case;
        end if;        
    end process;
    
    -- Thermostat output registers.
    a_c_on <= a_c_on_reg;
    furnace_on <= furnace_on_reg;  
    fan_on <= fan_on_reg;                                  

end rtl;

