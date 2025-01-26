library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clken is
    port (
        clk      : in bit;
        rst_f    : in bit;
        data     : in bit;
        enable   : in bit;
        data_out : out bit
    );
end clken;

architecture rtl of clken is

    signal rst_f_i       : bit;
    signal data_i        : bit;
    signal enable_i      : bit;
    signal data_out_o    : bit;

begin

    rst_f_i <= rst_f;
    data_i <= data;
    enable_i <= enable;

    process (clk, rst_f_i)
    begin
        if rst_f_i = '0' then
            data_out_o <= '0';
        elsif rising_edge(clk) then
            if enable_i = '1' then
                data_out_o <= data_i;
            else 
                data_out_o <= data_out_o;
            end if;
        end if;
    end process;

    data_out <= data_out_o;

end rtl;
