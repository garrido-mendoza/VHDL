library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity univ_shift_reg is
    generic (
        data_width : integer := 8
    );

    port (
        clk : in std_logic;
        rst : in std_logic;  
        I   : in std_logic_vector(data_width - 1 downto 0);
        S   : in std_logic_vector(data_width - 7 downto 0); -- Shift instruction. 
        A   : out std_logic_vector(data_width - 1 downto 0)
    );
end univ_shift_reg;

architecture Behavioral of univ_shift_reg is
    signal A_reg : std_logic_vector(data_width - 1 downto 0);
begin
    usr : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then 
                A_reg <= (others => '0');
            else 
                case S is
                    when "00" =>    -- Hold
                        A_reg <= A_reg;
                    when "01" =>    -- Right shift
                        A_reg(data_width - 1) <= '0';
                        A_reg(data_width - 2 downto 0) <= A_reg(data_width - 1 downto 1);
                    when "10" =>    -- Left shift
                        A_reg(data_width - 1 downto 1) <= A_reg(data_width - 2 downto 0);
                        A_reg(0) <= '0'; 
                    when "11" =>    -- Parallel load
                        A_reg <= I;
                    when others => 
                        A_reg <= (others => 'U');
                end case;
            end if;
        end if;
    end process usr;
    
    A <= A_reg;
                                           
end Behavioral;

