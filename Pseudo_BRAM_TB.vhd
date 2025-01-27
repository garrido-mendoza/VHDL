library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use STD.TEXTIO.all;

entity Pseudo_BRAM_TB is
end Pseudo_BRAM_TB;

architecture tb of Pseudo_BRAM_TB is
    constant DATA_WIDTH : natural := 16;
    constant ADDR_WIDTH : natural := 16;

    signal clk   : std_logic := '0';
    signal we    : std_logic;
    signal re    : std_logic;
    signal addr  : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal din   : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal dout  : std_logic_vector(DATA_WIDTH-1 downto 0);

    file output_file : text open write_mode is "output.txt";
    
begin
    -- Instantiate the module under test
    uut: entity work.pseudo_bram
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            ADDR_WIDTH => ADDR_WIDTH
        )
        port map (
            clk => clk,
            we => we,
            re => re,
            addr => addr,
            din => din,
            dout => dout
        );

    -- Clock generation process
    clk_gen: process
    begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end process clk_gen;

    -- Stimulus process
    stim_proc: process
        variable output_line : line;
    begin
        -- Write some data to the memory
        we <= '1';
        re <= '0';
        for i in 0 to 2**ADDR_WIDTH-1 loop
            addr <= std_logic_vector(to_unsigned(i, ADDR_WIDTH));
            din <= std_logic_vector(to_unsigned(i, DATA_WIDTH));
            wait until rising_edge(clk);
        end loop;

        -- Read data from the memory and capture it in the output file
        we <= '0';
        re <= '1';
        for i in 0 to 2**ADDR_WIDTH-1 loop
            addr <= std_logic_vector(to_unsigned(i, ADDR_WIDTH));
            wait until rising_edge(clk);
            write(output_line, string'("Address: "));
            write(output_line, to_integer(unsigned(addr)));
            write(output_line, string'(", Data: "));
            write(output_line, to_integer(unsigned(dout)));
            writeline(output_file, output_line);
        end loop;

        wait;
    end process stim_proc;
end tb;
