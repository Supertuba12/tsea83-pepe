library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--CPU interface
entity CPU is
  port(clk          : in std_logic;
       rst          : in std_logic;
       movement_in  : in unsigned(2 downto 0);
       rng_ut       : out unsigned(3 downto 0);
       move_pepe    : out unsigned(2 downto 0));
end CPU ;

architecture Behavioral of CPU is

  -- micro Memory component
  component uMem
    port(uAddr    : in unsigned(5 downto 0);
         uData    : out unsigned(19 downto 0));
  end component;

  -- program Memory component
  component pMem
    port(pAddr      : in unsigned(15 downto 0);
         pData_out  : out unsigned(15 downto 0);
         pData_in   : in unsigned(15 downto 0);
         RW         : in std_logic
         );
  end component;

  -- micro memory signals
  signal uM       : unsigned(19 downto 0); -- micro Memory output
  signal uPC      : unsigned(5 downto 0); -- micro Program Counter
  signal SEQ      : unsigned(3 downto 0); -- uPC controller ###NOT USED###
  signal uAddr    : unsigned(5 downto 0); -- micro Address ###NOT USED###
  signal TB       : unsigned(2 downto 0); -- To Bus field ###NOT USED###
  signal FB       : unsigned(2 downto 0); -- From Bus field ###NOT USED###
  signal ALU      : unsigned(2 downto 0); -- ALU operand ###NOT USED###
  signal K1       : unsigned (5 downto 0); -- K1 signal
  signal K2       : unsigned (5 downto 0); -- K2 signal
  -- program memory signals
  signal PM       : unsigned(15 downto 0); -- Program Memory output
  signal PC       : unsigned(15 downto 0); -- Program Counter
  signal PCsig    : std_logic; -- 0:PC=PC, 1:PC++ ###NOT USED###
  signal ASR      : unsigned(15 downto 0); -- Address Register
  signal IR       : unsigned(15 downto 0); -- Instruction Register
  signal DATA_BUS : unsigned(15 downto 0); -- Data Bus
  signal RW_s     : std_logic;             -- Read/Write signal to pMem
  -- Registers
  signal AR       : unsigned(15 downto 0); -- AR register for ALU
  signal AR_pre   : unsigned(15 downto 0); -- AR_pre register used when checking for overflow
  signal HELP_REG : unsigned(15 downto 0); -- Help register
  signal GR       : unsigned(15 downto 0);
  signal GR0      : unsigned(15 downto 0); -- General-use register 
  signal GR1      : unsigned(15 downto 0); -- General-use register
  signal GR2      : unsigned(15 downto 0);
  signal GR3      : unsigned(15 downto 0) := to_unsigned(0, 16);   -- millisecond clock
  -- IR parts
  signal OP       : unsigned(3 downto 0);
  signal GRX      : unsigned(1 downto 0);
  signal M        : std_logic;
  signal ADR      : unsigned(8 downto 0);
  -- Flags
  signal Z        : std_logic; -- Z = 1 if value @ AR == 0 else N = 0
  signal N        : std_logic; -- N = 1 if value @ AR < 0 else N = 0
  signal O        : std_logic; -- O = 1 if operation in ALU caused overflow
  -- General signals
  signal counter  : unsigned(16 downto 0);


begin
  GR2 <= to_unsigned(0, 16) + movement_in;
  process(clk)
  begin
    if rising_edge(clk) then
      counter <= counter + 1;
      if counter = 100000 then
        GR3 <= GR3 + 1;
        counter <= to_unsigned(0, 17);
      end if;
    end if;
  end process;

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
          uPC <= to_unsigned(0, 6);
        when "1000" =>
          if (Z = '1') then -- If flagged value zero -> jump to given adress
            uPC <= uAddr;
          end if;
        when "1001" =>
          if (N = '1') then -- If flagged negative value -> jump to given adress
            uPC <= uAddr;
          end if;
        when "1011" =>
          if (O = '1') then  -- If flagged overflow -> jump to given adress
            uPC <= uAddr;
          end if;
        when "1111" =>
          -- Do some bamboozle thingy
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
      case ALU is
        when "001" => -- AR := BUSS
          AR <= DATA_BUS;
        when "010" => -- Undef. Could be set to what we want
          case ADR is
            when to_unsigned(0, 9) =>
              move_pepe <= PM;
            when others =>
              null;
          end case;
        when "011" => -- AR := 0
          AR <= to_unsigned(0, 16);
        when "100" => -- AR := AR + BUSS
          AR_pre <= AR;
          AR <= AR + DATA_BUS;
          if AR(15 downto 15) = 1 then
            N <= '1'; 
          else
            N <= '0';
          end if;
          if AR = 0 then
            Z <= '1';
          else
            Z <= '0';
          end if;
          if (AR_pre(15 downto 15) = 1 and DATA_BUS(15 downto 15) = 1 and AR(15 downto 15) = 0) or 
              (AR_pre(15 downto 15) = 0 and DATA_BUS(15 downto 15) = 0 and AR(15 downto 15) = 1) then
            O <= '1';
          else
            O <= '0';
          end if;
        when "101" => -- AR := AR - BUSS
          AR_pre <= AR;
          AR <= AR - DATA_BUS;
          if AR(15 downto 15) = 1 then
            N <= '1'; 
          else
            N <= '0';
          end if;
          if AR = 0 then
            Z <= '1';
          else
            Z <= '0';
          end if;
          if (AR_pre(15 downto 15) = 1 and DATA_BUS(15 downto 15) = 1 and AR(15 downto 15) = 0) or 
              (AR_pre(15 downto 15) = 0 and DATA_BUS(15 downto 15) = 0 and AR(15 downto 15) = 1) then
            O <= '1';
          else
            O <= '0'; 
          end if; 
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
    if rst = '1' then
      -- Reset all registers? 
    end if;
    if rising_edge(clk) then
     
    end if;
  end process;

  -- K1 memory
  with OP select K1 <=
    to_unsigned(5, 6)   when "0000", -- Micro adress to LOAD
    to_unsigned(6, 6)   when "0001", -- Micro adress to STORE
    to_unsigned(7, 6)   when "0010", -- Micro adress to ADD
    to_unsigned(10, 6)  when "0011", -- Micro adress to SUB
    to_unsigned(13, 6)  when "0100", -- Micro adress to AND
    to_unsigned(16, 6)  when "0101", -- Micro adress to BGE
    to_unsigned(21, 6)  when "0110", -- Micro adress to JMP
    to_unsigned(22, 6)  when "0111", -- Micro adress to CMP
    to_unsigned(25, 6)  when "1000", -- Micro adress to HALT
    to_unsigned(26, 6)  when "1001"; -- Micro adress to SYNC

  -- K2 assignment
  with M select K2 <=
    to_unsigned(3, 6)   when '0', -- Direct mode
    to_unsigned(4, 6)   when '1'; -- Immediate mode

  -- micro memory component connection
  U0 : uMem port map(uAddr=>uPC, uData=>uM);

  -- program memory component connection
  U1 : pMem port map(pAddr=>ASR, pData_out=>PM, pData_in => AR, RW => RW_s);

  -- micro memory signal assignments
  uAddr  <= uM(5 downto 0);
  SEQ    <= uM(9 downto 6);
  PCsig  <= uM(10);
  FB     <= uM(13 downto 11);
  TB     <= uM(16 downto 14);
  ALU    <= uM(19 downto 17);
  OP     <= IR(15 downto 12);
  GRX    <= IR(11 downto 10);
  M      <= IR(9);
  ADR    <= IR(8 downto 0);

  -- data bus assignment
  DATA_BUS <= 
    IR        when (TB = "001") else
    PM        when (TB = "010") else
    PC        when (TB = "011") else
    AR        when (TB = "100") else
    GR        when (TB = "110") else
    (others => '0');

  -- MuX for general registers
  with GRX select GR <=
    GR0       when "00",
    GR1       when "01",
    GR2       when "10",
    GR3       when "11";

  -- Read/write decision
  RW_s <= 
    '1' when (OP = "0001") else
    '1' when (ALU = "010") else
    '0';

end Behavioral;
