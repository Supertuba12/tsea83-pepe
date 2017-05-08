--------------------------------------------------------------------------------
-- vga
-- MAJOR WIP

-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type

-- entity
entity VGA is
  port ( clk          : in std_logic;
    rst               : in std_logic;
    vgaRed            : out std_logic_vector(2 downto 0);
    vgaGreen          : out std_logic_vector(2 downto 0);
    vgaBlue           : out std_logic_vector(2 downto 1);
    Hsync             : out std_logic;
    Vsync             : out std_logic;
    rng_in            : in unsigned(3 downto 0);
    move_pepe_in      : in unsigned(2 downto 0)
    );
end VGA;

-- architecture
architecture Behavioral of VGA is
  signal  data            : std_logic_vector(7 downto 0);
  signal  sprite_data     : std_logic_vector(7 downto 0);
  signal  Xpixel          : unsigned(9 downto 0);         -- Horizontal pixel counter
  signal  Ypixel          : unsigned(9 downto 0);         -- Vertical pixel counter
  signal  ClkDiv          : unsigned(1 downto 0);         -- Clock divisor, to generate 25 MHz signal
  signal  Clk25           : std_logic;                    -- One pulse width 25 MHz signal
  signal  x_p             : unsigned(6 downto 0);
  signal  y_p             : unsigned(6 downto 0);
  signal  tilePixel       : std_logic_vector(7 downto 0); -- Tile pixel data
  signal  home            : unsigned(3 downto 0);         -- Home points at Y in array (0-71)
  signal  home_cp         : unsigned(3 downto 0);
  signal  start_y_p       : unsigned(2 downto 0);
  signal  start_y_p_cp    : unsigned(2 downto 0);
  signal  y_tile          : unsigned(6 downto 0);
  signal  y_tile_cp       : unsigned(6 downto 0);
  signal  tile_index      : unsigned(3 downto 0);
  signal  time_clk        : unsigned(0 downto 0);         -- When the screen should scroll
  signal  game_enable     : std_logic;                    -- Game only progress on rising_edge of time_clk
  signal  blank           : std_logic;                    -- blanking signal
  signal  xtile           : unsigned(6 downto 0);
  signal  x_out           : unsigned(9 downto 0);
  signal  y_out           : unsigned(9 downto 0);
  signal  Xpepe           : unsigned(9 downto 0) := "0110101000";
  signal  Ypepe           : unsigned(9 downto 0) := "0111000000";

  type lut_t is array (0 to 11) of unsigned(3 downto 0); signal lut : lut_t :=
  ("0001","0010","0011","0100","0101","0110","0111","1000","1001","1010","1011","0000");

  component ram
    port (clk       : in std_logic;
          x         : in unsigned;
          y         : in unsigned;
          t_pepe    : in unsigned;
          data_out  : out std_logic_vector(7 downto 0));
  end component;

  component sprite
    port (clk               : in std_logic;
          x_coord           : in unsigned;
          y_coord           : in unsigned;
          data_out_sprite   : out std_logic_vector(7 downto 0));
  end component;

begin
  -- Clock divisor
  -- Divide system clock (100 MHz) by 4
  process(clk)
  begin
    if rising_edge(clk) then
      ClkDiv <= ClkDiv + 1;
    end if;
  end process;

  -- 25 MHz clock (one system clock pulse width)
  Clk25 <= '1' when (ClkDiv = 3) else '0';

  -- Xpixel incrementation at 60Hz
  process(clk)
  begin
  if rising_edge(clk) then
    if Clk25 = '1' then
      if Xpixel = 799 then    -- vi har nÃ¥tt slutet av pixelantalet
        Xpixel <= (others => '0');
      else
        Xpixel <= Xpixel + 1;
      end if;

      if Xpixel > 247 and Xpixel < 640 then
        if Xpixel(2 downto 0) = 0 then
          xtile <= xtile + 1;
        end if;
      else
        xtile <= (others => '0');
      end if;
    end if;
  end if;
  end process;

  -- Horizontal sync
  Hsync <= '0' when ((Xpixel > 655) and (Xpixel <= 751)) else '1'; 

  -- Ypixel incrementation at 60Hz
  process(clk)
  begin
    if rising_edge(clk) then
      if Clk25 = '1' and Xpixel = 799 then
        if Ypixel = 520 then
          Ypixel <= (others => '0');
          time_clk <= time_clk + 1;
        elsif Ypixel = 480 then
          home_cp <= home;
          y_tile_cp <= y_tile;
          start_y_p_cp <= start_y_p;
          Ypixel <= Ypixel + 1;
        else
          Ypixel <= Ypixel + 1;
          if Ypixel < 480 then
            start_y_p_cp <= start_y_p_cp + 1;
            if start_y_p_cp = 0 then
              if y_tile_cp = 5 then
                y_tile_cp <= "0000000";
                if home_cp = 11 then
                  home_cp <= "0000";
                else
                  home_cp <= home_cp + 1;
                end if;
              else
                y_tile_cp <= y_tile_cp + 1;
              end if;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

-- Home pointer handler
  process(clk)
  begin
    if rising_edge(clk) then
      if time_clk = 1 then
        if game_enable = '0' then
          game_enable <= '1';
          if start_y_p = 1 then
            if y_tile = 0 then
              if home = 0 then
                home <= "1011";
              else 
                home <= home - 1;
              end if;
              y_tile <= "0000101";
            else
              y_tile <= y_tile - 1;
            end if;
          end if;
          start_y_p <= start_y_p - 1;
        end if;
      else
        game_enable <= '0';
      end if;
    end if;
  end process;

  -- Vertical sync
  Vsync <= '0' when ((Ypixel > 489) and (Ypixel <= 491)) else '1';

  -- Video blanking signal
  blank <= '1' when ((Xpixel > 639 and Xpixel <= 799) or (Ypixel > 479 and Ypixel <= 520)) else '0';

  tile_index <= lut(to_integer(home_cp));
  y_p <= y_tile_cp;
  x_p <= xtile;
  x_out <= Xpixel - Xpepe;
  y_out <= Ypixel - Ypepe;

  spritemem : sprite
  port map (
    clk => clk,
    x_coord => x_out,
    y_coord => y_out,
    data_out_sprite => sprite_data);

  bildmem : ram
  port map (
    clk=> clk,
    x => x_p,
    y => y_p,
    t_pepe => tile_index,
    data_out => data);

  -- Tile memory
  process(clk)
  begin
    if rising_edge(clk) then
      if (blank = '0') then
        if (Xpixel > 239) then
          if (Xpixel >= Xpepe and Xpixel < Xpepe + 32) and (Ypixel >= Ypepe and Ypixel < Ypepe + 32) then
            if sprite_data = "00000000" then
              tilePixel <= data;
            else
              tilePixel <= sprite_data;
            end if;
          else  
            tilePixel <= data;
          end if;
        else
          tilePixel <= (others => '0');
        end if;
      else
        tilePixel <= (others => '0');
      end if;
    end if;
  end process;

process(clk)
  begin
    if rising_edge(clk) then
      if move_pepe_in = "010" and Xpepe < "1001011111" then
        Xpepe <= Xpepe + 1;
      elsif move_pepe_in = "001" and Xpepe > "0011110000" then
        Xpepe <= Xpepe - 1;
      elsif move_pepe_in = "011" and Ypepe <  "0111000000" then
        Ypepe <= Ypepe + 1;
      elsif move_pepe_in = "100" and Ypepe > "0000000000" then
        Ypepe <= Ypepe - 1;
      end if;
    end if;
  end process;

  -- VGA generation
  vgaRed(2)     <= tilePixel(7);
  vgaRed(1)     <= tilePixel(6);
  vgaRed(0)     <= tilePixel(5);
  vgaGreen(2)   <= tilePixel(4);
  vgaGreen(1)   <= tilePixel(3);
  vgaGreen(0)   <= tilePixel(2);
  vgaBlue(2)    <= tilePixel(1);
  vgaBlue(1)    <= tilePixel(0);
end Behavioral;
