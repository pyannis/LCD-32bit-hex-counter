library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

use work.components_functions_types.all;

entity lcd is
  port(
    clk_50_MHz : in std_logic;
    switch     : in std_logic_vector (3 downto 0);
    button     : in std_logic;
    LCD_E      : out bit;
    LCD_RS     : out bit;
    LCD_RW     : out bit;
    SF_D       : out std_logic_vector(3 downto 0);
    LED        : out std_logic_vector(7 downto 0) );
end lcd;

architecture behavior of lcd is

  signal clk        : std_logic; 
  signal reset      : std_logic;
  signal inc_or_dec : std_logic;
  signal run        : std_logic;
  signal hexcounter : std_logic_vector(31 downto 0);

----Component Instantiation in Package----
  for  ClocksSwitchesStim : clocks_and_switches use entity work.clocks_and_switches(behv);
  for  HexCount : counter use entity work.counter(counter_logic);

  type tx_sequence is (high_setup, high_hold, oneus, low_setup, low_hold, fortyus, done);
  signal tx_state : tx_sequence := done;
  signal tx_byte : std_logic_vector(7 downto 0);
  signal tx_byte_init : std_logic_vector(7 downto 0);
  signal tx_init : bit := '0';

  type init_sequence is (idle, fifteenms, one, two, three, four, five, six, seven, eight, done);
  signal init_state : init_sequence := idle;
  signal init_init, init_done : bit := '0';

  signal i1 : integer range 0 to 750000 := 0; -- 15 ms
  signal i2 : integer range 0 to   2000 := 0; -- 40 μs
  signal i3 : integer range 0 to  82000 := 0; --  1.64 ms

  signal SF_D8 : std_logic_vector(7 downto 0);
  signal LCD_E0, LCD_E1 : bit;
  signal mux : bit;

  type display_state is (init, function_set, entry_set, set_display, clr_display, pause, set_addr, chars, done);
  signal cur_state : display_state := init;

  type data_type is array(0 to 79) of std_logic_vector(7 downto 0);
  signal msg : data_type := (
    -- 1st line : msg(0) to msg(39)
    x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",
    x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",
    x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",
    x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",
    -- 2nd line : msg(40) to msg(79)
    x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",
    x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",
    x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",
    x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20"
  );

  type digit_to_char_mapping is array(0 to 15) of std_logic_vector(7 downto 0);
  constant digit2asc : digit_to_char_mapping := (x"30",x"31",x"32",x"33",x"34",x"35",x"36",x"37",x"38",x"39",   x"41",x"42",x"43",x"44",x"45",x"46");

  type uint_array is array(9 downto 0) of unsigned(31 downto 0);
  type  int_array is array(9 downto 0) of integer range 0 to 9;
  
begin

  ----Component Implementation ---------
  ClocksSwitchesStim : clocks_and_switches port map(clk_50_MHz, switch, button, clk, reset, run, inc_or_dec);
  HexCount           : counter             port map(clk, reset, run, inc_or_dec, hexcounter);
  ------------------------------- 

  LED<=hexcounter(7 downto 0);  --for LED visualization

  LCD_RW <= '0'; --write only

  process(hexcounter)
  variable nn : unsigned(31 downto 0);
  variable ii : integer;
  variable dec : int_array;
  --constant factor : uint_array := (1000000000,100000000,10000000,1000000,100000,10000,1000,100,10,1);
  constant factor : uint_array := (x"3B9ACA00",x"05F5E100",x"00989680",x"000F4240",x"000186A0",x"00002710",x"000003E8",x"00000064",x"0000000A",x"00000001");
  begin
    nn := unsigned(hexcounter(31 downto 0)) ;
    -- billions
    ii:=9;
    dec(ii):=0;
    if     (nn >= 4*factor(ii)) then
      dec(ii):=   4;
      nn:=nn-     4*factor(ii);
    elsif  (nn >= 3*factor(ii)) then
      dec(ii):=   3;
      nn:=nn-     3*factor(ii);
    elsif  (nn >= 2*factor(ii)) then
      dec(ii):=   2;
      nn:=nn-     2*factor(ii);
    elsif  (nn >= 1*factor(ii)) then
      dec(ii):=   1;
      nn:=nn-     1*factor(ii);
    end if;
    --
    for ii in 8 downto 0 loop
      dec(ii):=0;
      if     (nn >= 9*factor(ii)) then
        dec(ii):=   9;
        nn:=nn-     9*factor(ii);
      elsif  (nn >= 8*factor(ii)) then
        dec(ii):=   8;
        nn:=nn-     8*factor(ii);
      elsif  (nn >= 7*factor(ii)) then
        dec(ii):=   7;
        nn:=nn-     7*factor(ii);
      elsif  (nn >= 6*factor(ii)) then
        dec(ii):=   6;
        nn:=nn-     6*factor(ii);
      elsif  (nn >= 5*factor(ii)) then
        dec(ii):=   5;
        nn:=nn-     5*factor(ii);
      elsif  (nn >= 4*factor(ii)) then
        dec(ii):=   4;
        nn:=nn-     4*factor(ii);
      elsif  (nn >= 3*factor(ii)) then
        dec(ii):=   3;
        nn:=nn-     3*factor(ii);
      elsif  (nn >= 2*factor(ii)) then
        dec(ii):=   2;
        nn:=nn-     2*factor(ii);
      elsif  (nn >= 1*factor(ii)) then
        dec(ii):=   1;
        nn:=nn-     1*factor(ii);
      end if;
    end loop;
    -- 
    for i in 9 downto 0 loop
      msg(49-i) <= digit2asc(dec(i)); -- 10-digit decimal counter
    end loop;

    for i in 7 downto 0 loop
      ii:=0;
      if (hexcounter(4*i+3)='1') then ii:=ii+8 ; end if;
      if (hexcounter(4*i+2)='1') then ii:=ii+4 ; end if;
      if (hexcounter(4*i+1)='1') then ii:=ii+2 ; end if;
      if (hexcounter(4*i  )='1') then ii:=ii+1 ; end if;
      msg(7-i) <= digit2asc(ii); -- 8-digit hexadecimal counter
    end loop;

  end process;

--The following "with" statements simplify the process of adding and removing states.

--when to transmit a command/data and when not to
  with cur_state select
    tx_init <= '0' when init | pause | done,
               '1' when others;

--control the bus
  with cur_state select
    mux <= '1' when init,
           '0' when others;

--control the initialization sequence
  with cur_state select
    init_init <= '1' when init,
                 '0' when others;

--register select
  with cur_state select
    LCD_RS <= '0' when function_set|entry_set|set_display|clr_display|set_addr,
              '1' when others;

--what byte to transmit to lcd
--refer to datasheet for an explanation of these values
  with cur_state select
    tx_byte <=
    x"28" when function_set, -- LCD 2 lines, 40 chars/line, 5x8 dot matrix, 4 bit interface
    x"06" when entry_set,    -- After each character displayed on the LCD, shift the cursor to the right
    x"0C" when set_display,  -- Display ON, Underscore cursor OFF, Cursor blink OFF
    x"01" when clr_display,  -- Display Clear
    x"80" when set_addr,     -- set DDRAM address
    msg(i3) when chars,
    x"00" when others;

  with init_state select
    tx_byte_init <=
    x"03" when one,          -- Display Home
    x"03" when three,        -- Display Home
    x"03" when five,         -- Display Home
    x"02" when seven,        -- Display Home
    x"00" when others;

--main state machine
  display: process(clk_50_MHz, reset)
  begin
    if(reset='1') then
      cur_state <= function_set;
    elsif(clk_50_MHz='1' and clk_50_MHz'event) then
      case cur_state is

        when init         =>          if (init_done = '1') then cur_state <= function_set;      else cur_state <= init;                end if;
        when function_set =>          if (i2 = 2000)       then cur_state <= entry_set;         else cur_state <= function_set;        end if;
        when entry_set    =>          if (i2 = 2000)       then cur_state <= set_display;       else cur_state <= entry_set;           end if;
        when set_display  =>          if (i2 = 2000)       then cur_state <= clr_display;       else cur_state <= set_display;         end if;
        when clr_display  => i3 <= 0; if (i2 = 2000)       then cur_state <= set_addr;          else cur_state <= clr_display;         end if;
        when set_addr     =>          if (i2 = 2000)       then cur_state <= chars;             else cur_state <= set_addr; end if;
        when chars        =>          if (i2 = 2000)       then   if ( i3 = msg'length ) then cur_state <= done; i3 <= 0; else cur_state <= chars; i3 <= i3 + 1; end if;   end if;
        when pause        => cur_state <= set_addr;
        when done         => cur_state <= set_addr;

      end case;
    end if;
  end process display;

  with mux select
    SF_D8 <= tx_byte      when '0',    --transmit
             tx_byte_init when others; --initialize

  with mux select
    LCD_E <= LCD_E0 when '0',    --transmit
             LCD_E1 when others; --initialize

--specified by datasheet
  transmit : process(clk_50_MHz, reset, tx_init)
  begin
    if(reset='1') then
      tx_state <= done;
    elsif(clk_50_MHz='1' and clk_50_MHz'event) then
      case tx_state is
        when high_setup => --40ns
          LCD_E0 <= '0';
          SF_D <= SF_D8(7 downto 4);
          if(i2 = 2) then tx_state <= high_hold; i2 <= 0; else tx_state <= high_setup; i2 <= i2 + 1; end if;
        when high_hold => --230ns
          LCD_E0 <= '1';
          SF_D <= SF_D8(7 downto 4);
          if(i2 = 12) then tx_state <= oneus; i2 <= 0; else tx_state <= high_hold; i2 <= i2 + 1; end if;
        when oneus =>
          LCD_E0 <= '0';
          if(i2 = 50) then tx_state <= low_setup; i2 <= 0; else tx_state <= oneus; i2 <= i2 + 1; end if;
        when low_setup =>
          LCD_E0 <= '0';
          SF_D <= SF_D8(3 downto 0);
          if(i2 = 2) then tx_state <= low_hold; i2 <= 0; else tx_state <= low_setup; i2 <= i2 + 1; end if;
        when low_hold =>
          LCD_E0 <= '1';
          SF_D <= SF_D8(3 downto 0);
          if(i2 = 12) then tx_state <= fortyus; i2 <= 0; else tx_state <= low_hold; i2 <= i2 + 1; end if;
        when fortyus =>
          LCD_E0 <= '0';
          if(i2 = 2000) then tx_state <= done; i2 <= 0; else tx_state <= fortyus; i2 <= i2 + 1; end if;
        when done =>
          LCD_E0 <= '0';
          if(tx_init = '1') then tx_state <= high_setup; i2 <= 0; else tx_state <= done; i2 <= 0; end if;
      end case;
    end if;
  end process transmit;

--specified by datasheet
  power_on_initialize: process(clk_50_MHz, reset, init_init) --power on initialization sequence
  begin
    if(reset='1') then
      init_state <= idle;
      init_done <= '0';
    elsif(clk_50_MHz='1' and clk_50_MHz'event) then
      case init_state is
        when idle =>
          init_done <= '0';
          if(init_init = '1') then init_state <= fifteenms; i1 <= 0; else init_state <= idle; i1 <= i1 + 1; end if;
        when fifteenms =>
          init_done <= '0';
          if(i1 = 750000) then init_state <= one; i1 <= 0; else init_state <= fifteenms; i1 <= i1 + 1; end if;
        when one =>
          LCD_E1 <= '1';
          init_done <= '0';
          if(i1 = 11) then init_state<=two; i1 <= 0; else init_state<=one; i1 <= i1 + 1; end if;
        when two =>
          LCD_E1 <= '0';
          init_done <= '0';
          if(i1 = 205000) then init_state<=three; i1 <= 0; else init_state<=two; i1 <= i1 + 1; end if;
        when three =>
          LCD_E1 <= '1';
          init_done <= '0';
          if(i1 = 11) then init_state<=four; i1 <= 0; else init_state<=three; i1 <= i1 + 1; end if;
        when four =>
          LCD_E1 <= '0';
          init_done <= '0';
          if(i1 = 5000) then init_state<=five; i1 <= 0; else init_state<=four; i1 <= i1 + 1; end if;
        when five =>
          LCD_E1 <= '1';
          init_done <= '0';
          if(i1 = 11) then init_state<=six; i1 <= 0; else init_state<=five; i1 <= i1 + 1; end if;
        when six =>
          LCD_E1 <= '0';
          init_done <= '0';
          if(i1 = 2000) then init_state<=seven; i1 <= 0; else init_state<=six; i1 <= i1 + 1; end if;
        when seven =>
          LCD_E1 <= '1';
          init_done <= '0';
          if(i1 = 11) then init_state<=eight; i1 <= 0; else init_state<=seven; i1 <= i1 + 1; end if;
        when eight =>
          LCD_E1 <= '0';
          init_done <= '0';
          if(i1 = 2000) then init_state<=done; i1 <= 0; else init_state<=eight; i1 <= i1 + 1; end if;
        when done =>
          init_done <= '1';
          init_state <= done;
      end case;
    end if;
  end process power_on_initialize;

end behavior;
