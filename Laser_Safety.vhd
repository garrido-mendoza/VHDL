-------------------------------------------------------------------------------------------------------------
--  Engineer: Diego Garrido-Mendoza
--  Project: Laser Safety (DEMO)
--  Company: N/A 
--  File: Laser_Safety.vhd
--  Date: 09/20/2022
-------------------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity Laser_Safety is
	port (
	   clk                 :   in std_logic;   -- clk: 72 MHz clock signal
	   rst                 :   in std_logic;
	   period_40pc         :   in std_logic_vector(23 downto 0);
	   safety_disable      :   in std_logic_vector(0 downto 0);    -- "laser safety disable" port, through which s/w will command bypassing this circuit for rectification.  
	   light_src1          :   in std_logic;   -- light_src1 is the light_src1_en_out signal coming from the image proc. sys ip. it's an active low signal.		
	   light_src2          :   in std_logic;
	   laser_out1	       :   out std_logic;
	   laser_out2          :   out std_logic;
	   watchdog_restart    :   out std_logic        
	);
end Laser_Safety;
			
architecture behavior of Laser_Safety is

------------------------------------------------------------------------------------------------------
-- Constant Definitions
------------------------------------------------------------------------------------------------------
constant wd_restart_spacing     :   integer := 9E6; -- 120 milliseconds (ms)
constant wd_restart_ms          :   integer := 10;  -- 10 milliseconds (ms)
constant wd_restart_width       :   integer := wd_restart_ms*72E3; 

------------------------------------------------------------------------------------------------------
-- Type Declarations
------------------------------------------------------------------------------------------------------
-- laser safety & watchdog fsm
type laser_safety_fsm_1 is (s0_1, s1_1, s2_1, s0_A_1, s1_A_1, s2_A_1);  -- watchdog & laser safety fsm 1 states
type laser_safety_fsm_2 is (s0_2, s1_2, s2_2, s0_A_2, s1_A_2, s2_A_2);  -- watchdog & laser safety fsm 2 states
	   
------------------------------------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------------------------------------
-- laser safety inputs
signal light_src1_i     :   std_logic;
signal light_src2_i     :   std_logic;
signal rst_i            :   std_logic;
signal safety_disable_i :   std_logic_vector(0 downto 0);
signal period_40pc_i    :   std_logic_vector(23 downto 0);

-- laser safety outputs
signal laser_o1         :   std_logic; 
signal laser_o2         :   std_logic; 

-- light source 1 state machine
signal laser_duty_state_reg_1   :   laser_safety_fsm_1;
signal laser_duty_state_next_1  :   laser_safety_fsm_1;
signal period_cntr_1            :   std_logic_vector(31 downto 0);
signal period_cntr_next_1       :   std_logic_vector(31 downto 0);
signal period_cntr_inc_1        :   std_logic;
signal period_cntr_clr_1        :   std_logic;
signal period_cntr_last_60_1    :   std_logic;
signal period_cntr_last_40_1    :   std_logic; 
signal pc_cntr_sel_1            :   std_logic;  

-- light source 2 state machine
signal laser_duty_state_reg_2   :   laser_safety_fsm_2;
signal laser_duty_state_next_2  :   laser_safety_fsm_2;
signal period_cntr_2            :   std_logic_vector(31 downto 0);
signal period_cntr_next_2       :   std_logic_vector(31 downto 0);
signal period_cntr_inc_2        :   std_logic;
signal period_cntr_clr_2        :   std_logic;
signal period_cntr_last_60_2    :   std_logic;
signal period_cntr_last_40_2    :   std_logic;                   
signal pc_cntr_sel_2            :   std_logic;

-- watchdog counter
signal wd_cntr                  :   std_logic_vector(31 downto 0);
signal wd_cntr_next             :   std_logic_vector(31 downto 0);

-- laser watchdog 1 state machine
signal wd_cntr_inc_1            :   std_logic;
signal wd_cntr_clr_1            :   std_logic;
signal wd_cntr_last_1           :   std_logic;

-- laser watchdog 2 state machine
signal wd_cntr_inc_2            :   std_logic;
signal wd_cntr_clr_2            :   std_logic;
signal wd_cntr_last_2           :   std_logic;

-- laser watchdog outputs
signal wd_restart_1             :   std_logic; 
signal wd_restart_2             :   std_logic; 
signal wd_restart               :   std_logic; 

-- frame rate configuration
signal period_20pc_i            :   std_logic_vector(23 downto 0);
signal period_60pc_i            :   std_logic_vector(23 downto 0);
signal period_100pc             :   std_logic_vector(23 downto 0);
signal frame_period             :   integer;

-- watchdog restart pulse stretcher (~10ms)
signal flag                     :   std_logic;
signal stretch_cntr_set         :   std_logic;
signal stretched_wd_restart_out :   std_logic;
signal stretch_cntr_clr         :   std_logic;
signal stretch_cntr_last        :   std_logic;
signal stretch_cntr_inc         :   std_logic;
signal stretch_cntr             :   std_logic_vector(31 downto 0); 
signal stretch_cntr_next        :   std_logic_vector(31 downto 0);
---------------------------------------------------------------------------------------------------------------------------

begin
    rst_i               <= not rst;
    light_src1_i        <= light_src1;
    light_src2_i        <= light_src2; 
    period_40pc_i       <= period_40pc;
    safety_disable_i    <= safety_disable;
    watchdog_restart    <= stretched_wd_restart_out;    
    
---------------------------------------------------------------------------------------------------------------------------
-- *** FRAME RATE CONFIGURATION
---------------------------------------------------------------------------------------------------------------------------     
    period_20pc_i   <= "0" & period_40pc_i(23 downto 1);    -- dgm 09/14/22: d40 = b101000 shifted one bit to the left is d20 = b10100.
    period_60pc_i   <= period_40pc_i + period_20pc_i;   

    period_100pc    <= period_60pc_i + period_40pc_i;
    frame_period    <= to_integer(unsigned(period_100pc));
               
---------------------------------------------------------------------------------------------------------------------------
-- *** LIGHT SOURCE 1, LASER LINE
---------------------------------------------------------------------------------------------------------------------------  
    -- light source 1 duty state register update
    state_reg_update_1: process(clk,rst_i)
    begin
        if (clk'event and clk = '1') then
            if (rst_i = '1') then
                laser_duty_state_reg_1 <= s0_1; 
            else
                laser_duty_state_reg_1 <= laser_duty_state_next_1;
            end if;
        end if;
    end process state_reg_update_1;

    -- light source 1 next-state logic
    next_state_update_1: process(laser_duty_state_reg_1,rst_i,light_src1_i,
                                wd_cntr_last_1,period_cntr_last_60_1,period_cntr_last_40_1)
    begin

        period_cntr_inc_1   <= '0';
        period_cntr_clr_1   <= '0';
        pc_cntr_sel_1       <= '0';
        laser_o1            <= '0';
        wd_cntr_inc_1       <= '0';
        wd_cntr_clr_1       <= '0';
        wd_restart_1        <= '0'; 

        if (rst_i = '1') then
            laser_duty_state_next_1 <= s0_1;
        else
            case laser_duty_state_reg_1 is
                when s0_1 =>    -- idle
                    if (wd_cntr_last_1 = '1') then
                        laser_o1                <= '0';
                        wd_cntr_clr_1           <= '1';
                        wd_restart_1            <= '1';  
                        laser_duty_state_next_1 <= s0_A_1;  -- s0_A_1: watchdog pulse
                    elsif (light_src1_i = '1') then                    
                        period_cntr_clr_1       <= '1'; 
                        pc_cntr_sel_1           <= '0';
                        laser_o1                <= '1';
                        wd_cntr_inc_1           <= '1';
                        laser_duty_state_next_1 <= s1_1;    -- s1_1: 60% timer                       
                    else
                        laser_o1                <= '0';
                        wd_cntr_inc_1           <= '1';  
                        laser_duty_state_next_1 <= s0_1;    -- s0_1: idle
                    end if;
                when s0_A_1 =>  -- watchdog pulse                      
                    if (light_src1_i = '1') then
                        period_cntr_clr_1       <= '1'; -- clear the 60% timer to begin counting from 0, exactly when the light source turns on. 
                        pc_cntr_sel_1           <= '0'; -- the 40% off time pulse is not generated yet; the light source is on, which triggers the 60% timer. 
                        laser_o1                <= '1'; -- laser output is active and running at 60% duty cycle
                        wd_cntr_inc_1           <= '1'; -- intention: begin generating a 60% wide pulse exactly when the light source is asserted. this pulse is then used to generate the laser output signal.
                        wd_restart_1            <= '0'; -- do not restart the watchdog counter when it must be incrementing. 
                        laser_duty_state_next_1 <= s1_1;    -- s1_1: 60% timer 
                    else
                        laser_o1                <= '0';                        
                        wd_cntr_inc_1           <= '1';
                        wd_restart_1            <= '0';
                        laser_duty_state_next_1 <= s0_1;    -- s0_1: idle
                    end if;                                                                
                when s1_1 =>    --s1_1: 60% timer
                    if (wd_cntr_last_1 = '1') then
                        period_cntr_inc_1       <= '1';
                        pc_cntr_sel_1           <= '0';
                        laser_o1                <= '1';
                        wd_cntr_clr_1           <= '1'; -- the assertion of the light source also causes the watchdog counter to restart. 
                        wd_restart_1            <= '1';
                        laser_duty_state_next_1 <= s1_A_1;    -- s0_1: idle                
                    elsif (light_src1_i = '0') or (period_cntr_last_60_1 = '1') then    -- this enforces the 40% off time when light source is de-asserted (goes inactive, low)
                        period_cntr_clr_1       <= '1'; -- clear to begin counting from 0
                        pc_cntr_sel_1           <= '1'; -- begin generating the 40% pulse
                        laser_o1                <= '0'; -- keep the laser output off for this 40% off time
                        wd_cntr_inc_1           <= '1'; -- begin generating the 125ms wide wd restart pulse. 
                        laser_duty_state_next_1 <= s2_1;    --s2_1: 40% timer                  
                    else
                        period_cntr_inc_1       <= '1';
                        pc_cntr_sel_1           <= '0';
                        laser_o1                <= '1';
                        wd_cntr_inc_1           <= '1';
                        laser_duty_state_next_1 <= s1_1;    --s1_1: 60% timer
                    end if;                  
                when s1_A_1 =>
                    if (light_src1_i = '1') and (period_cntr_last_60_1 = '0') then
                        period_cntr_inc_1       <= '1';
                        pc_cntr_sel_1           <= '0';
                        laser_o1                <= '1';
                        wd_cntr_inc_1           <= '1';
                        wd_restart_1            <= '0';
                        laser_duty_state_next_1 <= s1_1;
                    else
                        period_cntr_clr_1       <= '1';
                        pc_cntr_sel_1           <= '1';
                        laser_o1                <= '0';
                        wd_cntr_inc_1           <= '1';
                        wd_restart_1            <= '0';
                        laser_duty_state_next_1 <= s2_1;
                    end if;                            
                when s2_1 =>    --s2_1: 40% timer                     
                    if (wd_cntr_last_1 = '1') then
                        period_cntr_inc_1       <= '1';
                        pc_cntr_sel_1           <= '1';
                        laser_o1                <= '0';
                        wd_cntr_clr_1           <= '1'; 
                        wd_restart_1            <= '1';
                        laser_duty_state_next_1 <= s2_A_1;    -- s0_1: idle                     
                    elsif (light_src1_i = '1') and (period_cntr_last_40_1 = '1') then
                        period_cntr_clr_1       <= '1';
                        pc_cntr_sel_1           <= '0';
                        laser_o1                <= '1';
                        wd_cntr_inc_1           <= '1';
                        laser_duty_state_next_1 <= s1_1;    --s1_1: 60% timer
                    elsif (period_cntr_last_40_1 = '1') then  -- dgm 6/5/22: this activates the 40% time off enforcement. 
                        period_cntr_clr_1       <= '1';
                        pc_cntr_sel_1           <= '0';
                        laser_o1                <= '0';
                        wd_cntr_inc_1           <= '1';
                        laser_duty_state_next_1 <= s0_1;    -- s0_1: idle                  
                    else
                        period_cntr_inc_1       <= '1';
                        pc_cntr_sel_1           <= '1';
                        laser_o1                <= '0';
                        wd_cntr_inc_1           <= '1';
                        laser_duty_state_next_1 <= s2_1;    --s2_1: 40% timer
                    end if;
                when s2_A_1 =>    --s2_A_1: watchdog pulse
                    if (period_cntr_last_40_1 = '1') then
                        period_cntr_clr_1       <= '1';
                        pc_cntr_sel_1           <= '0';
                        laser_o1                <= '0';
                        wd_cntr_inc_1           <= '1';
                        wd_restart_1            <= '0';
                        laser_duty_state_next_1 <= s0_1; 
                    else
                        period_cntr_inc_1       <= '1';
                        pc_cntr_sel_1           <= '1';
                        laser_o1                <= '0';
                        wd_cntr_inc_1           <= '1';
                        wd_restart_1            <= '0';
                        laser_duty_state_next_1 <= s2_1; 
                    end if;                                                                                                                      
            end case;
        end if;
    end process next_state_update_1;  
                   
    -- light source 1 period counter update
    period_cntr_update_1: process(clk,rst_i)
    begin
        if (clk'event and clk = '1') then
            if (rst_i = '1') then
                period_cntr_1 <= (others => '0');
            else
                period_cntr_1 <= period_cntr_next_1;
            end if;
        end if;
    end process period_cntr_update_1;

    -- light source 1 period cntr next state
    period_cntr_next_1 <=   (others => '0')       when period_cntr_clr_1 = '1' else
                            period_cntr_1 + 1     when period_cntr_inc_1 = '1' else
                            period_cntr_1;
    
    -- light source 1 last period count and comparator logic
    period_cntr_last_60_1 <=    '1'              when period_cntr_1 = period_60pc_i else 
                                '0';                     
    period_cntr_last_40_1 <=    '1'              when period_cntr_1 = period_40pc_i else 
                                '0';  
                                                       
---------------------------------------------------------------------------------------------------------------------------
-- *** LASER OUTPUT 1
---------------------------------------------------------------------------------------------------------------------------                                       
    -- gated light source 1 output
    laser_out1  <=  light_src1_i when safety_disable_i = "1" else   -- when safety_disable_i = 0: enable, 'modified'
                    laser_o1;                                       -- when safety_disable_i = 1: disable, 'pass-through'             
                                 
---------------------------------------------------------------------------------------------------------------------------
-- *** LIGHT SOURCE 2, LASER DOTS
---------------------------------------------------------------------------------------------------------------------------                               
    -- light source 2 duty state register update
    state_reg_update_2: process(clk,rst_i)
    begin
        if (clk'event and clk = '1') then
            if (rst_i = '1') then
                laser_duty_state_reg_2 <= s0_2; 
            else
                laser_duty_state_reg_2 <= laser_duty_state_next_2;
            end if;
        end if;
    end process state_reg_update_2;  

---------------------------------------------------------------------------------------------------------------------------  
   -- light source 2 next-state logic
    next_state_update_2: process(laser_duty_state_reg_2,rst_i,light_src2_i,
                                wd_cntr_last_2,period_cntr_last_60_2,period_cntr_last_40_2)
    begin

        period_cntr_inc_2   <= '0';
        period_cntr_clr_2   <= '0';
        pc_cntr_sel_2       <= '0';
        laser_o2            <= '0';
        wd_cntr_inc_2       <= '0';
        wd_cntr_clr_2       <= '0';
        wd_restart_2        <= '0';          

        if (rst_i = '1') then
            laser_duty_state_next_2 <= s0_2;
        else
            case laser_duty_state_reg_2 is
                when s0_2 =>    -- idle
                   if (wd_cntr_last_2 = '1') then   -- the light source is off but the watchdog counter is running. if it's done counting, then wd_cntr_last is asserted. 
                        laser_o2                <= '0'; -- the light source is off; the laser output must remain off. 
                        wd_cntr_clr_2           <= '1'; -- one clock cycle long clear pulse. if the watchdog (wd) counter is done, one clock cycle later, it gets cleared to begin counting again (for 9E6 clock cycles). 
                        wd_restart_2            <= '1'; -- flag that gets generated along with the "wd counter clear" and "wd counter last" pulse, 
                        laser_duty_state_next_2 <= s0_A_2;  -- s0_A_2: watchdog pulse
                    elsif (light_src2_i = '1') then                    
                        period_cntr_clr_2       <= '1'; 
                        pc_cntr_sel_2           <= '0';
                        laser_o2                <= '1';
                        wd_cntr_inc_2           <= '1';
                        laser_duty_state_next_2 <= s1_2;    -- s1_1: 60% timer                       
                    else
                        laser_o2                <= '0';
                        wd_cntr_inc_2           <= '1';  
                        laser_duty_state_next_2 <= s0_2;    -- s0_1: idle
                    end if;
                when s0_A_2 =>                      
                    if (light_src2_i = '1') then
                        period_cntr_clr_2       <= '1';
                        pc_cntr_sel_2           <= '0';
                        laser_o2                <= '1';
                        wd_cntr_inc_2           <= '1';
                        wd_restart_2            <= '0';
                        laser_duty_state_next_2 <= s1_2;    -- s1_1: 60% timer 
                    else
                        laser_o2                <= '0';                        
                        wd_cntr_inc_2           <= '1';
                        wd_restart_2            <= '0';
                        laser_duty_state_next_2 <= s0_2;    -- s0_1: idle
                    end if;                                              
                when s1_2 =>    --s1_2: 60% timer
                    if (wd_cntr_last_2 = '1') then
                        period_cntr_inc_2       <= '1';
                        pc_cntr_sel_2           <= '0';
                        laser_o2                <= '1';
                        wd_cntr_clr_2           <= '1';
                        wd_restart_2            <= '1';
                        laser_duty_state_next_2 <= s1_A_2;    -- s1_A_2: watchdog pulse               
                    elsif (light_src2_i = '0') or (period_cntr_last_60_2 = '1') then
                        period_cntr_clr_2       <= '1';
                        pc_cntr_sel_2           <= '1';
                        laser_o2                <= '0';
                        wd_cntr_inc_2           <= '1';
                        laser_duty_state_next_2 <= s2_2;    --s2_2: 40% timer               
                    else
                        period_cntr_inc_2       <= '1';
                        pc_cntr_sel_2           <= '0';
                        laser_o2                <= '1';
                        wd_cntr_inc_2           <= '1';
                        laser_duty_state_next_2 <= s1_2;    --s1_2: 60% timer
                    end if;                  
                when s1_A_2 =>
                    if (light_src2_i = '1') and (period_cntr_last_60_2 = '0') then
                        period_cntr_inc_2       <= '1';
                        pc_cntr_sel_2           <= '0';
                        laser_o2                <= '1';
                        wd_cntr_inc_2           <= '1';
                        wd_restart_2            <= '0';
                        laser_duty_state_next_2 <= s1_2;
                    else
                        period_cntr_clr_2       <= '1';
                        pc_cntr_sel_2           <= '1';
                        laser_o2                <= '0';
                        wd_cntr_inc_2           <= '1';
                        wd_restart_2            <= '0';
                        laser_duty_state_next_2 <= s2_2;
                    end if;                  
                when s2_2 =>    --s2_2: 40% timer                     
                    if (wd_cntr_last_2 = '1') then
                        period_cntr_inc_2       <= '1';
                        pc_cntr_sel_2           <= '1';
                        laser_o2                <= '0';
                        wd_cntr_clr_2           <= '1'; 
                        wd_restart_2            <= '1';
                        laser_duty_state_next_2 <= s2_A_2;    -- s2_A_2: watchdog pulse 
                    elsif (light_src2_i = '1') and (period_cntr_last_40_2 = '1') then
                        period_cntr_clr_2       <= '1';
                        pc_cntr_sel_2           <= '0';
                        laser_o2                <= '1';
                        wd_cntr_inc_2           <= '1';
                        laser_duty_state_next_2 <= s1_2;    --s1_2: 60% timer 
                    elsif (period_cntr_last_40_2 = '1') then  -- dgm 6/5/22: activates the 40% time off enforcement. 
                        period_cntr_clr_2       <= '1';
                        pc_cntr_sel_2           <= '0';
                        laser_o2                <= '0';
                        wd_cntr_inc_2           <= '1';
                        laser_duty_state_next_2 <= s0_2;    -- s0_2: idle                  
                    else
                        period_cntr_inc_2       <= '1';
                        pc_cntr_sel_2           <= '1';
                        laser_o2                <= '0';
                        wd_cntr_inc_2           <= '1';
                        laser_duty_state_next_2 <= s2_2;    --s2_2: 40% timer
                    end if;
                when s2_A_2 =>    --s2_A_2: watchdog pulse
                    if (period_cntr_last_40_2 = '1') then
                        period_cntr_clr_2       <= '1';
                        pc_cntr_sel_2           <= '0';
                        laser_o2                <= '0';
                        wd_cntr_inc_2           <= '1';
                        wd_restart_2            <= '0';
                        laser_duty_state_next_2 <= s0_2;
                    else
                        period_cntr_inc_2       <= '1';
                        pc_cntr_sel_2           <= '1';
                        laser_o2                <= '0';
                        wd_cntr_inc_2           <= '1';
                        wd_restart_2            <= '0';
                        laser_duty_state_next_2 <= s2_2;
                    end if;                                                                                                                      
            end case;
        end if;
    end process next_state_update_2;

    -- light source 2 period counter update
    period_cntr_update_2: process(clk,rst_i)
    begin
        if (clk'event and clk = '1') then
            if (rst_i = '1') then
                period_cntr_2 <= (others => '0');
            else
                    period_cntr_2 <= period_cntr_next_2;
            end if;
        end if;
    end process period_cntr_update_2;    

    -- light source 2 period cntr next state logic
    period_cntr_next_2  <=  (others => '0')       when period_cntr_clr_2 = '1' else
                            period_cntr_2 + 1     when period_cntr_inc_2 = '1' else
                            period_cntr_2;
    
    -- light source 2 last period count and comparator logic
    period_cntr_last_60_2 <=    '1'               when period_cntr_2 = period_60pc_i else
                                '0';                      
    period_cntr_last_40_2 <=    '1'               when period_cntr_2 = period_40pc_i else                                           
                                '0';               
                                
---------------------------------------------------------------------------------------------------------------------------
-- *** LASER OUTPUT 2
---------------------------------------------------------------------------------------------------------------------------                                      
    -- gated light source 2 output    
    laser_out2  <=  light_src2_i when safety_disable_i = "1" else   -- when safety_disable_i = 0: enable, 'modified'
                    laser_o2;                                       -- when safety_disable_i = 1: disable, 'pass-through'  
    
---------------------------------------------------------------------------------------------------------------------------
-- *** WATCHDOG COUNTER
---------------------------------------------------------------------------------------------------------------------------  

    -- watchdog counter update
    wd_cntr_update: process(clk,rst_i)
    begin
        if (clk'event and clk = '1') then
                if (rst_i = '1') then
                    wd_cntr <= (others => '0');
                else
                    wd_cntr <= wd_cntr_next;
                end if;
            end if;
    end process wd_cntr_update;

    wd_cntr_next    <=  (others => '0')     when wd_cntr_clr_1 = '1' and wd_cntr_clr_2 = '1' else 
                        wd_cntr + 1         when wd_cntr_inc_1 = '1' and wd_cntr_inc_2 = '1' else
                        wd_cntr;

    wd_cntr_last_1  <=  '1'                 when wd_cntr = wd_restart_spacing else    -- wd_restart_spacing = 9E6 clock cycles -> ~120ms.    
                        '0';

    wd_cntr_last_2  <=  '1'                 when wd_cntr = wd_restart_spacing else    -- wd_restart_spacing = 9E6 clock cycles -> ~120ms.    
                        '0';
    
    -- remember: only two exists from S0: (1) light_srcN is true, or (2) wd_cntr_last is true. 
  
---------------------------------------------------------------------------------------------------------------------------
-- *** WATCHDOG RESTART PULSE
---------------------------------------------------------------------------------------------------------------------------                     
    -- when the wd_cntr_last pulses arrive to the watchdog state machine, 
    -- the pulses wd_restart1 and wd_restart2 get generated in the same 
    -- clock cycle in which "last" arrives.    

    wd_restart  <= wd_restart_1 and wd_restart_2;

---------------------------------------------------------------------------------------------------------------------------
-- *** WATCHDOG RESTART PULSE STRETCHER
---------------------------------------------------------------------------------------------------------------------------  
    stretch_cntr_set    <= '1' when (wd_restart_1 = '1') and (wd_restart_2 = '1') else       -- AND gate output; 'stretch_cntr_set' is the set input (S)
                           '0';

    sr_ff: process(clk) -- set/reset flip flop: when S is '1', the output Q is set to '1', and when R is '1', the output is reset to '0'.
                        -- restriction: S & R shall not both be '1' at the same time; if they are, the output value is not specified (violation).
    begin
        if (clk'event and clk = '1') then
            if ((rst_i = '1') or (stretch_cntr_clr = '1')) then -- rst_i or stretch_cntr_clr corresponds to the reset input (R)
                flag <= '0';    -- Q = '0'; 'flag' is the output of the SR flip-flop (Q)
            elsif (stretch_cntr_set = '1') then -- 'stretch_cntr_set' is the set input (S)
                flag <= '1';    -- Q = '1'.
            end if;
        end if;
    end process sr_ff;

    stretch_cntr_clr <= stretch_cntr_last;      
    stretch_cntr_inc <= flag;

    stretch_cntr_update: process(clk)
    begin
        if (clk'event and clk =  '1') then
            if (rst_i = '1') then
                stretch_cntr <= (others => '0');
            else
                stretch_cntr <= stretch_cntr_next;
            end if;
        end if;
    end process stretch_cntr_update;

    -- stretch_cntr next state logic
    stretch_cntr_next <= (others => '0')    when stretch_cntr_clr = '1' else
                         stretch_cntr + 1   when stretch_cntr_inc = '1' else
                         stretch_cntr;

    stretch_cntr_last <= '1'  when stretch_cntr = wd_restart_width else
                         '0';

    stretched_wd_restart_out <= flag;
         	                                 
end behavior;		
