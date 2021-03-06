library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sprite is
  port (clk               : in std_logic;
        x_coord           : in unsigned(9 downto 0);
        y_coord           : in unsigned(9 downto 0);
        data_out_sprite   : out std_logic_vector(7 downto 0));
end sprite;

architecture Behavioral of sprite is
  signal index : unsigned(19 downto 0);
  type ram_t is array (0 to 1023) of std_logic_vector(7 downto 0);

  signal spriteMem : ram_t :=(
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"ba", x"ba", x"ba", x"ba", x"ba", x"ba", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"ba", x"ba", x"ba", x"ba", x"ba", x"ba", x"ba", x"ba", x"ba", x"ba", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"ba", x"ba", x"ba", x"ba", x"ba", x"ba", x"ba", x"ba", x"ba", x"ba", x"ba", x"ba", x"ba", x"ba", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"ba", x"ba", x"50", x"50", x"50", x"50", x"ba", x"ba", x"ba", x"ba", x"50", x"50", x"50", x"ba", x"ba", x"ba", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"ba", x"ba", x"50", x"50", x"50", x"50", x"50", x"50", x"ba", x"ba", x"50", x"50", x"50", x"50", x"50", x"ba", x"ba", x"ba", x"00", x"00", x"00", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"00", x"00", x"ba", x"ba", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"ba", x"ba", x"50", x"50", x"50", x"50", x"50", x"ba", x"da", x"da", x"ba", x"00", x"00", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"00", x"ba", x"ba", x"ba", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"ba", x"ba", x"da", x"da", x"ba", x"00", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"00", x"ba", x"ba", x"ba", x"50", x"50", x"50", x"50", x"ff", x"ff", x"24", x"24", x"50", x"50", x"ff", x"ff", x"24", x"24", x"ba", x"ba", x"ba", x"da", x"ba", x"00", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"00", x"ba", x"ba", x"ba", x"50", x"50", x"50", x"50", x"ff", x"ff", x"24", x"24", x"50", x"50", x"ff", x"ff", x"24", x"24", x"ba", x"ba", x"ba", x"ba", x"ba", x"00", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"00", x"ba", x"ba", x"ba", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"ba", x"ba", x"ba", x"ba", x"ba", x"00", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"00", x"ba", x"ba", x"ba", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"ba", x"ba", x"ba", x"ba", x"ba", x"00", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"00", x"ba", x"ba", x"ba", x"03", x"03", x"50", x"50", x"a0", x"a0", x"a0", x"a0", x"a0", x"a0", x"a0", x"a0", x"a0", x"a0", x"ba", x"ba", x"ba", x"ba", x"ba", x"00", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"00", x"ba", x"ba", x"ba", x"03", x"03", x"50", x"50", x"a0", x"a0", x"a0", x"a0", x"a0", x"a0", x"a0", x"a0", x"a0", x"a0", x"ba", x"ba", x"ba", x"ba", x"ba", x"00", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"b6", x"ba", x"ba", x"ba", x"03", x"03", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"50", x"ba", x"ba", x"ba", x"ba", x"ba", x"ba", x"ba", x"b6", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"00", x"00", x"00", 
x"00", x"00", x"b6", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"da", x"b6", x"00", x"00", 
x"00", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"b6", x"00", 
x"b6", x"b6", x"1f", x"1f", x"b6", x"b6", x"1f", x"1f", x"b6", x"b6", x"1f", x"1f", x"b6", x"b6", x"1f", x"1f", x"b6", x"b6", x"1f", x"1f", x"b6", x"b6", x"1f", x"1f", x"b6", x"b6", x"1f", x"1f", x"b6", x"b6", x"1f", x"1f", 
x"00", x"b6", x"1f", x"1f", x"b6", x"b6", x"1f", x"1f", x"b6", x"b6", x"1f", x"1f", x"b6", x"b6", x"1f", x"1f", x"b6", x"b6", x"1f", x"1f", x"b6", x"b6", x"1f", x"1f", x"b6", x"b6", x"1f", x"1f", x"b6", x"b6", x"1f", x"00", 
x"00", x"00", x"24", x"24", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"24", x"24", x"00", x"00", 
x"00", x"00", x"00", x"24", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"24", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"24", x"24", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"24", x"24", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"00", x"24", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"91", x"24", x"00", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"00", x"00", x"00", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"00", x"00", x"00", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"16", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"16", x"16", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", 
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"16", x"16", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00"
);

begin
  index <= ((y_coord)*32) + (x_coord);
  process(clk) begin
    if rising_edge(clk) then
      if index >= 0 and index <= 1023 then
        data_out_sprite <= spriteMem(to_integer(index));
      end if;
    end if;
  end process;

end Behavioral;

