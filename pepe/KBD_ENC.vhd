library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity KBD_ENC is
  port (clk	              : in std_logic;     -- system clock (100 MHz)
        rst               : in std_logic;
        PS2KeyboardClk    : in std_logic;     -- USB keyboard PS2 clock
        PS2KeyboardData   : in std_logic;     -- USB keyboard PS2 data
        movement          : out unsigned(2 downto 0));
end KBD_ENC;

-- architecture
architecture behavioral of KBD_ENC is
  signal PS2Clk                 : std_logic := '0';                                 -- Synchronized PS2 clock
  signal PS2Data                : std_logic := '0';                                 -- Synchronized PS2 data
  signal PS2Clk_Q1, PS2Clk_Q2   : std_logic := '0';                                 -- PS2 clock one pulse flip flop
  signal PS2Clk_op              : std_logic := '0';                                 -- PS2 clock one pulse 
  signal PS2Data_sr             : std_logic_vector(10 downto 0) := (others => '0'); -- PS2 data shift register
  signal PS2BitCounter          : unsigned(3 downto 0) := (others => '0');          -- PS2 bit counter
  type state_type is (IDLE, MAKE, BREAK);                                           -- declare state types for PS2
  signal PS2state               : state_type := IDLE;                               -- PS2 state
  signal ScanCode               : std_logic_vector(7 downto 0) := (others => '0');  -- scan code
  signal state                  : std_logic := '0';                                 -- MAKE or BREAK

begin
  -- Synchronize PS2-KBD signals
  process(clk) begin
    if rising_edge(clk) then
      PS2Clk <= PS2KeyboardCLK;
      PS2Data <= PS2KeyboardData;
    end if;
  end process;

  -- Generate one cycle pulse from PS2 clock, negative edge
  process(clk) begin
    if rising_edge(clk) then
      if rst = '1' then
        PS2Clk_Q1 <= '1';
        PS2Clk_Q2 <= '0';
      else
        PS2Clk_Q1 <= PS2Clk;
        PS2Clk_Q2 <= not PS2Clk_Q1;
      end if;
    end if;
  end process;

  PS2Clk_op <= (not PS2Clk_Q1) and (not PS2Clk_Q2);

  process(clk) begin
    if rising_edge(clk) then
      if rst = '1' then
        ps2Data_sr <= (others => '0');
      elsif (PS2Clk_op = '1') then
        ps2Data_sr <= PS2Data & PS2Data_sr(10 downto 1);
      end if;
    end if;
  end process;

  ScanCode <= PS2Data_sr(8 downto 1);

  -- PS2 bit counter
  -- The purpose of the PS2 bit counter is to tell the PS2 state machine when to change state
  process(clk) begin
    if rising_edge(clk) then
      if PS2BitCounter = "1011" or rst = '1' then
        PS2BitCounter <= "0000";
          -- state <= '1';
      end if;
      if PS2Clk_op = '1' then 
        PS2BitCounter <= PS2BitCounter + 1;
          -- state <= '0';
      end if;
    end if;
  end process;

    state <= '1' when (PS2BitCounter = "1011") else '0';
  -- PS2 state
  -- Either MAKE or BREAK state is identified from the scancode
  -- Only single character scan codes are identified
  -- The behavior of multiple character scan codes is undefined
  process(clk) begin
    if rising_edge(clk) then
      if rst = '1' then
        PS2State <= IDLE;
      elsif PS2state =  IDLE then
        if state = '1' then
          if ScanCode = x"f0" then
            PS2state <= BREAK;
          else
            PS2state <= MAKE;
          end if;
        end if;
      elsif PS2state = BREAK and state = '1' then
        PS2state <= IDLE;
      elsif PS2state = MAKE then
        PS2state <= IDLE;
      end if;
    end if;
  end process;

  process(clk) begin
    if rising_edge(clk) then
      if rst = '1' then
        movement <= "000";
      else
        case ScanCode is
          when x"1C" =>
            movement <= "001";
          when x"23" =>
            movement <= "010";
          when x"1B" =>
            movement <= "011";
          when x"1D" =>
            movement <= "100";
          when others =>
            movement <= "000";
        end case;
      end if;
    end if;
  end process;
end behavioral;

