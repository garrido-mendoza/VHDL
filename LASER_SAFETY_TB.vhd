-------------------------------------------------------------------------------------------------------------
--  Engineer: Diego Garrido-Mendoza
--  Project: Laser Safety - Testbench
--  Company: N/A 
--  File: laser_safety_tb.vhd
--  Date: 08/26/2022
-------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity laser_safety_tb is
end laser_safety_tb;

architecture behavior of laser_safety_tb is

------------------------------------------------------------------------------------------------------
-- Component Declaration
------------------------------------------------------------------------------------------------------ 
component laser_safety is
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
end component;

------------------------------------------------------------------------------------------------------
-- Constant Definitions
------------------------------------------------------------------------------------------------------    
    constant clk_period     : time      := 13.889 ns;   -- system's clock period.
    constant FRAME_SPACING  : integer   := 25000;       --  clks
    
------------------------------------------------------------------------------------------------------
-- Signals
------------------------------------------------------------------------------------------------------    
    -- inputs
    signal clk_in               :   std_logic   := '0';
    signal rst_in               :   std_logic   := '0';
    signal light_src1_in        :   std_logic   := '0'; 
    signal light_src2_in        :   std_logic   := '0';    
    signal period_40pc_in       :   std_logic_vector(23 downto 0);    
    signal safety_disable_in    :   std_logic_vector(0 downto 0) := "0";    
    
    -- outputs
    signal laser_o1             :   std_logic;
    signal laser_o2             :   std_logic;
    signal wd_restart           :   std_logic;    
    
    begin    
    UUT : component laser_safety 
        port map (
            clk                 => clk_in,
            rst                 => rst_in,
            safety_disable      => safety_disable_in,
            period_40pc         => period_40pc_in,
            light_src1          => light_src1_in,
            light_src2          => light_src2_in,
            laser_out1          => laser_o1,
            laser_out2          => laser_o2,
            watchdog_restart    => wd_restart
    );
    
    -- clock generator    
    clk_gen :process
    begin
        clk_in <= '0';
        wait for clk_period/2;
        clk_in <= '1';
        wait for clk_period/2;
    end process clk_gen;

    stimuli :   process
    begin 
    
    ---------------------------------------------------------------------
        period_40pc_in <= x"012C60";   -- clock ticks that set the 1,068us-long 40% off time (40% of the 2670us period). 
--        period_40pc_in <= x"001E0A";   -- clock ticks that set the 106.8us-long 40% off time (40% of the 267us period).
--        period_40pc_in <= x"00E100";    -- clock ticks that set the 800us-long 40% off time (40% of the 2000us period).
--        period_40pc_in <= x"001680";   -- clock ticks that set the 80us-long 40% off time (40% of the 200us period).
    ---------------------------------------------------------------------   
        wait for clk_period*(30*FRAME_SPACING);   
        rst_in        <= '1';
    ---------------------------------------------------------------------  
        wait for clk_period*(10*FRAME_SPACING);    
        light_src1_in <= '1';
    ---------------------------------------------------------------------
        wait for clk_period*(15*FRAME_SPACING);
        light_src2_in <= '1';
    ---------------------------------------------------------------------
        wait for clk_period*(10*FRAME_SPACING);    
        light_src1_in <= '0';
    ---------------------------------------------------------------------
        wait for clk_period*(10*FRAME_SPACING);    
        light_src2_in <= '0';
    --------------------------------------------------------------------- 
        wait for clk_period*(30*FRAME_SPACING);    
        light_src2_in <= '1';
    ---------------------------------------------------------------------
        wait for clk_period*(45*FRAME_SPACING);    
        light_src1_in <= '1';
    ---------------------------------------------------------------------    
        wait for clk_period*(240*FRAME_SPACING);    
        light_src1_in <= '0';
    ---------------------------------------------------------------------
        wait for clk_period*(200*FRAME_SPACING);    
        light_src2_in <= '0';
    ---------------------------------------------------------------------
        wait for clk_period*(100*FRAME_SPACING);    
        light_src2_in <= '1';  
    ---------------------------------------------------------------------
        wait for clk_period*(150*FRAME_SPACING);    
        light_src1_in <= '1';          
    ---------------------------------------------------------------------
        wait for clk_period*(190*FRAME_SPACING);    
        light_src1_in <= '0';
    ---------------------------------------------------------------------
        wait for clk_period*(50*FRAME_SPACING);    
        light_src2_in <= '0';                                             
    --------------------------------------------------------------------- 
        wait for clk_period*(10*FRAME_SPACING);    
        light_src1_in <= '1';
        wait;
    end process stimuli;
    
    end behavior;