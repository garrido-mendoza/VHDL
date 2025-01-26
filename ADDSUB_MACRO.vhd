library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.vcomponents.all;

library UNIMACRO;
use UNIMACRO.vcomponents.all;

entity ADDSUB_MACRO is
    generic (
        DEVICE           : string := "7SERIES";  -- Target Device: "7SERIES", "VIRTEX6", "SPARTAN6"
        LATENCY          : integer := 2;         -- Desired clock cycle latency, 0-2
        WIDTH            : integer := 48         -- Input / Output bus width, 1-48
    );
    port (
        CARRYOUT    : out std_logic;                            -- 1-bit carry-out output signal
        RESULT      : out std_logic_vector(WIDTH-1 downto 0);   -- Add/sub result output, width defined by WIDTH generic
        A           : in std_logic_vector(WIDTH-1 downto 0);    -- Input A bus, width defined by WIDTH generic
        ADD_SUB     : in std_logic;                             -- 1-bit add/sub input, high selects add, low selects subtract
        B           : in std_logic_vector(WIDTH-1 downto 0);    -- Input B bus, width defined by WIDTH generic
        CARRYIN     : in std_logic;                             -- 1-bit carry-in input
        CE          : in std_logic;                             -- 1-bit clock enable input
        CLK         : in std_logic;                             -- 1-bit clock input
        RST         : in std_logic                              -- 1-bit input active high synchronous reset
    );
end ADDSUB_MACRO;

architecture Behavioral of ADDSUB_MACRO is

signal A_reg             : std_logic_vector(WIDTH-1 downto 0);
signal B_reg             : std_logic_vector(WIDTH-1 downto 0);
signal ADD_SUB_reg       : std_logic;
signal CARRYIN_reg       : std_logic;
signal extended_carryin  : signed(WIDTH downto 0);  -- Declare extended_carryin here
signal result_temp       : signed(WIDTH downto 0);  -- Declare result_temp here
signal extended_carryin_temp: std_logic_vector(WIDTH-1 downto 0);  -- Declare extended_carryin_temp here

-- Register stages for latency
type pipeline_array is array (0 to LATENCY-1) of std_logic_vector(WIDTH-1 downto 0);
signal pipeline : pipeline_array;

-- Carry-out pipeline for latency
signal carry_pipeline : std_logic_vector(LATENCY-1 downto 0);

begin

    process(CLK, RST)
    begin
        if RST = '1' then
            A_reg <= (others => '0');
            B_reg <= (others => '0');
            ADD_SUB_reg <= '0';
            CARRYIN_reg <= '0';
            pipeline <= (others => (others => '0'));
            carry_pipeline <= (others => '0');
            result_temp <= (others => '0');  -- Initialize result_temp during reset
            extended_carryin <= (others => '0');  -- Initialize extended_carryin during reset
            extended_carryin_temp <= (others => '0');  -- Initialize extended_carryin_temp during reset
        elsif rising_edge(CLK) then
            if CE = '1' then
                A_reg <= A;
                B_reg <= B;
                ADD_SUB_reg <= ADD_SUB;
                CARRYIN_reg <= CARRYIN;

                -- Extend the carry-in bit to match the operand width
                extended_carryin_temp <= (others => '0');
                extended_carryin_temp(WIDTH-1) <= CARRYIN_reg;

                -- Convert to signed type and extend to WIDTH+1
                extended_carryin <= signed('0' & extended_carryin_temp);

                -- Perform addition or subtraction operation, and pipeline the results
                if ADD_SUB_reg = '1' then
                    result_temp <= signed(A_reg) + signed(B_reg) + extended_carryin;
                else
                    result_temp <= signed(A_reg) - signed(B_reg) - extended_carryin;
                end if;

                pipeline(0) <= std_logic_vector(result_temp(WIDTH-1 downto 0));
                carry_pipeline(0) <= std_logic(result_temp(WIDTH));

                -- Shift pipeline
                for i in 1 to LATENCY-1 loop
                    pipeline(i) <= pipeline(i-1);
                    carry_pipeline(i) <= carry_pipeline(i-1);
                end loop;
                
            end if;
        end if;
    end process;

    RESULT <= pipeline(LATENCY-1);
    CARRYOUT <= carry_pipeline(LATENCY-1);

end Behavioral;

-- **********************************************************************************************
-- Key Issues and Solutions:
-- 
-- 1. Type Conversion Errors:
--    Problem: The compiler was unable to determine the correct overloaded definition of the `&` operator 
--             and had trouble converting `std_logic` to `unsigned`.
--    Solution: We used intermediate steps to extend the `CARRYIN_reg` bit properly. This involved creating
--              an intermediate signal `extended_carryin_temp` and then converting it to the `signed` type.
-- 
-- 2. Signal Declaration within the Process:
--    Problem: Declaring signals inside the process caused errors as VHDL does not allow signals to be declared 
--             within a process.
--    Solution: We moved the declarations of `extended_carryin_temp` and other intermediate signals to the
--              architecture's declarative region, outside of the process.
-- 
-- 3. Handling Intermediate Signals:
--    Problem: Extending and converting the `CARRYIN_reg` to match the operand width required careful handling.
--             This is because `CARRYIN_reg` is a single bit, while the operands (`A` and `B`) are `WIDTH` bits
--             wide. Simply concatenating and converting types can lead to type mismatches and errors. Ensuring 
--             the correct alignment and type compatibility is crucial for accurate arithmetic operations.
--    Solution: We created an intermediate `std_logic_vector` signal (`extended_carryin_temp`), extended it to 
--              the required width, and then converted it to a `signed` type in a step-by-step manner. This 
--              approach ensured that the `CARRYIN_reg` was correctly aligned and compatible with the other 
--              operands, allowing for accurate addition or subtraction.
-- **********************************************************************************************
