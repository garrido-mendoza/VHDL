library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Async_Rst is
    port (
        clk    : in bit;
        rst_f  : in bit;
        count  : out integer
    );
end Async_Rst;

architecture rtl of Async_Rst is

    signal rst_f_i : bit;
    signal count_o : integer;

begin

    -- Synchronous reset and counter logic
    process (clk, rst_f_i)
    begin
        if rst_f_i = '0' then
            count_o <= 0;
        elsif clk'event and clk = '1' then
            if count_o <= 8 then -- counter counts from 0 through 8; thus, it counts 9 units when count is less than or equal to 8.  
                count_o <= count_o + 1;
            else
                count_o <= 0;
            end if;
        end if;
    end process;    

    -- Output assignments
    rst_f_i <= rst_f;
    count <= count_o;

end rtl;
