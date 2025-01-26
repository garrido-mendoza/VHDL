library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use std.textio.all; -- Import TextIO package

entity TB_Parallel_FIR_Filter is
end TB_Parallel_FIR_Filter;

architecture testbench of TB_Parallel_FIR_Filter is
    -- Component declaration
    component Parallel_FIR_Filter is
        Generic (
            FILTER_TAPS  : integer := 60;
            INPUT_WIDTH  : integer range 8 to 25 := 24;
            COEFF_WIDTH  : integer range 8 to 18 := 16;
            OUTPUT_WIDTH : integer range 8 to 43 := 24
        );
        Port (
            clk    : in STD_LOGIC;
            reset  : in STD_LOGIC;
            enable : in STD_LOGIC;
            data_i : in STD_LOGIC_VECTOR (INPUT_WIDTH-1 downto 0);
            data_o : out STD_LOGIC_VECTOR (OUTPUT_WIDTH-1 downto 0)
        );
    end component;

    -- Signals for driving the DUT
    signal clk    : STD_LOGIC := '0';
    signal reset  : STD_LOGIC := '0';
    signal enable : STD_LOGIC := '1';
    signal data_i : STD_LOGIC_VECTOR (23 downto 0) := (others => '0');
    signal data_o : STD_LOGIC_VECTOR (23 downto 0);

    -- Clock period definition
    constant clk_period : time := 10 ns;

    -- File for output
    file output_file : text open write_mode is "sine_wave_output.txt";

begin
    -- Instantiate the Unit Under Test (UUT)
    uut: Parallel_FIR_Filter
        Generic map (
            FILTER_TAPS => 60,
            INPUT_WIDTH => 24,
            COEFF_WIDTH => 16,
            OUTPUT_WIDTH => 24
        )
        Port map (
            clk    => clk,
            reset  => reset,
            enable => enable,
            data_i => data_i,
            data_o => data_o
        );

    -- Clock generation
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end process;

    -- Stimulus process
    stim_proc: process
        variable t : real := 0.0;
        variable sine_wave_real : real := 0.0;
        variable sine_wave_int : integer := 0;
        variable int_data_i : integer;
        variable l : line; -- Line for TextIO
    begin
        -- Initialize inputs
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        wait for clk_period * 2;

        -- Apply a sine wave input
        for i in 0 to 100 loop
            t := t + 1.0 / 44.1e3; -- Increment time with respect to sampling rate
            sine_wave_real := sin(2.0 * math_pi * 1000.0 * t); -- 1 kHz sine wave
            sine_wave_int := integer(sine_wave_real * (2.0**22)); -- Scale and convert to integer (more headroom)

            -- Ensure the sine_wave_int is within the 24-bit signed integer range
            if sine_wave_int > 2**23 - 1 then
                sine_wave_int := 2**23 - 1; -- Prevent overflow
            elsif sine_wave_int < -(2**23) then
                sine_wave_int := -(2**23); -- Prevent underflow
            end if;

            data_i <= std_logic_vector(to_signed(sine_wave_int, 24)); -- Ensure signed conversion
            wait for clk_period;

            -- Convert std_logic_vector to integer for printing
            int_data_i := to_integer(signed(data_i));

            -- Print data_i value
            write(l, string'("data_i = "));
            write(l, int_data_i);
            writeline(output_file, l);
        end loop;

        -- Complete the test
        wait;
    end process;
end testbench;
