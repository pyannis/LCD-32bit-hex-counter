library ieee; 
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


package components_functions_types is 

  component clocks_and_switches is
    port(clk50MHz   : in  std_logic;
         switch     : in  std_logic_vector (3 downto 0);
         button     : in  std_logic;
         clk        : out std_logic;
         rst        : out std_logic;
         run        : out std_logic;
         inc_or_dec : out std_logic); 
  end component;
  
  component counter is
    port(clk:        in  std_logic;
         rst:        in  std_logic;
         run:        in  std_logic;
         inc_or_dec: in  std_logic;
         counter:    out std_logic_vector);
  end component; 
  
end components_functions_types;
