library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pseudo_bram is
    generic (
        DATA_WIDTH : natural := 16;
        ADDR_WIDTH : natural := 16
    );
    port (
        clk   : in std_logic;
        we    : in std_logic;
        re    : in std_logic;
        addr  : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        din   : in std_logic_vector(DATA_WIDTH-1 downto 0);
        dout  : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end pseudo_bram;

architecture rtl of pseudo_bram is
    type ram_type is array (0 to 2**ADDR_WIDTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal ram : ram_type := (others => (others => '0'));
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                ram(to_integer(unsigned(addr))) <= din;
            end if;
            if re = '1' then
                dout <= ram(to_integer(unsigned(addr)));
            else
                dout <= (others => 'Z');
            end if;
        end if;
    end process;
end rtl;

