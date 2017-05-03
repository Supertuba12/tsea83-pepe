library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;

entity PEPE is
  port (clk               : in std_logic;                         -- system clock
        rst               : in std_logic;                         -- reset
        Hsync             : out std_logic;                        -- horizontal sync
        Vsync             : out std_logic;                        -- vertical sync
        vgaRed            : out	std_logic_vector(2 downto 0);     -- VGA red
        vgaGreen          : out std_logic_vector(2 downto 0);     -- VGA green
        vgaBlue           : out std_logic_vector(2 downto 1);    -- VGA blue
        PS2KeyboardClk	  : in std_logic;                         -- PS2 clock
	      PS2KeyboardData   : in std_logic);                        -- PS2 data
end PEPE;

architecture Behavioral of PEPE is
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

  component CPU
    port(clk : in std_logic;
         rst : in std_logic);
  end component;

  --Inputs
  --signal clk : std_logic:= '0';
  --signal rst : std_logic:= '0';

  --Clock period definitions
  --constant clk_period : time:= 1 us;

begin
  -- VGA component connection
  U2 : VGA port map(clk, rst, vgaRed, vgaGreen, vgaBlue, Hsync, Vsync, PS2KeyboardClk, PS2KeyboardData);

  -- Instantiate the Unit Under Test (UUT)
  uut: CPU PORT MAP (
    clk => clk,
    rst => rst);

  -- Clock process definitions
  clk_process :process
  begin
    clk <= '0';
    wait for clk_period/2;
    clk <= '1';
    wait for clk_period/2;
  end process;

  rst <= '1', '0' after 1.7 us;

end Behavioral;
