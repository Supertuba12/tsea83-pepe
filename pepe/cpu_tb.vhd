-- TestBench Template 

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY cpu_tb IS
END cpu_tb;

ARCHITECTURE behavior OF cpu_tb IS 

  -- Component Declaration
  COMPONENT cpu
    port(clk         : in std_logic;
        rst          : in std_logic;
        movement_in  : in unsigned(2 downto 0)   := to_unsigned(0, 3);
        rnd_out      : out unsigned(3 downto 0)  := to_unsigned(0, 4);
        move_pepe    : out unsigned(2 downto 0)  := to_unsigned(0, 3));
    end component ;

  signal clk          : std_logic := '0';
  signal rst          : std_logic := '0';
  signal movement_in  : unsigned(2 downto 0) := "000" ;
  signal tb_running   : boolean := true;
  signal rnd_out       : unsigned(3 downto 0);
  signal move_pepe    : unsigned(2 downto 0);
BEGIN

  -- Component Instantiation
  uut: cpu PORT MAP(
    clk => clk,
    rst => rst,
    movement_in => movement_in,
    rnd_out => rnd_out,
    move_pepe => move_pepe);


  clk_gen : process
  begin
    while tb_running loop
      clk <= '0';
      wait for 5 ns;
      clk <= '1';
      wait for 5 ns;
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
    movement_in <= "001";
    report "Reset released" severity note;
    wait for 1 us;
    
    for i in 0 to 50000 loop         -- Vänta ett antal klockcykler
      wait until rising_edge(clk);
    end loop;  -- i
    
    tb_running <= false;                -- Stanna klockan (vilket medför att inga
                                        -- nya event genereras vilket stannar
                                        -- simuleringen).
    wait;
  end process;
END;
