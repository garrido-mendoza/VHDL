library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-----------------------------------------------------------------------------------------------------------------
-- Design Specifications
-----------------------------------------------------------------------------------------------------------------
-- Filter taps: 59th Order LPF read at 44.1KHz, with a cutoff frequency of 1KHz.
-- Output width: should be < (Input+Coeff width-1). 

-----------------------------------------------------------------------------------------------------------------
-- Entity Declaration
-----------------------------------------------------------------------------------------------------------------
entity Parallel_FIR_Filter is
    Generic (
        FILTER_TAPS  : integer := 60;               -- Number of the filter taps (Example 2 & 3).   
        INPUT_WIDTH  : integer range 8 to 25 := 24; -- Bit-width of the input data. 
        COEFF_WIDTH  : integer range 8 to 18 := 16; -- Bit-width of the coefficients.
        OUTPUT_WIDTH : integer range 8 to 43 := 24  -- Bit-width of the output data.    
    );
    Port ( 
           clk    : in STD_LOGIC;
           reset  : in STD_LOGIC;
           enable : in STD_LOGIC;
           data_i : in STD_LOGIC_VECTOR (INPUT_WIDTH-1 downto 0);
           data_o : out STD_LOGIC_VECTOR (OUTPUT_WIDTH-1 downto 0)
           );
end Parallel_FIR_Filter;

-----------------------------------------------------------------------------------------------------------------
-- Architecture Declaration
-----------------------------------------------------------------------------------------------------------------
architecture Behavioral of Parallel_FIR_Filter is

-- This attribute is used to specify the use of DSP blocks.
attribute use_dsp : string;                                 
attribute use_dsp of Behavioral : architecture is "yes";

-- Defines the width of the Multiply-Accumulate (MAC) operation. 
constant MAC_WIDTH : integer := COEFF_WIDTH+INPUT_WIDTH;    

-----------------------------------------------------------------------------------------------------------------
-- Signal and Type Declarations
-----------------------------------------------------------------------------------------------------------------
-- Definitions of arrays and signals for input registers, coefficients, multiplication registers, DSP registers, 
-- output data, and signal signals
type input_registers is array(0 to FILTER_TAPS-1) of signed(INPUT_WIDTH-1 downto 0);
signal areg_s  : input_registers := (others=>(others=>'0'));

type coeff_registers is array(0 to FILTER_TAPS-1) of signed(COEFF_WIDTH-1 downto 0);
signal breg_s : coeff_registers := (others=>(others=>'0'));

type mult_registers is array(0 to FILTER_TAPS-1) of signed(INPUT_WIDTH+COEFF_WIDTH-1 downto 0);
signal mreg_s : mult_registers := (others=>(others=>'0'));

type dsp_registers is array(0 to FILTER_TAPS-1) of signed(MAC_WIDTH-1 downto 0);
signal preg_s : dsp_registers := (others=>(others=>'0'));

signal dout_s : std_logic_vector(MAC_WIDTH-1 downto 0);
signal sign_s : signed(MAC_WIDTH-INPUT_WIDTH-COEFF_WIDTH+1 downto 0) := (others=>'0');

-----------------------------------------------------------------------------------------------------------------
-- Coefficient Initialization
-----------------------------------------------------------------------------------------------------------------
---- Example 1. 1KHz Chebyshev LPF. 
---- Note: This filter causes overflow at low freq. 
--type coefficients is array (0 to 59) of signed( 15 downto 0);
--signal coeff_s: coefficients :=( 
--x"FFFF", x"FFFF", x"FFFF", x"FFFF",
--x"FFFF", x"FFFE", x"FFFE", x"FFFF",
--x"0001", x"0007", x"0011", x"0022",
--x"003B", x"005E", x"008E", x"00CD",
--x"011C", x"017C", x"01ED", x"026F",
--x"02FF", x"0399", x"0439", x"04D9",
--x"0573", x"0601", x"067B", x"06DD",
--x"0721", x"0744", x"0744", x"0721",
--x"06DD", x"067B", x"0601", x"0573",
--x"04D9", x"0439", x"0399", x"02FF",
--x"026F", x"01ED", x"017C", x"011C",
--x"00CD", x"008E", x"005E", x"003B",
--x"0022", x"0011", x"0007", x"0001",
--x"FFFF", x"FFFE", x"FFFE", x"FFFF",
--x"FFFF", x"FFFF", x"FFFF", x"FFFF");

-- Example 2. 500Hz Blackman LPF.
type coefficients is array(0 to FILTER_TAPS-1) of signed(COEFF_WIDTH-1 downto 0);
signal coeff_s: coefficients :=(
    X"0000", X"0001", X"0005", X"000C", 
    X"0016", X"0025", X"0037", X"004E", 
    X"0069", X"008B", X"00B2", X"00E0", 
    X"0114", X"014E", X"018E", X"01D3", 
    X"021D", X"026A", X"02BA", X"030B", 
    X"035B", X"03AA", X"03F5", X"043B", 
    X"047B", X"04B2", X"04E0", X"0504", 
    X"051C", X"0528", X"0528", X"051C", 
    X"0504", X"04E0", X"04B2", X"047B", 
    X"043B", X"03F5", X"03AA", X"035B", 
    X"030B", X"02BA", X"026A", X"021D", 
    X"01D3", X"018E", X"014E", X"0114", 
    X"00E0", X"00B2", X"008B", X"0069", 
    X"004E", X"0037", X"0025", X"0016", 
    X"000C", X"0005", X"0001", X"0000");

-----------------------------------------------------------------------------------------------------------------
-- Main Body
-----------------------------------------------------------------------------------------------------------------
begin  

-- Coefficient Formatting.
-- This logic assigns the coefficient values to the coefficient register (breg_s).
Coeff_Array: for i in 0 to FILTER_TAPS-1 generate
    Coeff: for n in 0 to COEFF_WIDTH-1 generate
        Coeff_Sign: if n > COEFF_WIDTH-2 generate
            breg_s(i)(n) <= coeff_s(i)(COEFF_WIDTH-1);
        end generate;
        Coeff_Value: if n < COEFF_WIDTH-1 generate
            breg_s(i)(n) <= coeff_s(i)(n);
        end generate;
    end generate;
end generate;

-- Output Assignment.
-- This assigns the output data (adata_o) from the DSP registers, 
data_o <= std_logic_vector(preg_s(0)(MAC_WIDTH-2 downto MAC_WIDTH-OUTPUT_WIDTH-1));         
      
process(clk)
begin
    if rising_edge(clk) then
        if (reset = '1') then
            -- Reset Condition: If reset is high, all registers are set to zero.
            for i in 0 to FILTER_TAPS-1 loop
                areg_s(i) <= (others => '0');
                mreg_s(i) <= (others => '0');
                preg_s(i) <= (others => '0');
            end loop;
        else
            -- Main Operation: When reset is low, data is processed.
            -- Assign input data to input registers (areg_s).
            -- Loop through Taps: For each filter tap (i), the input data (data_i) is assigned to the respective bit in the input registers.
            for i in 0 to FILTER_TAPS-1 loop
                for n in 0 to INPUT_WIDTH-1 loop
                    if n > INPUT_WIDTH-2 then
                        areg_s(i)(n) <= data_i(INPUT_WIDTH-1);
                    else
                        areg_s(i)(n) <= data_i(n);
                    end if;
                end loop;
            end loop;
            
            -- Perform multiplication and accumulation.
            for i in 0 to FILTER_TAPS-1 loop
                -- Multiplication: 
                -- The input registers (areg_s) are multiplied by the coefficient registers (breg_s), and the results are stored in the multiplication registers (mreg_s).
                mreg_s(i) <= areg_s(i) * breg_s(i); -- Multiply input registers with coefficient registers.

                -- Accumulation: 
                -- For taps less than the total number of filter taps, the current multiplication result (mreg_s(i)) is added to the next DSP register value (preg_s(i+1)). 
                -- For the last tap (i = FILTER_TAPS-1), the multiplication result is assigned directly to the DSP register (preg_s(i)). 
                if (i < FILTER_TAPS-1) then
                    preg_s(i) <= mreg_s(i) + preg_s(i+1); -- Accumulate the results.
                else
                    preg_s(i) <= mreg_s(i); -- Assign the final multiplication result to DSP register.
                end if;
            end loop;
        end if;
    end if;
end process;


end Behavioral;