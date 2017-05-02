--------------------------------------------------------------------------------
-- test


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
                                        -- and various arithmetic operations

-- entity
entity test is
  port (clk               : in std_logic;                         -- system clock
        rst               : in std_logic;                         -- reset
        Hsync             : out std_logic;                        -- horizontal sync
        Vsync             : out std_logic;                        -- vertical sync
        vgaRed            : out	std_logic_vector(2 downto 0);     -- VGA red
        vgaGreen          : out std_logic_vector(2 downto 0);     -- VGA green
        vgaBlue           : out std_logic_vector(2 downto 1);    -- VGA blue
        PS2KeyboardClk	  : in std_logic;                         -- PS2 clock
	      PS2KeyboardData   : in std_logic);                        -- PS2 data
end test;

-- architecture
architecture Behavioral of test is
  component VGA
    port (clk               : in std_logic;
          rst               : in std_logic;
          vgaRed            : out std_logic_vector(2 downto 0);
          vgaGreen          : out std_logic_vector(2 downto 0);
          vgaBlue           : out std_logic_vector(2 downto 1);
          Hsync             : out std_logic;
          Vsync             : out std_logic;
          PS2KeyboardClk	  : in std_logic; 		-- USB keyboard PS2 clock
          PS2KeyboardData	  : in std_logic);
  end component;

begin


  -- VGA component connection
  U2 : VGA port map(clk, rst, vgaRed, vgaGreen, vgaBlue, Hsync, Vsync, PS2KeyboardClk, PS2KeyboardData);

end Behavioral;
