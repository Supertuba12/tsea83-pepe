library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--CPU interface
entity proj is
  port(clk: in std_logic;
	     rst: in std_logic);
end proj ;

architecture Behavioral of proj is


  -- micro Memory component
  component em
    port(uAddr : in unsigned(5 downto 0);
         uData : out unsigned(19 downto 0));
  end component;

  -- program Memory component
  component pMem
    port(pAddr : in unsigned(15 downto 0);
         pData : out unsigned(15 downto 0));
  end component;
  
  -- micro memory signals
  signal uM : unsigned(19 downto 0); -- micro Memory output
  signal uPC : unsigned(5 downto 0); -- micro Program Counter
  signal SEQ : unsigned(3 downto 0); -- uPC controller
  signal uAddr : unsigned(5 downto 0); -- micro Address
  signal TB : unsigned(2 downto 0); -- To Bus field
  signal FB : unsigned(2 downto 0); -- From Bus field
	signal ALU : unsigned(2 downto 0); -- ALU operand
  signal K1 : unsigned (7 downto 0); -- K1 signal
  signal K2 : unsigned (7 downto 0); -- K2 signal
  -- program memory signals
  signal PM : unsigned(15 downto 0); -- Program Memory output
  signal PC : unsigned(15 downto 0); -- Program Counter
  signal Pcsig : std_logic; -- 0:PC=PC, 1:PC++
  signal ASR : unsigned(15 downto 0); -- Address Register
  signal IR : unsigned(15 downto 0); -- Instruction Register
  signal DATA_BUS : unsigned(15 downto 0); -- Data Bus
  -- Registers
  signal AR : unsigned(15 downto 0); -- AR register for ALU
	signal HELP_REG : unsigned(15 downto 0); -- Help register
  signal GR0 : unsigned(15 downto 0); -- General-use register 
  signal GR1 : unsigned(15 downto 0); -- General-use register
  signal GRX : unsigned(15 downto 0); -- Bus signal for chosen G-register
  -- Flags
  signal Z : std_logic; -- Z = 1 if value @ AR == 0 else N = 0
  signal N : std_logic; -- N = 1 if value @ AR < 0 else N = 0
  signal O : std_logic; -- O = 1 if operation in ALU caused overflow

begin

  -- mPC : micro Program Counter
  process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        uPC <= (others => '0');
      elsif (SEQ = '') then
        uPC <= uAddr;
      else
        uPC <= uPC + 1;
      end if;
    end if;
  end process;
	
  -- PC : Program Counter
  process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        PC <= (others => '0');
      elsif (FB = "011") then
        PC <= DATA_BUS;
      elsif (PCsig = '1') then
        PC <= PC + 1;
      end if;
    end if;
  end process;
	
  -- IR : Instruction Register
  process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        IR <= (others => '0');
      elsif (FB = "001") then
        IR <= DATA_BUS;
      end if;
    end if;
  end process;
	
  -- ASR : Address Register
  process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        ASR <= (others => '0');
      elsif (FB = "100") then
        ASR <= DATA_BUS;
      end if;
    end if;
  end process;

  -- ALU component
  process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        -- Maybe reset AR?
      end if;
      case SEQ is
        when "001" => -- AR := BUSS
          AR <= DATA_BUS;
        when "010" => -- Undef. Could be set to what we want

        when "011" => -- AR := 0
          AR <= 0;
        when "100" => -- AR := AR + BUSS
          AR <= AR + DATA_BUS;
        when "101" => -- AR := AR - BUSS
          AR <= AR - DATA_BUS
        when "110" => -- AR := AR && BUSS
          AR <= AR and DATA_BUS;
        when "111" => -- AR := AR || BUSS
          AR <= AR or DATA_BUS;
        when others => -- NOP
          null;
      end case;
    end if;
  end process;  

  -- General registers 
	process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        -- Reset all registers? 
      end if;
    end if;
  end process;

  -- K1 memory
  with ALU select K1 <=
    to_unsigned(X"00") when "0000"
    to_unsigned(X"00") when "0001"
    to_unsigned(X"00") when "0010"
    to_unsigned(X"00") when "0011"
    to_unsigned(X"00") when "0100"
    to_unsigned(X"00") when "0101"
    to_unsigned(X"00") when "0110"
    to_unsigned(X"00") when "0111"
  
  -- K2 assignment


  -- micro memory component connection
  U0 : em port map(uAddr=>uPC, uData=>uM);

  -- program memory component connection
  U1 : pMem port map(pAddr=>ASR, pData=>PM);
	
  -- micro memory signal assignments
  uAddr <= (5 downto 0);
  SEQ <= (9 downto 6);
  PCsig <= (10);
  FB <= (13 downto 11);
  TB <= (16 downto 14);
  ALU <= (19 downto 17)
	
  -- data bus assignment
  DATA_BUS <= IR when (TB = "001") else
    PM when (TB = "010") else
    PC when (TB = "011") else
    ASR when (TB = "100") else
    AR when (TB = "101") else
    HELP_REG when (TB = "110") else
    GRX when (TB = "111")
    (others => '0');

end Behavioral;
