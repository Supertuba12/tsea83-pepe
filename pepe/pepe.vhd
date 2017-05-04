library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pepe is
  port (clk               : in std_logic;                         -- system clock
        rst               : in std_logic;                         -- reset
        Hsync             : out std_logic;                        -- horizontal sync
        Vsync             : out std_logic;                        -- vertical sync
        vgaRed            : out	std_logic_vector(2 downto 0);     -- VGA red
        vgaGreen          : out std_logic_vector(2 downto 0);     -- VGA green
        vgaBlue           : out std_logic_vector(2 downto 1);     -- VGA blue
        PS2KeyboardClk	  : in std_logic;                         -- PS2 clock
	      PS2KeyboardData   : in std_logic);                        -- PS2 data
end pepe;

architecture Behavioral of pepe is
  signal movement_bus       : unsigned(2 downto 0);
  signal rng_bus            : unsigned(3 downto 0);
  signal move_pepe_bus      : unsigned(2 downto 0);
  component VGA
    port (clk               : in std_logic;
          rst               : in std_logic;
          vgaRed            : out std_logic_vector(2 downto 0);
          vgaGreen          : out std_logic_vector(2 downto 0);
          vgaBlue           : out std_logic_vector(2 downto 1);
          Hsync             : out std_logic;
          Vsync             : out std_logic;
          rng_in            : in unsigned(3 downto 0);
          move_pepe_in      : in unsigned(2 downto 0));
  end component;

  component CPU
    port(clk          : in std_logic;
         rst          : in std_logic;
         movement_in  : in unsigned(2 downto 0);
         rng_ut       : out unsigned(3 downto 0);
         move_pepe    : out unsigned(2 downto 0));
  end component;
  
  component KBD_ENC 
    port(clk	            : in std_logic;
         PS2KeyboardClk   : in std_logic;
         PS2KeyboardData  : in std_logic;
         movement         : out unsigned(2 downto 0));
  end component;
begin
  U2 : VGA port map(clk, rst, vgaRed, vgaGreen, vgaBlue, Hsync, Vsync, rng_in => rng_bus, move_pepe_in => move_pepe_bus);
  U3 : KBD_ENC port map(clk, PS2KeyboardClk, PS2KeyboardData, movement => movement_bus);
  U4: CPU port map(clk, rst, movement_in => movement_bus, rng_ut => rng_bus, move_pepe => move_pepe_bus);

end Behavioral;
