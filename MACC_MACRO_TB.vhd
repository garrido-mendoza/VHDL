library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MACC_MACRO_TB is
end MACC_MACRO_TB;

architecture Behavioral of MACC_MACRO_TB is
    -- Component Declaration for the Unit Under Test (UUT)
    component MACC_MACRO
        generic (
            DEVICE     : string := "7SERIES";  -- Target Device: "VIRTEX5", "7SERIES", "SPARTAN6"
            LATENCY    : integer := 3;         -- Desired clock cycle latency, 1-4
            WIDTH_A    : integer := 25;        -- Multiplier A-input bus width, 1-25
            WIDTH_B    : integer := 18;        -- Multiplier B-input bus width, 1-18
            WIDTH_P    : integer := 48         -- Accumulator output bus width, 1-48
        );
        port (
            P           : out std_logic_vector(WIDTH_P-1 downto 0);  -- MACC output bus
            A           : in  std_logic_vector(WIDTH_A-1 downto 0);  -- MACC input A bus
            ADDSUB      : in  std_logic;                      -- 1-bit add/sub input
            B           : in  std_logic_vector(WIDTH_B-1 downto 0);  -- MACC input B bus
            CARRYIN     : in  std_logic;                      -- 1-bit carry-in input
            CE          : in  std_logic;                      -- 1-bit active high input clock enable
            CLK         : in  std_logic;                      -- 1-bit positive edge clock input
            LOAD        : in  std_logic;                      -- 1-bit active high input load accumulator enable
            LOAD_DATA   : in  std_logic_vector(WIDTH_P-1 downto 0);  -- Load accumulator input data, width determined by WIDTH_P generic
            RST         : in  std_logic                       -- 1-bit input active high reset
        );
    end component;

    -- Signal Declarations
    signal P           : std_logic_vector(47 downto 0);  -- MACC output bus
    signal A           : std_logic_vector(24 downto 0) := (others => '0');  -- MACC input A bus
    signal ADDSUB      : std_logic := '0';               -- 1-bit add/sub input
    signal B           : std_logic_vector(17 downto 0) := (others => '0');  -- MACC input B bus
    signal CARRYIN     : std_logic := '0';               -- 1-bit carry-in input
    signal CE          : std_logic := '1';               -- 1-bit active high input clock enable
    signal CLK         : std_logic := '0';               -- 1-bit positive edge clock input
    signal LOAD        : std_logic := '0';               -- 1-bit active high input load accumulator enable
    signal LOAD_DATA   : std_logic_vector(47 downto 0) := (others => '0');  -- Load accumulator input data
    signal RST         : std_logic := '0';               -- 1-bit input active high reset

begin
    -- Instantiate the Unit Under Test (UUT)
    uut: MACC_MACRO
        generic map (
            DEVICE     => "7SERIES",   -- Target Device
            LATENCY    => 3,           -- Desired clock cycle latency
            WIDTH_A    => 25,          -- Multiplier A-input bus width
            WIDTH_B    => 18,          -- Multiplier B-input bus width
            WIDTH_P    => 48           -- Accumulator output bus width
        )
        port map (
            P           => P,
            A           => A,
            ADDSUB      => ADDSUB,
            B           => B,
            CARRYIN     => CARRYIN,
            CE          => CE,
            CLK         => CLK,
            LOAD        => LOAD,
            LOAD_DATA   => LOAD_DATA,
            RST         => RST
        );

    -- Clock Generation
    CLK_process: process
    begin
        while true loop
            CLK <= '0';
            wait for 5 ns;
            CLK <= '1';
            wait for 5 ns;
        end loop;
    end process;

    -- Stimulus Process
    stim_proc: process
    begin
        -- Initialize Inputs
        RST <= '1';
        wait for 20 ns;
        RST <= '0';
        wait for 20 ns;

        -- Apply some test stimulus
        A <= (24 downto 1 => '0') & '1';    -- Equivalent to A <= "0000000000000000000000001";
        B <= (17 downto 1 => '0') & '1';    -- Equivalente to B <= "000000000000000001";
        CARRYIN <= '1';
        wait for 20 ns;

        LOAD <= '1';
        LOAD_DATA <= (47 downto 1 => '0') & '1';    -- Equivalent to LOAD_DATA <= "000000000000000000000000000000000000000000000001";
        wait for 20 ns;
        LOAD <= '0';

        ADDSUB <= '1';  -- Perform addition
        wait for 20 ns;

        ADDSUB <= '0';  -- Perform subtraction
        wait for 20 ns;

        -- More test cases can be added here

        -- Stop the simulation
        wait;
    end process;
    
end Behavioral;
