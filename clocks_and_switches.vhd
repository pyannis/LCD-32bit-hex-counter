library ieee;
use ieee.std_logic_1164.all;
use work.components_functions_types.all;
use ieee.numeric_std.all;
--use ieee.std_logic_unsigned.all;

entity clocks_and_switches is
  port(clk50MHz   : in  std_logic;
       switch     : in  std_logic_vector (3 downto 0);
       button     : in  std_logic;
       clk        : out std_logic;
       rst        : out std_logic;
       run        : out std_logic;
       inc_or_dec : out std_logic); 
end clocks_and_switches; 
---------------------------------------------------------

architecture behv of clocks_and_switches is
  constant fmax : integer := 50000000;  -- in Hz, internal clk is 50_MHz
  shared variable counter_ticks_half: integer;
  signal int_clk : std_logic := '0' ;
begin

--switches x Pushsbutton
  process(switch,button)
  begin
    --- pushsbutton: reset ---
    if (button='1')then
      rst<='1';
    else
      rst<='0';
    end if;
    --- up/down switches --- 
    if (switch(1)='1')then   
      run<='1';  --RUN---
    else           -- switches: . . x .
      run<='0';  --STOP--
    end if;
    if (switch(0)='1') then
      inc_or_dec<='1'; --INCREASE--
    else                 -- switches: . . . x
      inc_or_dec<='0'; --DECREASE--
    end if;
    if    (switch(3)='0' and switch(2)='0') then -- switches: 0 0 . .    1 Hz
      counter_ticks_half := fmax/   1/2;
    elsif (switch(3)='0' and switch(2)='1') then -- switches: 0 1 . .   10 Hz
      counter_ticks_half := fmax/  10/2;
    elsif (switch(3)='1' and switch(2)='0') then -- switches: 1 0 . .   10 kHz
      counter_ticks_half := fmax/ 10000/2;
    else                                         -- switches: 1 1 . .    1 MHz
      counter_ticks_half := fmax/1000000/2;
    end if;
  end process;

-- clocks generator
  process(clk50MHz)
    variable count:     integer;
  begin
    if clk50MHz'event and clk50MHz='1' then
      -- counter clock generation
      if count>=counter_ticks_half then
        count:= 0;
        int_clk <=not int_clk;
      else
        count:=count+1;
      end if;
    end if;
  end process;

  clk <= int_clk;

end behv; 
