library IEEE;
use IEEE.STD_LOGIC_UNISGNED.all;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_1164.all;

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

    -- Type declaration for thermostat and counter state machines.
    type state_type is (state_idle, state_heat_on, state_furnace_hot, state_furnace_cool, state_cool_on, state_ac_ready, state_ac_done);    -- Enumerated data type.

    -- Signal declaration for thermostat and counter state machines,
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

    -- Signal for counter within the state machine. 
    signal countdown             : std_logic_vector(4 downto 0) := "00000";

begin
       
    thermostat_io_reg : process(clk)
    begin
        if clk'event and clk = '1' then
            -- Thermostat input registers.
            current_temp_reg <= current_temp;
            desired_temp_reg <= desired_temp;
            display_select_reg <= display_select;
            cool_reg <= cool;
            heat_reg <= heat;
            furnace_hot_reg <= furnace_hot;
            ac_ready_reg <= ac_ready;
            -- Thermostat output registers.
            a_c_on <= a_c_on_reg;
            furnace_on <= furnace_on_reg;  
            fan_on <= fan_on_reg;   
        end if;
    end process;
    
    -- Clocked sequential logic for the temperature display register.
    thermostat : process (clk)
    begin
        if clk'event and clk = '1' then  -- Any signal assignment done inside a clocked process will result in a flip-flop (register).                   
            if display_select_reg = '1' then
                temp_display_reg <= current_temp_reg;
            else 
                temp_display_reg <= desired_temp_reg;
            end if;
        end if;
    end process;   
    
    -- Thermostat display output register.
    temp_display <= temp_display_reg;

    -- Clocked sequential logic for the next state register.
    next_state : process (clk) 
    begin
        if clk'event and clk = '1' then
            current_state_reg <= next_state_reg;
        end if;
    end process;   
        
    -- Counter within the state machine.
    cntr_clk : process(clk)
    begin
        if clk'event and clk = '1' then
            if next_state_reg = state_furnace_hot then 
                countdown <= std_logic_vector(to_unsigned(16#A#, 5));  -- 10 clock cycles. IEEE.numeric_std.all required to properly assigned the hex value A within the constraints of a 5-bit vector.
--                countdown <= "01010";
            elsif next_state_reg = state_ac_ready then
                countdown <= std_logic_vector(to_unsigned(16#14#, 5)); -- 20 clock cycles
--                countdown <= "10100";
            elsif (next_state_reg = state_furnace_cool) or (next_state_reg = state_ac_done) then
                countdown <= countdown - 1; -- IEEE.std_logic_unsigned.all is required in order to compute countdown - 1.
            end if;
        end if;
    end process;  
    
    -- Thermostat FSM.
    fsm : process (rst, current_state_reg, heat_reg, cool_reg, current_temp_reg, desired_temp_reg, ac_ready_reg, furnace_hot_reg, countdown)
    begin
        if rst = '1' then    
            next_state_reg <= state_idle;   -- We want idle to come out of reset. This way, after reset, we are in a known, safe state. 
        else
            case current_state_reg is
                when state_idle =>
                    if (heat_reg = '1') and (current_temp_reg < desired_temp_reg) then
                        next_state_reg <= state_heat_on;
                    elsif cool_reg = '1' and (current_temp_reg > desired_temp_reg) then
                        next_state_reg <= state_cool_on; 
                    else 
                        next_state_reg <= state_idle;
                    end if;
                when state_heat_on =>
                    if furnace_hot_reg = '1' then
                        next_state_reg <= state_furnace_hot;
                    else
                        next_state_reg <= state_heat_on;
                    end if;
                when state_furnace_hot =>
                    if not((heat_reg = '1') and (current_temp_reg < desired_temp_reg)) then -- Alternatively: if heat_reg /= '1' or current_temp_reg >= desired_temp_reg then
                        next_state_reg <= state_furnace_cool;
                    else
                        next_state_reg <= state_furnace_hot;
                    end if;
                when state_furnace_cool =>
--                    if (furnace_hot_reg = '0' and countdown = "00000") then   -- Observation: the state machine diagramn shows that furnace_hot_reg = '0', but ac_ready_reg = '0' is correct.
                    if (ac_ready_reg = '0') and (countdown = x"0") then
                        next_state_reg <= state_idle;                 
                    else
                        next_state_reg <= state_furnace_cool;
                    end if; 
                when state_cool_on =>
                    if ac_ready_reg = '1' then
                        next_state_reg <= state_ac_ready;   
                    else
                        next_state_reg <= state_cool_on;
                    end if;
                when state_ac_ready =>
                    if not((cool_reg = '1') and (current_temp_reg > desired_temp_reg)) then -- Alternatively: if cool_reg /= '1' or current_temp_reg <= desired_temp_reg then 
                        next_state_reg <= state_ac_done;
                    else
                        next_state_reg <= state_ac_ready;
                    end if;
                when state_ac_done =>
--                    if (ac_ready_reg = '0') and (countdown = x"0") then   -- Observation: the state machine diagramn shows that ac_ready_reg = '0', but furnace_hot_reg = '0' is correct.
                    if (furnace_hot_reg = '0') and (countdown = x"0") then
                        next_state_reg <= state_idle;
                    else
                        next_state_reg <= state_ac_done;
                    end if;
                when others =>
                    next_state_reg <= state_idle;
            end case;
            
--            -- Debug outputs for FSM state and signals 
--            report "FSM State: " & state_type'image(current_state_reg); 
--            report "a_c_on_reg: " & std_logic'image(a_c_on_reg); 
--            report "cool_reg: " & std_logic'image(cool_reg); 
--            report "ac_ready_reg: " & std_logic'image(ac_ready_reg); 
--            report "countdown: " & integer'image(to_integer(unsigned(countdown)));
            
        end if;        
    end process;
    
    -- Thermostat output registers.
    outputs_seq_logic : process(clk)
    begin
        if clk'event and clk = '1' then
            if (next_state_reg = state_heat_on) or (next_state_reg = state_furnace_hot) then
                furnace_on_reg <= '1';
            else
                furnace_on_reg <= '0';
            end if;
            if (next_state_reg = state_cool_on) or (next_state_reg = state_ac_ready) then
                a_c_on_reg <= '1';
            else
                a_c_on_reg <= '0';
            end if;
            if (next_state_reg = state_ac_ready) or (next_state_reg = state_ac_done) or (next_state_reg = state_furnace_hot) or (next_state_reg = state_furnace_cool) then
                fan_on_reg <= '1';
            else
                fan_on_reg <= '0';
            end if;
        end if;
    end process;    
                                
end rtl;

