library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.vcomponents.all;

library UNIMACRO;
use UNIMACRO.vcomponents.all;

-- ========================================================================================================================================
-- OVERIVEW: MACC_MACRO typically uses signed arithmetic to handle the positive and negative values common in many DSP applications and to ensure consistency in processing.

-- The MACC_MACRO performs a Multiply-Accumulate (MACC) operation using signed arithmetic, which is suitable for digital signal processing 
-- applications where signed numbers are commonly used. 
-- The MACC_MACRO VHDL module performs high-speed multiply-accumulate operations using signed arithmetic. It supports loading initial data, 
-- handling carry-in inputs, and performing both addition and subtraction operations, all synchronized to a clock signal with an optional 
-- clock enable feature. This makes it highly suitable for digital signal processing applications.
--
--  1) Input Handling:
--      The module accepts inputs A and B, which are multiplied together. The widths of these inputs are defined by the generic parameters WIDTH_A and WIDTH_B, respectively.
--
--  2) Multiply Operation:
--      A_in * B_in: Multiplies the values of A and B.
--      The multiplication result is a product of the inputs A and B, which are treated as signed integers.
--
--  3) Accumulate Operation:
--      Accumulate the product: The product of the multiplication can then be added to or subtracted from an existing accumulated value (Accumulator).
--      The accumulation operation typically looks like: $$ \text{acc} \leftarrow \text{acc} + \left( A \times B \right) $$ or $$ \text{acc} \leftarrow \text{acc} - \left( A \times B \right) $$ depending on the control signal ADDSUB.
--
--  4) Load Data:
--      If the LOAD signal is high, the accumulator is loaded with the value of LOAD_DATA.
--
--  The MACC_MACRO leverages the DSP48E1 slice in Xilinx FPGAs to combine these operations efficiently within a single cycle, making it very effective for high-speed arithmetic computations.

--  Key Points:
--      A_in * B_in: Multiplies two input signals.
--      Accumulate: Adds or subtracts the result to/from an accumulated value, depending on the ADDSUB signal.
--      Load Data: Loads the accumulator with an initial value if LOAD is high.
-- ========================================================================================================================================

entity MACC_MACRO is
    generic (
        DEVICE     : string := "7SERIES";  -- Target Device: "VIRTEX5", "7SERIES", "SPARTAN6"
        LATENCY    : integer := 3;         -- Desired clock cycle latency, 1-4
        WIDTH_A    : integer := 25;        -- Multiplier A-input bus width, 1-25
        WIDTH_B    : integer := 18;        -- Multiplier B-input bus width, 1-18
        WIDTH_P    : integer := 48         -- Accumulator output bus width, 1-48
    );
    port (
        P           : out std_logic_vector(WIDTH_P-1 downto 0); -- MACC output bus
        A           : in  std_logic_vector(WIDTH_A-1 downto 0); -- MACC input A bus
        ADDSUB      : in  std_logic;                            -- 1-bit add/sub input
        B           : in  std_logic_vector(WIDTH_B-1 downto 0); -- MACC input B bus
        CARRYIN     : in  std_logic;                            -- 1-bit carry-in input
        CE          : in  std_logic;                            -- 1-bit active high input clock enable
        CLK         : in  std_logic;                            -- 1-bit positive edge clock input
        LOAD        : in  std_logic;                            -- 1-bit active high input load accumulator enable
        LOAD_DATA   : in  std_logic_vector(WIDTH_P-1 downto 0); -- Load accumulator input data, width determined by WIDTH_P generic
        RST         : in  std_logic                             -- 1-bit input active high reset
    );
end MACC_MACRO;

architecture Behavioral of MACC_MACRO is
    
    signal A_in         : std_logic_vector(WIDTH_A-1 downto 0);
    signal B_in         : std_logic_vector(WIDTH_B-1 downto 0);
    signal Accumulator  : std_logic_vector(WIDTH_P-1 downto 0);  

begin

    process (CLK,RST)
    begin
        if RST = '1' then
            A_in <= (others => '0');
            B_in <= (others => '0');
            Accumulator <= (others => '0');
        elsif rising_edge(CLK) then
            if CE = '1' then    -- The process only performs operations when clock enable (CE) is high, which is consistent with DSP block enable functionality.
                if LOAD = '1' then  -- When LOAD is high, A_in, B_in, and Accumulator are set to the values of A, B, and LOAD_DATA, respectively. Correct behavior of loading data into the MACC (Multiply-Accumulate) unit. 
                    A_in <= A;
                    B_in <= B;
                    Accumulator <= LOAD_DATA;
                else 
                    A_in <= A;
                    B_in <= B;
                    if ADDSUB = '1' then
                        -- Arithmetic Operations:
                        -- The process multiplies A_in and B_in and adds/subtracts the result to/from the Accumulator, including the CARRYIN value. The arithmetic operations use signed types for proper two's complement arithmetic.
                        -- The CARRYIN is correctly handled by extending it to the width of the accumulator with zero-padding and converting it to a signed vector.
                        Accumulator <= std_logic_vector(signed(A_in) * signed(B_in) + signed(Accumulator) + signed(std_logic_vector'(CARRYIN & (WIDTH_P-1 downto 1 => '0'))));
                    else
                        Accumulator <= std_logic_vector(signed(A_in) * signed(B_in) - signed(Accumulator) - signed(std_logic_vector'(CARRYIN & (WIDTH_P-1 downto 1 => '0'))));
                    end if;
                end if;
            end if;  
        end if;  
    end process;
    
    P <= Accumulator;                       
    
end Behavioral;

-- ========================================================================================================================================
-- SIGNED ARITHMETIC:
-- Two's Complement Arithmetic: Digital signal processing often involves both positive and negative values, especially when dealing with 
-- audio signals, filters, and image processing. Signed arithmetic allows the representation and manipulation of these values using 
-- two's complement format.
--
-- Consistency in Processing: When inputs (such as A and B) are inherently signed due to the nature of the data, it makes sense to use 
-- signed arithmetic throughout the multiply-accumulate operations to maintain consistency and accuracy.
--
-- Carry Input Handling: Convert the CARRYIN signal from std_logic to std_logic_vector to be used in arithmetic operations. 
-- To do this conversion, use signed(std_logic_vector'(CARRYIN & (WIDTH_P-1 downto 1 => '0'))).
-- This converts CARRYIN to a std_logic_vector with the appropriate number of bits.
-- Must apply the signed function to the entire expression to avoid a type mismatch error.
-- Use signed(std_logic_vector'(CARRYIN & (WIDTH_P-1 downto 1 => '0'))) to effectively pads CARRYIN to the width of the accumulator and convert it.
--
-- WIDTH_P-1 downto 1 is a range specification. It means "create a vector with WIDTH_P-1 elements, starting from index 1 and going down to index 1".
-- => '0' is an assignment operator. It means "assign the value '0' to each element in the range". 
-- The expression creates a vector of zeros with a length of WIDTH_P-1. The index of the vector starts at 1 and goes down to 1, which means that the vector has WIDTH_P-1 elements.
-- The entire expression WIDTH_P-1 downto 1 => '0' means "create a vector with WIDTH_P-1 elements, and assign the value '0' to each element".
-- ========================================================================================================================================