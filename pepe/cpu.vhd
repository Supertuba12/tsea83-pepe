library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--CPU interface
entity CPU is
  port(clk: in std_logic;
	     rst: in std_logic);
end CPU ;

architecture Behavioral of CPU is

  -- micro Memory component
  component em
    port(uAddr : in unsigned(7 downto 0);
         uData : out unsigned(21 downto 0));
  end component;

  -- program Memory component
  component pMem
    port(pAddr : in unsigned(15 downto 0);
         pData : out unsigned(15 downto 0));
  end component;
  
  -- micro memory signals
  signal uM : unsigned(21 downto 0); -- micro Memory output
  signal uPC : unsigned(7 downto 0); -- micro Program Counter
  signal SEQ : unsigned(3 downto 0); -- uPC controller ###NOT USED###
  signal uAddr : unsigned(7 downto 0); -- micro Address ###NOT USED###
  signal TB : unsigned(2 downto 0); -- To Bus field ###NOT USED###
  signal FB : unsigned(2 downto 0); -- From Bus field ###NOT USED###
	signal ALU : unsigned(2 downto 0); -- ALU operand ###NOT USED###
  signal K1 : unsigned (7 downto 0); -- K1 signal
  signal K2 : unsigned (7 downto 0); -- K2 signal
  -- program memory signals
  signal PM : unsigned(15 downto 0); -- Program Memory output
  signal PC : unsigned(15 downto 0); -- Program Counter
  signal PCsig : std_logic; -- 0:PC=PC, 1:PC++ ###NOT USED###
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
      end if;
      case SEQ is
        when "0000" =>
          uPC <= uPC + 1;
        when "0001" =>
          uPC <= K1;
        when "0010" =>
          uPC <= K2;
        when "0011" =>
          uPC <= 0;
        when "1000" =>
          if (Z = '1') then -- If flagged value zero -> jump to given adress
            uPC = uAddr;
          end if;
        when "1001" =>
          if (N = '1') then -- If flagged negative value -> jump to given adress
            uPC = uAddr;
          end if;
        when "1011" =>
          if (O = '1')  -- If flagged overflow -> jump to given adress
            uPC = uAddr;
          end if;
        when "1111" =>
          -- SHUT THE MACHINE DOWN!!!
        when others =>
          null;
      end case;
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
      elsif (FB = "111") then
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
        AR <= (others => '0');
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
  with IR(15 downto 12) select K1 <=
    to_unsigned(x"05") when "0000", -- Micro adress to LOAD
    to_unsigned(x"06") when "0001", -- Micro adress to STORE
    to_unsigned(x"07") when "0010", -- Micro adress to ADD
    to_unsigned(x"0A") when "0011", -- Micro adress to SUB
    to_unsigned(x"0D") when "0100", -- Micro adress to AND
    to_unsigned(x"10") when "0101", -- Micro adress to BGE
    to_unsigned(x"15") when "0110", -- Micro adress to JMP
    to_unsigned(x"16") when "0111", -- Micro adress to CMP
    to_unsigned(x"19") when "1000"; -- Micro adress to HALT
        
  -- K2 assignment
  with IR(9 downto 8) select K2 <=
    to_unsigned(x"03") when "0", -- Direct mode
    to_unsigned(x"04") when "1"; -- Immediate mode


  -- micro memory component connection
  U0 : em port map(uAddr=>uPC, uData=>uM);

  -- program memory component connection
  U1 : pMem port map(pAddr=>ASR, pData=>PM);
	
  -- micro memory signal assignments
  -- uAddr <= uM(7 downto 0);
  -- SEQ <= uM(11 downto 8);
  -- PCsig <= uM(12);
  -- FB <= uM(15 downto 13);
  -- TB <= uM(18 downto 16);
  -- ALU <= uM(21 downto 19)

  -- Alias declaration for micro memory signal uM
  alias uAddr : unsigned(7 downto 0) is uM(7 downto 0);
  alias SEQ : unsigned(3 downto 0) is uM(11 downto 8);
  alias PCsig : std_logic is uM(12);
  alias FB : unsigned(2 downto 0) is uM(15 downto 13);
  alias TB : unsigned(2 downto 0) is uM(18 downto 16);
  alias ALU : unsigned(2 downto 0) is uM(21 downto 19)
	
  -- Alias declaration for instruction register sequences
  alias OP : unsigned(3 downto 0) is IR(15 downto 12);
  alias GR : std_logic is IR(11);
  alias addrM : std_logic is IR(10);
  alias PMaddr : unsigned(9 downto 0) is IR(9 downto 0);

  -- data bus assignment
  DATA_BUS <= 
    IR when (TB = "001") else
    PM when (TB = "010") else
    PC when (TB = "011") else
    AR when (TB = "100") else
    HELP_REG when (TB = "101") else
    GRX when (TB = "110")
    (others => '0');

end Behavioral;
