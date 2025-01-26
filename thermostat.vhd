library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--------------------------------------------------------------------------------- 
-- Example 1 - THERMOSTAT LOGIC USING COMBINATORIAL LOGIC
--------------------------------------------------------------------------------- 
--entity thermostat is
--  port (    current_temp    : in bit_vector(6 downto 0);
--            desired_temp    : in bit_vector(6 downto 0);
--            display_select  : in bit;
--            cool            : in bit;  -- Switch that indicates when the operator wants the a/c to come on. 
--            heat            : in bit;  -- This heat bit will come on when the operator wants the furnace to come on.
--            temp_display    : out bit_vector(6 downto 0);
--            a_c_on          : out bit;   -- The a/c only comes on if the current temperature is greater than the desired temperature.
--            furnace_on      : out bit);  -- The furnace should come on only if the current temperature is less than the desired temperature. 
--end thermostat;

--architecture Behavioral of thermostat is

--signal temp_display_o : bit_vector(6 downto 0);
--signal a_c_on_o : bit;
--signal furnace_on_o : bit;

--begin

--    -- Combinatorial logic for the temperature display.
--    thermostat : process(current_temp, desired_temp, display_select)
--    begin
--        if display_select = '1' then
--            temp_display_o <= current_temp;
--        else 
--            temp_display_o <= desired_temp;
--        end if;
--    end process;
    
--    temp_display <= temp_display_o;
    
--    -- Combinatorial logic for the a/c.
--    cool_ac : process(current_temp, desired_temp, cool)
--    begin
--        if cool = '1' and (current_temp > desired_temp) then
--            a_c_on_o <= '1';
--        else 
--            a_c_on_o <= '0';
--        end if;
--    end process;
    
--    a_c_on <= a_c_on_o;
    
--    -- Combinatorial logic for the furnace.
--    furnace : process(current_temp, desired_temp, heat)
--    begin
--        if heat = '1' and (current_temp < desired_temp) then
--            furnace_on_o <= '1';
--        else 
--            furnace_on_o <= '0';
--        end if;
--    end process;    
    
--    furnace_on <= furnace_on_o;        

--end Behavioral;


--------------------------------------------------------------------------------- 
-- Example 2 - THERMOSTAT LOGIC USING COMBINATORIAL LOGIC & CLOCKED PROCESSES
---------------------------------------------------------------------------------
entity thermostat is
  port (    clk             : in bit;
            rst             : in bit;
            current_temp    : in bit_vector(6 downto 0);
            desired_temp    : in bit_vector(6 downto 0);
            display_select  : in bit;
            cool            : in bit;  -- Switch that indicates when the operator wants the a/c to come on. 
            heat            : in bit;  -- This heat bit will come on when the operator wants the furnace to come on.
            temp_display    : out bit_vector(6 downto 0);
            a_c_on          : out bit;   -- The a/c only comes on if the current temperature is greater than the desired temperature.
            furnace_on      : out bit);  -- The furnace should come on only if the current temperature is less than the desired temperature. 
end thermostat;

architecture rtl of thermostat is

-- Input register signals
signal current_temp_reg : bit_vector(6 downto 0);
signal desired_temp_reg : bit_vector(6 downto 0);
signal display_select_reg : bit;
signal cool_reg : bit;
signal heat_reg : bit;

-- Output register signals
signal temp_display_reg : bit_vector(6 downto 0);
signal a_c_on_reg : bit;
signal furnace_on_reg : bit;

begin

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
    
    -- Thermostat output register
    temp_display <= temp_display_reg;
    
    -- Clocked combinatorial logic for the a/c.
    cool_ac_clk : process (clk, rst)
    begin
        if rst = '1' then
            a_c_on_reg <= '0';
        elsif clk'event and clk = '1' then  -- Any signal assignment done inside a clocked process will result in a flip-flop (register).
            cool_reg <= cool;    
            if cool_reg = '1' and (current_temp_reg > desired_temp_reg) then
                a_c_on_reg <= '1';
            else 
                a_c_on_reg <= '0';
            end if;
        end if;
    end process;

    -- Combinatorial logic for the A/C.
    a_c_on <= a_c_on_reg;
    
    furnace_clk : process (clk, rst)
    begin
        if rst = '1' then
            furnace_on_reg <= '0';
        elsif clk'event and clk = '1' then  -- Any signal assignment done inside a clocked process will result in a flip-flop (register).
            heat_reg <= heat;   
            if heat_reg = '1' and (current_temp_reg < desired_temp_reg) then
                furnace_on_reg <= '1';
            else 
                furnace_on_reg <= '0';
            end if;
        end if;
    end process;    
    
    -- Combinatorial logic for the furnace.
    furnace_on <= furnace_on_reg;        

end rtl;
