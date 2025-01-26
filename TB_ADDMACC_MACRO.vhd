library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.vcomponents.all;

library UNIMACRO;
use UNIMACRO.vcomponents.all;

-- ========================================================================================================================================
-- Overview:
-- This testbench is used to simulate and verify the behavior of the ADDMACC_MACRO component, which performs a sequence of arithmetic 
-- operations involving pre-addition, multiplication, and accumulation.
-- 
-- Key Components and Capabilities:
-- 1. Component Declaration:
--    - The ADDMACC_MACRO component is declared with various generics (parameters) that define its characteristics, such as target device, 
--      latency, and input/output widths.
--    - Ports of the component define the inputs and outputs, including the product output, multiplier input, pre-adder inputs, carry-in, 
--      clock enable, clock, load, load data, and reset signals.
-- 
-- 2. Signal Declarations:
--    - Signals are declared to connect to the ports of the ADDMACC_MACRO component. These signals include PRODUCT, MULTIPLIER, PREADDER1, 
--      PREADDER2, CARRYIN, CE, CLK, LOAD, LOAD_DATA, and RST.
--    - These signals will be driven by the stimulus process to apply test vectors to the component.
-- 
-- 3. Input Values:
--    - A record type input_set is defined to hold the input values, including multiplier, preadd1, preadd2, and load_value.
--    - An array input_array of input_set records is declared to store multiple sets of input values.
--    - A process initialize_inputs dynamically initializes the inputs array based on the value of rec_sets_num. This allows the testbench to 
--      be easily configurable by adjusting the number of input sets without manual updates.
-- 
-- 4. Clock Process:
--    - The clk_gen process generates a periodic clock signal with a 20 ns period (10 ns high, 10 ns low). This clock signal is used to 
--      synchronize the operations of the ADDMACC_MACRO component.
-- 
-- 5. Stimulus Process:
--    - The stimulus process is responsible for applying the test vectors to the ADDMACC_MACRO component and observing its behavior.
--    - The process performs the following steps:
--      1. Reset: Sets the RST signal high for 20 ns to reset the component, then sets it low.
--      2. Enable Clock: Sets the CE signal high to enable the clock.
--      3. Loop Through Inputs: Iterates through the inputs array and applies each set of input values to the component.
--      4. Wait for Processing: Waits for a few clock cycles to allow the component to process the inputs.
--      5. Set Load Data: Assigns the load_value field of the current input set to LOAD_DATA.
--      6. Toggle Load Signal: Toggles the LOAD signal high and low to simulate a load operation.
--      7. Wait for Processing: Waits for a few clock cycles to allow the component to process the load operation.
-- 
-- Special Capabilities:
-- * Configurability: The testbench is highly configurable, allowing you to easily adjust the number of input sets by changing the 
--   rec_sets_num constant. This flexibility reduces manual updates and makes the testbench more agile.
-- * Dynamic Initialization: The input sets are dynamically initialized using a process, ensuring that the inputs array is populated based on 
--   the specified configuration.
-- * Thorough Testing: By looping through multiple input sets and applying them to the component, the testbench ensures comprehensive testing 
--   of the ADDMACC_MACRO component's functionality.
-- 
-- Overall, this testbench provides a robust framework for testing the ADDMACC_MACRO component, ensuring that it performs the desired 
-- arithmetic operations correctly under various input conditions.
-- ========================================================================================================================================

entity TB_ADDMACC_MACRO is
end TB_ADDMACC_MACRO;

architecture Behavioral of TB_ADDMACC_MACRO is

    component ADDMACC_MACRO
        generic (
            DEVICE           : string := "7SERIES";  -- Target Device: "7SERIES", "VIRTEX6", "SPARTAN6" 
            LATENCY          : integer := 4;         -- Desired clock cycle latency, 1-4
            WIDTH_PREADD     : integer := 25;        -- Pre-Adder input bus width, 1-25
            WIDTH_MULTIPLIER : integer := 18;        -- Multiplier input bus width, 1-18     
            WIDTH_PRODUCT    : integer := 48         -- MACC output width, 1-48
        );    
        port (
            PRODUCT      : out std_logic_vector(WIDTH_PRODUCT-1 downto 0);     -- MACC result output, width defined by WIDTH_PRODUCT generic 
            MULTIPLIER   : in std_logic_vector(WIDTH_MULTIPLIER-1 downto 0);   -- Multiplier data input, width determined by WIDTH_MULTIPLIER generic
            PREADDER1    : in std_logic_vector(WIDTH_PREADD-1 downto 0);       -- Preadder data input, width determined by WIDTH_PREADDER generic 
            PREADDER2    : in std_logic_vector(WIDTH_PREADD-1 downto 0);       -- Preadder data input, width determined by WIDTH_PREADDER generic 
            CARRYIN      : in std_logic;  -- 1-bit carry-in input
            CE           : in std_logic;  -- 1-bit input clock enable
            CLK          : in std_logic; 
            LOAD         : in std_logic; 
            LOAD_DATA    : in std_logic_vector(WIDTH_PRODUCT-1 downto 0);  -- Accumulator load data input, width defined by WIDTH_PRODUCT generic
            RST          : in std_logic   -- 1-bit input active high synchronous reset
        );
    end component;

    signal PRODUCT      : std_logic_vector(47 downto 0);
    signal MULTIPLIER   : std_logic_vector(17 downto 0) := (others => '0');
    signal PREADDER1    : std_logic_vector(24 downto 0) := (others => '0');
    signal PREADDER2    : std_logic_vector(24 downto 0) := (others => '0');
    signal CARRYIN      : std_logic := '0';
    signal CE           : std_logic := '0';
    signal CLK          : std_logic;
    signal LOAD         : std_logic := '0';
    signal LOAD_DATA    : std_logic_vector(47 downto 0) := (others => '0');
    signal RST          : std_logic;

    -- Define the input values
    type input_set is record
        multiplier : integer;
        preadd1    : integer;
        preadd2    : integer;
        load_value : integer;
    end record;

    -- Declare an array of records to hold the input values
    constant rec_sets_num : integer := 100;
    type input_array is array(0 to rec_sets_num-1) of input_set;
    
    -- Declare the input array
    signal inputs           : input_array;
    constant mult           : integer := 1;
    constant pradd1         : integer := 2;
    constant pradd2         : integer := 3;
    constant load_dat       : integer := 5;
    -- Index (i) factor
--    constant index_factor   : integer := 0; -- Default: index_factor = 0.
begin

    -- Dynamically initialize the input array inside a process
    initialize_inputs: process
    begin
        for i in 0 to rec_sets_num-1 loop
--            inputs(i) <= (i + mult, i + pradd1, i + pradd2, i + load_dat + (i * index_factor));
            inputs(i) <= (i + mult, i + pradd1, i + pradd2, i + load_dat);
        end loop;
        wait;
    end process;

    uut: ADDMACC_MACRO
        port map (
            PRODUCT      => PRODUCT,      -- MACC result output, width defined by WIDTH_PRODUCT generic 
            MULTIPLIER   => MULTIPLIER,    -- Multiplier data input, width determined by WIDTH_MULTIPLIER generic
            PREADDER1    => PREADDER1,     -- Preadder data input, width determined by WIDTH_PREADDER generic 
            PREADDER2    => PREADDER2,     -- Preadder data input, width determined by WIDTH_PREADDER generic 
            CARRYIN      => CARRYIN,       -- 1-bit carry-in input
            CE           => CE,            -- 1-bit input clock enable
            CLK          => CLK,           -- 1-bit clock input
            LOAD         => LOAD,          -- 1-bit accumulator load input
            LOAD_DATA    => LOAD_DATA,     -- Accumulator load data input, width defined by WIDTH_PRODUCT generic
            RST          => RST            -- 1-bit input active high synchronous reset
        );

    -- Clock process
    clk_gen : process
    begin
        CLK <= '0';
        wait for 10 ns;
        CLK <= '1';
        wait for 10 ns;
    end process;

    -- Stimulus process
    stimulus : process
    begin
        RST <= '1';
        wait for 20 ns;
        RST <= '0';
        wait for 20 ns;

        CE <= '1';
        for i in 0 to rec_sets_num-1 loop
            -- Set up input values
            MULTIPLIER <= std_logic_vector(to_unsigned(inputs(i).multiplier, 18));
            PREADDER1 <= std_logic_vector(to_unsigned(inputs(i).preadd1, 25));
            PREADDER2 <= std_logic_vector(to_unsigned(inputs(i).preadd2, 25));

            -- Wait for a few clock cycles
            for j in 0 to 15 loop
                wait for 20 ns;
            end loop;

            -- Set up load data
            LOAD_DATA <= std_logic_vector(to_unsigned(inputs(i).load_value, 48));

            -- Wait for a few clock cycles
            for j in 0 to 10 loop
                wait for 20 ns;
            end loop;

            -- Toggle load signal
            for j in 0 to 3 loop
                LOAD <= '1';
                wait for 20 ns;
                LOAD <= '0';
            end loop;

            -- Wait for a few clock cycles
            for j in 0 to 10 loop
                wait for 20 ns;
            end loop;
        end loop;

        wait;
    end process;

end Behavioral;

