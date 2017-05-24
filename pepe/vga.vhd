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
    move_pepe_in      : in unsigned(2 downto 0);
    score_in          : in unsigned(15 downto 0);
    score_out         : out unsigned(15 downto 0)
    );
end VGA;

-- architecture
architecture Behavioral of VGA is
  signal  data            : std_logic_vector(7 downto 0)  := "00000000";            -- VGA data from RAM
  signal  sprite_data     : std_logic_vector(7 downto 0)  := "00000000";            -- VGA data from SpriteMem
  signal  highScore_data  : std_logic_vector(7 downto 0)  := "00000000";            -- VGA data from HighscoreMem
  signal  Xpixel          : unsigned(9 downto 0)          := to_unsigned(0, 10);    -- Horizontal pixel counter
  signal  Ypixel          : unsigned(9 downto 0)          := to_unsigned(0, 10);    -- Vertical pixel counter
  signal  ClkDiv          : unsigned(1 downto 0)          := to_unsigned(0, 2);     -- Clock divisor, to generate 25 MHz signal
  signal  Clk25           : std_logic                     := '0';                   -- One pulse width 25 MHz signal
  signal  x_p             : unsigned(6 downto 0)          := to_unsigned(0, 7);     -- X signal for RAM
  signal  y_p             : unsigned(6 downto 0)          := to_unsigned(0, 7);     -- Y signal for RAM
  signal  x_h             : unsigned(6 downto 0)          := to_unsigned(0, 7);     -- X signal for HighscoreMem
  signal  y_h             : unsigned(6 downto 0)          := to_unsigned(0, 7);     -- Y signal for HighscoreMem
  signal  tilePixel       : std_logic_vector(7 downto 0)  := "00000000";            -- VGA data for screen output
  signal  home            : unsigned(3 downto 0)          := to_unsigned(0, 4);     -- Home pointer for lut
  signal  home_cp         : unsigned(3 downto 0)          := to_unsigned(0, 4);     -- Copy of home used decide block index in RAM
  signal  start_y_p       : unsigned(2 downto 0)          := to_unsigned(0, 3);     -- Home pointer for which Ypixel to start from
  signal  start_y_p_cp    : unsigned(2 downto 0)          := to_unsigned(0, 3);     -- Mutable copy of start_y_p
  signal  y_tile          : unsigned(6 downto 0)          := to_unsigned(0, 7);     -- Home pointer for which Ytile to start from
  signal  y_tile_cp       : unsigned(6 downto 0)          := to_unsigned(0, 7);     -- Mutable copy of y_tile
  signal  tile_index      : unsigned(4 downto 0)          := to_unsigned(0, 5);     -- Which block to choose from RAM
  signal  time_clk        : unsigned(0 downto 0)          := (others => '0');       -- When the screen should scroll
  signal  game_enable     : std_logic                     := '0';                   -- Game only progress on rising_edge of time_clk
  signal  blank           : std_logic                     := '0';                   -- blanking signal
  signal  xtile           : unsigned(6 downto 0)          := to_unsigned(0, 7);     -- Which horizontal tile to choose from RAM
  signal  x_out           : unsigned(9 downto 0)          := to_unsigned(0, 10);    -- Horizontal pixel in SpriteMem
  signal  X_pixel_h       : unsigned(6 downto 0)          := to_unsigned(0, 7);     -- Horizontal pixel in HighscoreMem
  signal  Y_pixel_h       : unsigned(6 downto 0)          := to_unsigned(0, 7);     -- Vertical pixel in HighscoreMem
  signal  y_out           : unsigned(9 downto 0)          := to_unsigned(0, 10);    -- Vertical pixel in SpriteMem
  signal  Xpepe           : unsigned(9 downto 0)          := "0110101000";          -- Horizontal position of player
  signal  Ypepe           : unsigned(9 downto 0)          := "0111000000";          -- Vertical position of player
  signal  counter         : unsigned(19 downto 0)         := to_unsigned(0, 20);    -- 20-bit counter
  signal  index_h         : unsigned(4 downto 0)          := to_unsigned(0, 5);     -- Which number or letter from HighscoreMem
  signal  home_pre        : unsigned(3 downto 0)          := to_unsigned(0, 4);     -- Previous value of Home
  signal  score_out_s     : unsigned(15 downto 0)         := to_unsigned(0, 16);    -- Signal copy of score_out used for indexing
  signal  rng             : unsigned(3 downto 0)          := (others => '0');       -- Random number for choosing next block
  signal  dead            : std_logic                     := '0';                   -- If player is dead
  signal  tile_index_s    : unsigned(4 downto 0)          := to_unsigned(0, 5);     -- tile index used when alive
  signal  tile_index_d    : unsigned(4 downto 0)          := to_unsigned(0, 5);     -- tile index used when dead    
  signal score_saved      : std_logic                     := '0';                   -- 1 if score has been saved
  
  type lut_t is array (11 downto 0) of unsigned(3 downto 0);
  type lut_2d is array (4 downto 0) of lut_t;
  constant lut_c : lut_t := (others => "0000");

  signal lut : lut_t := lut_c;                          -- Array representing the game board
  signal index_save : lut_t := lut_c;                   -- Array used for storing score and an RNG number
  signal highscore_lut : lut_2d := (others => lut_c);   -- Array used for storing previous highscores

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
  
  component highscoreMem
    port (clk               : in std_logic;
      x                     : in unsigned(6 downto 0); -- Range 0 - 15
      y                     : in unsigned(6 downto 0); -- Range 0 - 15
      tileIndex             : in unsigned(4 downto 0); -- Range 0 - 17
      data_out              : out std_logic_vector(7 downto 0));
    end component;
begin
  -- Clock divisor
  -- Divide system clock (100 MHz) by 4
  process(clk) begin
    if rising_edge(clk) then
      if rst = '1' then
        ClkDiv <= (others => '0');
      else
        ClkDiv <= ClkDiv + 1;
      end if;
    end if;
  end process;

  -- 25 MHz clock (one system clock pulse width)
  Clk25 <= '1' when (ClkDiv = 3) else '0';

  dead <= '1' when (Ypepe > 464) else '0';
  
  -- Xpixel incrementation at 60Hz
  process(clk) begin
    if rising_edge(clk) then
      if rst = '1' then
        xtile <= (others => '0');
      elsif Clk25 = '1' then
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
  process(clk) begin
    if rising_edge(clk) then
      if rst = '1' then
        rng <= (others => '0');
        home_cp <= (others => '0');
        start_y_p_cp <= (others => '0');
        y_tile_cp <= (others => '0');
        score_out <= (others => '0');
        score_out_s <= (others => '0');
      elsif Clk25 = '1' and Xpixel = 799 then
        if Ypixel(3 downto 0) < 7 then
          score_out <= to_unsigned(0, 12) & Ypixel(3 downto 0);
          score_out_s <= to_unsigned(0, 12) & Ypixel(3 downto 0);
        else
          score_out <= to_unsigned(0, 16);
          score_out_s <= to_unsigned(0, 16);
        end if;
        if dead = '0' then
          index_save(to_integer(score_out_s)) <= score_in(3 downto 0);
        end if;
        rng <= rng + index_save(0);
        if score_out_s = 6 then
          rng <= rng + score_in(3 downto 0);
        end if;
        if Ypixel(6 downto 6) = 1 and Ypixel(5 downto 0) = 0 then
          time_clk <= time_clk + 1;
        end if;
        if Ypixel = 520 then
          Ypixel <= (others => '0');
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
  process(clk) begin
    if rising_edge(clk) then
      if rst = '1' then
        game_enable <= '0';
        home <= (others => '0');
        y_tile <= (others => '0');
        start_y_p <= (others => '0');
      elsif time_clk = 1 then
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
  y_p <=
    y_tile_cp                                                         when (dead = '0' or (Ypixel <= 192 or Ypixel >= 288)) else
    "000" & to_unsigned(to_integer(Ypixel - 193), 7)(6 downto 3)      when (dead = '1' and Ypixel > 192 and Ypixel < 241)   else
    "000" & to_unsigned(to_integer(Ypixel - 241), 7) (6 downto 3)     when (dead = '1' and Ypixel > 240 and Ypixel < 288);
  x_p <= xtile;
  x_out <= Xpixel - Xpepe;
  y_out <= Ypixel - Ypepe;
  tile_index <= tile_index_s when (dead = '0') else tile_index_d;
  
  x_h <= "000" & Xpixel(3 downto 0);
  y_h <= "000" & Ypixel(3 downto 0);

  index_h <=
      to_unsigned(14, 5)             when Xpixel(8 downto 4) = 5 and Ypixel(8 downto 4) = 0 else
      to_unsigned(15, 5)             when Xpixel(8 downto 4) = 6 and Ypixel(8 downto 4) = 0 else
      to_unsigned(16, 5)             when Xpixel(8 downto 4) = 7 and Ypixel(8 downto 4) = 0 else
      to_unsigned(17, 5)             when Xpixel(8 downto 4) = 8 and Ypixel(8 downto 4) = 0 else
      to_unsigned(18, 5)             when Xpixel(8 downto 4) = 9 and Ypixel(8 downto 4) = 0 else
      "0" & index_save(1)            when Xpixel(8 downto 4) = 5 and Ypixel(8 downto 4) = 1 else
      "0" & index_save(2)            when Xpixel(8 downto 4) = 6 and Ypixel(8 downto 4) = 1 else
      "0" & index_save(3)            when Xpixel(8 downto 4) = 7 and Ypixel(8 downto 4) = 1 else
      "0" & index_save(4)            when Xpixel(8 downto 4) = 8 and Ypixel(8 downto 4) = 1 else
      "0" & index_save(5)            when Xpixel(8 downto 4) = 9 and Ypixel(8 downto 4) = 1 else
      "0" & index_save(6)            when Xpixel(8 downto 4) = 10 and Ypixel(8 downto 4) = 1 else
      to_unsigned(10, 5)             when Xpixel(8 downto 4) = 3 and Ypixel(8 downto 4) = 3 else
      to_unsigned(11, 5)             when Xpixel(8 downto 4) = 4 and Ypixel(8 downto 4) = 3 else
      to_unsigned(12, 5)             when Xpixel(8 downto 4) = 5 and Ypixel(8 downto 4) = 3 else
      to_unsigned(13, 5)             when Xpixel(8 downto 4) = 6 and Ypixel(8 downto 4) = 3 else
      to_unsigned(14, 5)             when Xpixel(8 downto 4) = 7 and Ypixel(8 downto 4) = 3 else
      to_unsigned(15, 5)             when Xpixel(8 downto 4) = 8 and Ypixel(8 downto 4) = 3 else
      to_unsigned(16, 5)             when Xpixel(8 downto 4) = 9 and Ypixel(8 downto 4) = 3 else
      to_unsigned(17, 5)             when Xpixel(8 downto 4) = 10 and Ypixel(8 downto 4) = 3 else
      to_unsigned(18, 5)             when Xpixel(8 downto 4) = 11 and Ypixel(8 downto 4) = 3 else
      to_unsigned(1, 5)              when Xpixel(8 downto 4) = 2 and Ypixel(8 downto 4) = 5 else
      "0" & highscore_lut(0)(1)      when Xpixel(8 downto 4) = 5 and Ypixel(8 downto 4) = 5 else
      "0" & highscore_lut(0)(2)      when Xpixel(8 downto 4) = 6 and Ypixel(8 downto 4) = 5 else
      "0" & highscore_lut(0)(3)      when Xpixel(8 downto 4) = 7 and Ypixel(8 downto 4) = 5 else
      "0" & highscore_lut(0)(4)      when Xpixel(8 downto 4) = 8 and Ypixel(8 downto 4) = 5 else
      "0" & highscore_lut(0)(5)      when Xpixel(8 downto 4) = 9 and Ypixel(8 downto 4) = 5 else
      "0" & highscore_lut(0)(6)      when Xpixel(8 downto 4) = 10 and Ypixel(8 downto 4) = 5 else
      to_unsigned(2, 5)              when Xpixel(8 downto 4) = 2 and Ypixel(8 downto 4) = 6 else
      "0" & highscore_lut(1)(1)      when Xpixel(8 downto 4) = 5 and Ypixel(8 downto 4) = 6 else
      "0" & highscore_lut(1)(2)      when Xpixel(8 downto 4) = 6 and Ypixel(8 downto 4) = 6 else
      "0" & highscore_lut(1)(3)      when Xpixel(8 downto 4) = 7 and Ypixel(8 downto 4) = 6 else
      "0" & highscore_lut(1)(4)      when Xpixel(8 downto 4) = 8 and Ypixel(8 downto 4) = 6 else
      "0" & highscore_lut(1)(5)      when Xpixel(8 downto 4) = 9 and Ypixel(8 downto 4) = 6 else
      "0" & highscore_lut(1)(6)      when Xpixel(8 downto 4) = 10 and Ypixel(8 downto 4) = 6 else
      to_unsigned(3, 5)              when Xpixel(8 downto 4) = 2 and Ypixel(8 downto 4) = 7 else
      "0" & highscore_lut(2)(1)      when Xpixel(8 downto 4) = 5 and Ypixel(8 downto 4) = 7 else
      "0" & highscore_lut(2)(2)      when Xpixel(8 downto 4) = 6 and Ypixel(8 downto 4) = 7 else
      "0" & highscore_lut(2)(3)      when Xpixel(8 downto 4) = 7 and Ypixel(8 downto 4) = 7 else
      "0" & highscore_lut(2)(4)      when Xpixel(8 downto 4) = 8 and Ypixel(8 downto 4) = 7 else
      "0" & highscore_lut(2)(5)      when Xpixel(8 downto 4) = 9 and Ypixel(8 downto 4) = 7 else
      "0" & highscore_lut(2)(6)      when Xpixel(8 downto 4) = 10 and Ypixel(8 downto 4) = 7 else
      to_unsigned(4, 5)              when Xpixel(8 downto 4) = 2 and Ypixel(8 downto 4) = 8 else
      "0" & highscore_lut(3)(1)      when Xpixel(8 downto 4) = 5 and Ypixel(8 downto 4) = 8 else
      "0" & highscore_lut(3)(2)      when Xpixel(8 downto 4) = 6 and Ypixel(8 downto 4) = 8 else
      "0" & highscore_lut(3)(3)      when Xpixel(8 downto 4) = 7 and Ypixel(8 downto 4) = 8 else
      "0" & highscore_lut(3)(4)      when Xpixel(8 downto 4) = 8 and Ypixel(8 downto 4) = 8 else
      "0" & highscore_lut(3)(5)      when Xpixel(8 downto 4) = 9 and Ypixel(8 downto 4) = 8 else
      "0" & highscore_lut(3)(6)      when Xpixel(8 downto 4) = 10 and Ypixel(8 downto 4) = 8 else
      to_unsigned(5, 5)              when Xpixel(8 downto 4) = 2 and Ypixel(8 downto 4) = 9 else
      "0" & highscore_lut(4)(1)      when Xpixel(8 downto 4) = 5 and Ypixel(8 downto 4) = 9 else
      "0" & highscore_lut(4)(2)      when Xpixel(8 downto 4) = 6 and Ypixel(8 downto 4) = 9 else
      "0" & highscore_lut(4)(3)      when Xpixel(8 downto 4) = 7 and Ypixel(8 downto 4) = 9 else
      "0" & highscore_lut(4)(4)      when Xpixel(8 downto 4) = 8 and Ypixel(8 downto 4) = 9 else
      "0" & highscore_lut(4)(5)      when Xpixel(8 downto 4) = 9 and Ypixel(8 downto 4) = 9 else
      "0" & highscore_lut(4)(6)      when Xpixel(8 downto 4) = 10 and Ypixel(8 downto 4) = 9 else
      to_unsigned(19, 5);
  

  process(clk) begin
    if rising_edge(clk) then
      if rst = '1' then
        tile_index_s <= (others => '0');
        home_pre <= (others => '0');
        lut <= lut_c;
      else
        tile_index_s <= "0" & lut(to_integer(home_cp));
        if home /= home_pre then
          home_pre <= home;
          if home(0 downto 0) = 1 then
            lut(to_integer(home) - 1) <= rng;
          end if;
        end if;
      end if;
    end if;
  end process;

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

  highscore : highscoreMem
  port map (
    clk=> clk,
    x => x_h,
    y => y_h,
    tileIndex => index_h,
    data_out => highScore_data);

  -- Tile memory
process(clk) begin
  if rising_edge(clk) then
    if rst = '1' then
        Xpepe <= "0110101000";
        Ypepe <= "0111000000";
    else
      if dead = '0' then
        if counter = 0 then
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
      end if;
      if (blank = '0') then
        if (Xpixel < 240) then
           tilePixel <= highScore_data;
        elsif dead = '0' then
            -- Spelplan
          if (Xpixel >= Xpepe and Xpixel < Xpepe + 32) and (Ypixel >= Ypepe and Ypixel < Ypepe + 32) then
            if sprite_data = "00000000" then
              tilePixel <= data;
            elsif data = "00000000" then
                tilePixel <= sprite_data;
            else
              if (Ypixel - Ypepe) = 17 then
                case move_pepe_in is
                  when "010" => Xpepe <= Xpepe - 1;
                  when "001" => Xpepe <= Xpepe + 1;
                  when others => Ypepe <= Ypepe + 1;
                end case;
              elsif (Ypixel - Ypepe) < 17 then
                if Ypixel - Ypepe < 13 and Ypixel - Ypepe > 5 then
                  case move_pepe_in is
                    when "010" => Xpepe <= Xpepe - 1;
                    when "001" => Xpepe <= Xpepe + 1;
                    when others => null;
                  end case;
                else
                  Ypepe <= Ypepe + 1;
                  if (Xpixel - Xpepe < 13) then
                    Xpepe <= Xpepe + 1;
                  elsif (Xpixel - Xpepe > 18) then
                    Xpepe <= Xpepe - 1;
                  end if;
                end if;
              else
                if Xpixel - Xpepe < 13 then
                  Xpepe <= Xpepe + 1;
                elsif Xpixel - Xpepe > 18 then
                  Xpepe <= Xpepe - 1;
                else
                  Ypepe <= Ypepe - 1;
                end if;
              end if;
            end if;
          else
            tilePixel <= data;
          end if;
        
        elsif dead = '1' then
          if (Xpixel >= Xpepe and Xpixel < Xpepe + 32) and (Ypixel >= Ypepe and Ypixel < Ypepe + 32) then
            if sprite_data = "00000000" then
              tilePixel <= data;
            elsif data = "00000000" then
              tilePixel <= sprite_data;
            end if;
          elsif Ypixel > 192 and Ypixel < 241 then -- GAME
            tile_index_d <= to_unsigned(16, 5);
            tilePixel <= data;
          elsif  Ypixel > 240 and  Ypixel < 288 then -- OVER
            tile_index_d <= to_unsigned(17, 5);
            tilePixel <= data;
          else
            tile_index_d <= "0" & lut(to_integer(home_cp));
            tilePixel <= data;
          end if;
        else
          tilePixel <= (others => '0');
        end if;
      end if;
    end if;
  end if;
end process;

  process(clk) begin
    if rising_edge(clk) then
      counter <= counter + 1;
    end if;
  end process;


 process(clk) begin
    if rising_edge(clk) then
      if rst = '1' and score_saved = '0' then
        if index_save(1) > highscore_lut(0)(1) then
          highscore_lut <= highscore_lut(3 downto 0) & index_save;
          score_saved <= '1';
        elsif index_save(1) = highscore_lut(0)(1) then
          if index_save(2) > highscore_lut(0)(2) then
            highscore_lut <= highscore_lut(3 downto 0) & index_save;
            score_saved <= '1';
          elsif index_save(2) = highscore_lut(0)(2) then
            if index_save(3) > highscore_lut(0)(3) then
              highscore_lut <= highscore_lut(3 downto 0) & index_save;
              score_saved <= '1';
            elsif index_save(3) = highscore_lut(0)(3) then
              if index_save(4) > highscore_lut(0)(4) then
                highscore_lut <= highscore_lut(3 downto 0) & index_save;
                score_saved <= '1';
              elsif index_save(4) = highscore_lut(0)(4) then
                if index_save(5) > highscore_lut(0)(5) then
                  highscore_lut <= highscore_lut(3 downto 0) & index_save;
                  score_saved <= '1';
                elsif index_save(5) = highscore_lut(0)(5) then
                  if index_save(6) >= highscore_lut(0)(6) then
                    highscore_lut <= highscore_lut(3 downto 0) & index_save;
                    score_saved <= '1';
                  end if;
                end if;
              end if;
            end if;
          end if;
        end if;
      elsif rst = '0' then
        score_saved <= '0';
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
