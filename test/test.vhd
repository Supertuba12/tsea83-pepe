--------------------------------------------------------------------------------
-- test


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
                                        -- and various arithmetic operations

-- entity
entity VGA_lab is
  port ( clk	                : in std_logic;                         -- system clock
	 rst                    : in std_logic;                         -- reset
	 Hsync	                : out std_logic;                        -- horizontal sync
	 Vsync	                : out std_logic;                        -- vertical sync
	 vgaRed	                : out	std_logic_vector(2 downto 0);   -- VGA red
	 vgaGreen               : out std_logic_vector(2 downto 0);     -- VGA green
	 vgaBlue	        : out std_logic_vector(2 downto 1));     -- VGA blue
end VGA_lab;


-- architecture
architecture Behavioral of test is

  component VGA
    port ( clk            : in std_logic;
        data              : in std_logic_vector(7 downto 0);
        x_p               : out integer;
        y_p               : out integer;
        rst               : in std_logic;
        vgaRed            : out std_logic_vector(2 downto 0);
        vgaGreen          : out std_logic_vector(2 downto 0);
        vgaBlue           : out std_logic_vector(2 downto 1);
        Hsync             : out std_logic;
        Vsync             : out std_logic);
  end component;
  component ram
    port (
        clk         : in std_logic;
        x           : in integer;
        y           : in integer;
        data_out    : out std_logic_vector(7 downto 0);
  end ram;
	
  -- intermediate signals between PICT_MEM and VGA_MOTOR
  signal	data_out_s     : std_logic_vector(7 downto 0);         -- data
  signal	x_s		: integer;                -- x address
  signal    y_s     : integer;                -- y address  
begin

  -- picture memory component connection
  U1 : ram port map(clk=>clk, x=>x_s, y=>y_s, data_out=>data_out_s);
	
  -- VGA component connection
  U2 : VGA port map(clk=>clk, data=>data_out_s, x_p => x_s, y_p => y_srst=>rst vgaRed=>vgaRed, vgaGreen=>vgaGreen, vgaBlue=>vgaBlue, Hsync=>Hsync, Vsync=>Vsync);

end Behavioral;
