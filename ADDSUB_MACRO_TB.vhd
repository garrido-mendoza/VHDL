library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ADDSUB_MACRO_TB is
end ADDSUB_MACRO_TB;

architecture Behavioral of ADDSUB_MACRO_TB is

    -- Constant Declaration
    constant WIDTH : integer := 48;

    -- Component Declaration for the Unit Under Test (UUT)
    component ADDSUB_MACRO
        generic (
            DEVICE  : string := "7SERIES";
            LATENCY : integer := 2;
            WIDTH   : integer := 48
        );
        port (
            CARRYOUT : out std_logic;
            RESULT   : out std_logic_vector(WIDTH-1 downto 0);
            A        : in std_logic_vector(WIDTH-1 downto 0);
            ADD_SUB  : in std_logic;
            B        : in std_logic_vector(WIDTH-1 downto 0);
            CARRYIN  : in std_logic;
            CE       : in std_logic;
            CLK      : in std_logic;
            RST      : in std_logic
        );
    end component;

    -- Inputs
    signal A        : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal ADD_SUB  : std_logic := '0';
    signal B        : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal CARRYIN  : std_logic := '0';
    signal CE       : std_logic := '0';
    signal CLK      : std_logic := '0';
    signal RST      : std_logic := '0';

    -- Outputs
    signal CARRYOUT : std_logic;
    signal RESULT   : std_logic_vector(WIDTH-1 downto 0);

    -- Clock period definition
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: ADDSUB_MACRO
        generic map (
            DEVICE  => "7SERIES",
            LATENCY => 2,
            WIDTH   => 48
        )
        port map (
            CARRYOUT => CARRYOUT,
            RESULT   => RESULT,
            A        => A,
            ADD_SUB  => ADD_SUB,
            B        => B,
            CARRYIN  => CARRYIN,
            CE       => CE,
            CLK      => CLK,
            RST      => RST
        );

    -- Clock process definitions
    CLK_process :process
    begin
        CLK <= '0';
        wait for CLK_PERIOD/2;
        CLK <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- hold reset state for 100 ns.
        RST <= '1';
        wait for 100 ns;
        RST <= '0';
        wait for 100 ns;

        -- Test Case 1: Simple Addition
        A <= x"000000000001";
        B <= x"000000000001";
        ADD_SUB <= '1';  -- Add operation
        CARRYIN <= '0';
        CE <= '1';
        wait for 40 ns;  -- Wait for the result after 4 clock cycles
        
        -- Test Case 2: Simple Subtraction
        A <= x"000000000002";
        B <= x"000000000001";
        ADD_SUB <= '0';  -- Subtract operation
        CARRYIN <= '0';
        CE <= '1';
        wait for 40 ns;  -- Wait for the result after 4 clock cycles
        
        -- Test Case 3: Addition with Carry-In
        A <= x"000000000002";
        B <= x"000000000001";
        ADD_SUB <= '1';  -- Add operation
        CARRYIN <= '1';
        CE <= '1';
        wait for 40 ns;  -- Wait for the result after 4 clock cycles
        
        -- Test Case 4: Subtraction with Carry-In
        A <= x"000000000003";
        B <= x"000000000001";
        ADD_SUB <= '0';  -- Subtract operation
        CARRYIN <= '1';
        CE <= '1';
        wait for 40 ns;  -- Wait for the result after 4 clock cycles
        
        -- Test Case 5: Reset during Operation
        A <= x"000000000002";
        B <= x"000000000001";
        ADD_SUB <= '1';  -- Add operation
        CARRYIN <= '0';
        CE <= '1';
        wait for 20 ns;  -- Partial time for the operation
        RST <= '1';      -- Assert reset
        wait for 20 ns;
        RST <= '0';      -- Deassert reset
        wait for 40 ns;  -- Wait for the result after 4 clock cycles
        
        -- Test Case 6: Clock Enable Disabled
        A <= x"000000000003";
        B <= x"000000000001";
        ADD_SUB <= '1';  -- Add operation
        CARRYIN <= '0';
        CE <= '0';       -- Disable clock enable
        wait for 40 ns;  -- Operation should not take place
        
        -- Test Case 7: Verify Latency
        A <= x"000000000005";
        B <= x"000000000003";
        ADD_SUB <= '1';  -- Add operation
        CARRYIN <= '0';
        CE <= '1';
        wait for 10 ns;  -- Wait for partial latency
        wait for 30 ns;  -- Complete the latency period
        
        -- Test complete
        wait;
    end process;

end Behavioral;
