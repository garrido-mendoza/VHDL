library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.vcomponents.all;

library UNIMACRO;
use UNIMACRO.vcomponents.all;

-- ========================================================================================================================================
-- OVERVIEW: ADDMACC_MACRO typically uses unsigned arithmetic for handling large ranges and maximizing efficiency with DSP48E1 optimization.

-- The ADDMACC_MACRO performs a sequence of arithmetic operations involving addition, multiplication, and accumulation. 
-- Here's a breakdown of the operations it typically computes:

--  1) Pre-Addition:
--      PREADDER1 + PREADDER2: It first adds two input values, PREADDER1 and PREADDER2. Both inputs are defined by the generic WIDTH_PREADD, so their widths match.
--
--  2) Multiplication:
--      (PREADDER1 + PREADDER2) * MULTIPLIER: The result of the pre-addition is then multiplied by another input, MULTIPLIER. 
--      The width of the MULTIPLIER is defined by the generic WIDTH_MULTIPLIER.
--
--  3) Accumulation:
--      Accumulate the product: The product of the pre-addition and multiplication can then be added to an existing accumulated value. 
--      This accumulated value can be stored and updated over multiple clock cycles.
--      The accumulation operation typically looks like: $$ \text{acc} \leftarrow \text{acc} + \left( (\text{PREADDER1} + \text{PREADDER2}) \times \text{MULTIPLIER} \right) $$
--
--  The ADDMACC_MACRO combines these operations efficiently within a single cycle, leveraging the powerful capabilities of the DSP48E1 slice in Xilinx FPGAs. 
--  This combination is very effective for digital signal processing applications, such as filtering, convolution, and other mathematical computations.
--
--  Key Points:
--      PREADDER1 + PREADDER2: Adds two input signals.
--      (PREADDER1 + PREADDER2) * MULTIPLIER: Multiplies the sum by a third input.
--      Accumulate: Adds the result to an accumulated value, if applicable.
-- ========================================================================================================================================

entity ADDMACC_MACRO is
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
end ADDMACC_MACRO;

architecture Behavioral of ADDMACC_MACRO is

signal Accumulator      : unsigned(WIDTH_PRODUCT-1 downto 0) := (others => '0');  
signal PREADDER1_in     : std_logic_vector(WIDTH_PREADD-1 downto 0); 
signal PREADDER2_in     : std_logic_vector(WIDTH_PREADD-1 downto 0);
signal MULTIPLIER_in    : std_logic_vector(WIDTH_MULTIPLIER-1 downto 0);

begin
    
    process(CLK)
    begin
        if RST = '1' then
                PREADDER1_in <= (others => '0');
                PREADDER2_in <= (others => '0');
                MULTIPLIER_in <= (others => '0'); 
                Accumulator <= (others => '0');
        elsif rising_edge(CLK) then
            if CE = '1' then
                if LOAD = '1' then
                    PREADDER1_in <= PREADDER1;
                    PREADDER2_in <= PREADDER2;
                    MULTIPLIER_in <= MULTIPLIER;
                    Accumulator <= unsigned(LOAD_DATA);
                else
                    Accumulator <= Accumulator + (unsigned(MULTIPLIER_in) * (unsigned(PREADDER1_in) + unsigned(PREADDER2_in)));
                end if;
            end if;
        end if;
    end process;    

    PRODUCT <= std_logic_vector(Accumulator);

end Behavioral;

-- ========================================================================================================================================
-- UNSIGNED ARITHMETIC: 
-- Overflow Handling: In many digital signal processing (DSP) applications, accumulations are designed to handle large values. 
-- Using unsigned arithmetic helps to maximize the dynamic range and avoid unexpected behaviors due to overflow.
--
-- DSP48E1 Optimization: The DSP48E1 slice in Xilinx FPGAs is highly optimized for unsigned operations, which makes it a natural choice for 
-- implementations that leverage these hardware resources.
-- ========================================================================================================================================