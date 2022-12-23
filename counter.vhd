library ieee;
use ieee.std_logic_1164.all;
use work.components_functions_types.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity counter is
  port(clk        :  in  std_logic;
       rst        :  in  std_logic;
       run        :  in  std_logic;
       inc_or_dec :  in  std_logic;
       counter    :  out std_logic_vector);
end counter; 

architecture counter_logic of counter is
  signal cnt : integer := 0;
begin
  process(clk, rst, run, inc_or_dec)
  begin
    if (rst='1') then
      cnt <= 0;
    elsif (clk'event and clk='1') then
      if (run='1') then
        if (inc_or_dec='1') then
          --INCREMENT : the counter will restart at 0 after FFFFFFFF
          cnt <= cnt+1;
        else
          --DECREMENT : the counter will restart at FFFFFFFF after 0
          cnt <= cnt-1;
        end if;
      end if;
    end if;
    counter <= std_logic_vector(to_unsigned(cnt, counter'length));
  end process;
end counter_logic;
