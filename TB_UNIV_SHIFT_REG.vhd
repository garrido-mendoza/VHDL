library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity univ_shift_reg_tb is
end univ_shift_reg_tb;

architecture Behavioral of univ_shift_reg_tb is

component univ_shift_reg is
    generic (   data_width : integer := 8);
    port (  clk : in std_logic;
            rst : in std_logic;  
            I   : in std_logic_vector(data_width - 1 downto 0);
            S   : in std_logic_vector(data_width - 7 downto 0); -- Shift instruction. 
            A   : out std_logic_vector(data_width - 1 downto 0));
end component;

signal clk_i : std_Logic;
signal rst_i : std_Logic;
signal I_i : std_logic_vector(7 downto 0);
signal S_i : std_logic_vector(1 downto 0);
signal A_o : std_logic_vector(7 downto 0);

begin

    uut : univ_shift_reg
    port map (  clk => clk_i,
                rst => rst_i,
                I   => I_i, 
                S   => S_i, 
                A   => A_o);

    clk_gen : process
    begin
        while true loop
            clk_i <= '0';
            wait for 10 ns;
            clk_i <= '1';
            wait for 10 ns;
        end loop;
    end process;
    
    stimulus : process
    begin
        rst_i <= '0';
        
        wait for 10 us;
        rst_i <= '1';
        
        wait for 50 us;
        rst_i <= '0';
        
        
        wait for 100 us;
        S_i <= "00";
        
        wait for 50 us;
        S_i <= "01";
        
        wait for 50 us;
        S_i <= "10";
        
        wait for 50 us;
        S_i <= "11";
        
        wait for 100 us;
        S_i <= "00";
        
        wait for 50 us;
        S_i <= "01";
        
        wait for 50 us;
        S_i <= "10";
        
        wait for 50 us;
        S_i <= "11";
        
        wait for 100 us;
        S_i <= "00";
        
        wait for 50 us;
        S_i <= "01";
        
        wait for 50 us;
        S_i <= "10";
        
        wait for 50 us;
        S_i <= "11";
        
        wait for 100 us;
        S_i <= "00";

        wait;
    end process;

end Behavioral;
