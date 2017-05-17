-- TestBench Template 

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY pepe_tb IS
END pepe_tb;

ARCHITECTURE behavior OF pepe_tb IS 

  -- Component Declaration
  COMPONENT pepe
     port (clk              : in std_logic;                         -- system clock
          rst               : in std_logic;                         -- reset
          Hsync             : out std_logic;                        -- horizontal sync
          Vsync             : out std_logic;                        -- vertical sync
          vgaRed            : out	std_logic_vector(2 downto 0);     -- VGA red
          vgaGreen          : out std_logic_vector(2 downto 0);     -- VGA green
          vgaBlue           : out std_logic_vector(2 downto 1);     -- VGA blue
          PS2KeyboardClk	  : in std_logic;                         -- PS2 clock
	        PS2KeyboardData   : in std_logic);                        -- PS2 data
    end component ;
  
  signal clk          : std_logic := '0';
  signal rst          : std_logic := '0';
  signal tb_running   : boolean := true;
  signal Hsync        : std_logic := '0';
  signal Vsync        : std_logic := '0';
  signal vgaRed       : std_logic_vector(2 downto 0) := "010";
  signal vgaGreen     : std_logic_vector(2 downto 0) := "010";
  signal vgaBlue      : std_logic_vector(2 downto 1) := "01";
  signal PS2KeyboardClk : std_logic := '1';
  signal PS2KeyboardData : std_logic := '1';
BEGIN

  -- Component Instantiation
  uut: pepe PORT MAP(
    clk => clk,
    rst => rst,
    Hsync => Hsync,
    Vsync => Vsync,
    vgaRed => vgaRed,
    vgaGreen => vgaGreen,
    vgaBlue => vgaBlue,
    PS2KeyboardClk => PS2KeyboardClk,
    PS2KeyboardData => PS2KeyboardData);


  clk_gen : process
  begin
    while tb_running loop
      clk <= '0';
      wait for 1 ns;
      clk <= '1';
      wait for 1 ns;
    end loop;
    wait;
  end process;

  

  stimuli_generator : process
    variable i : integer;
  begin
    -- Aktivera reset ett litet tag.
    rst <= '1';
    wait for 500 ns;

    wait until rising_edge(clk);        -- se till att reset släpps synkront
                                        -- med klockan
    rst <= '0';
    report "Reset released" severity note;
    wait for 1 us;
    
    for i in 0 to 500000000 loop         -- Vänta ett antal klockcykler
      wait until rising_edge(clk);
    end loop;  -- i
    
    tb_running <= false;                -- Stanna klockan (vilket medför att inga
                                        -- nya event genereras vilket stannar
                                        -- simuleringen).
    wait;
  end process;
END;
