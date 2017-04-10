--------------------------------------------------------------------------------
-- vga
-- MAJOR WIP

-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type


-- entity
entity VGA is
  port ( clk			  : in std_logic;
	 data			        : in std_logic_vector(7 downto 0);
	 addr			        : out unsigned(10 downto 0);
	 rst			        : in std_logic;
	 vgaRed		        : out std_logic_vector(2 downto 0);
	 vgaGreen	        : out std_logic_vector(2 downto 0);
	 vgaBlue		      : out std_logic_vector(2 downto 1);
	 Hsync		        : out std_logic;
	 Vsync		        : out std_logic);
end VGA;


-- architecture
architecture Behavioral of VGA is

  signal	Xpixel	        : unsigned(9 downto 0);         -- Horizontal pixel counter
  signal	Ypixel	        : unsigned(9 downto 0);		      -- Vertical pixel counter
  signal	ClkDiv	        : unsigned(1 downto 0);		      -- Clock divisor, to generate 25 MHz signal
  signal	Clk25		        : std_logic;			              -- One pulse width 25 MHz signal
		
  signal 	tilePixel       : std_logic_vector(7 downto 0);	-- Tile pixel data
  signal	tileAddr	      : unsigned(10 downto 0);	      -- Tile address

  signal  blank           : std_logic;                    -- blanking signal

  component ram
      port (
          clk       : in std_logic;
          xaddress  : in integer;
          yaddress  : in integer;
          data_i    : in std_logic_vector(3 downto 0);
          data_o    : out std_logic_vector(3 downto 0)
          );
  end component;
begin

  -- Clock divisor
  -- Divide system clock (100 MHz) by 4
  process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
	      ClkDiv <= (others => '0');
      else
	      ClkDiv <= ClkDiv + 1;
      end if;
    end if;
  end process;
	
  -- 25 MHz clock (one system clock pulse width)
  Clk25 <= '1' when (ClkDiv = 3) else '0';
	
	
  -- Horizontal pixel counter

  -- ***********************************
  -- *                                 *
  -- *  VHDL for :                     *
  -- *  Xpixel                         *
  -- *                                 *
  -- ***********************************
  process(clk)
  begin
	if rst = '1' then
		Xpixel <= (others => '0');
	elsif rising_edge(clk) then
		if Clk25 = '1' then
			if Xpixel = 799 then	-- vi har nått slutet av pixelantalet
				Xpixel <= (others => '0');
			else
				Xpixel <= Xpixel + 1;
			end if;
		end if;
	end if;
  end process;
		

  
  -- Horizontal sync

  -- ***********************************
  -- *                                 *
  -- *  VHDL for :                     *
  -- *  Hsync                          *
  -- *                                 *
  -- ***********************************

	Hsync <=  '0' when ((Xpixel > 655) and (Xpixel <= 751)) else '1'; 

  -- Vertical pixel counter

  -- ***********************************
  -- *                                 *
  -- *  VHDL for :                     *
  -- *  Ypixel                         *
  -- *                                 *
  -- ***********************************
process(clk)
begin
	if rst = '1' then
		Ypixel <= (others => '0');
	elsif rising_edge(clk) then
		if Clk25 = '1' and Xpixel = 799 then
			if Ypixel = 520 then	-- vi har nått slutet av pixelantalet
				Ypixel <= (others => '0');
			else 
				Ypixel <= Ypixel + 1;
			end if;
		end if;
	end if;
  end process;
	

  -- Vertical sync

  -- ***********************************
  -- *                                 *
  -- *  VHDL for :                     *
  -- *  Vsync                          *
  -- *                                 *
  -- ***********************************

	Vsync <= '0' when ((Ypixel > 489) and (Ypixel <= 491)) else '1';
  
  -- Video blanking signal

  -- ***********************************
  -- *                                 *
  -- *  VHDL for :                     *
  -- *  Blank                          *
  -- *                                 *
  -- ***********************************

	blank <= '1' when ((Xpixel > 639 and Xpixel <= 799) or (Ypixel > 479 and Ypixel <= 520)) else '0';
  
  -- Tile memory
  process(clk)
  begin
    if rising_edge(clk) then
      if (blank = '0') then
        tilePixel <= ram(Xpixel, Ypixel);
      else
        tilePixel <= (others => '0');
      end if;
    end if;
  end process;

  -- VGA generation
  vgaRed(2) 	<= tilePixel(7);
  vgaRed(1) 	<= tilePixel(6);
  vgaRed(0) 	<= tilePixel(5);
  vgaGreen(2)   <= tilePixel(4);
  vgaGreen(1)   <= tilePixel(3);
  vgaGreen(0)   <= tilePixel(2);
  vgaBlue(2) 	<= tilePixel(1);
  vgaBlue(1) 	<= tilePixel(0);


end Behavioral;
