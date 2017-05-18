library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--CPU interface
entity CPU is
  port(clk          : in std_logic;
       rst          : in std_logic;
       movement_in  : in unsigned(2 downto 0);
       move_pepe    : out unsigned(2 downto 0);
       vga_in           : in unsigned(15 downto 0);
       vga_out          : out unsigned(15 downto 0)
       );
end CPU ;

architecture Behavioral of CPU is

  -- micro Memory component
  component uMem
    port(uAddr    : in unsigned(5 downto 0);
         uData    : out unsigned(19 downto 0));
  end component;

  -- program Memory component
  component pMem
    port(clk        : in std_logic;
         rst        : in std_logic;
         pAddr      : in unsigned(8 downto 0);
         pData_out  : out unsigned(15 downto 0);
         pData_in   : in unsigned(15 downto 0);
         RW         : in std_logic
         );
  end component;

  -- micro memory signals
  signal uM       : unsigned(19 downto 0) := to_unsigned(0, 20);    -- micro Memory output
  signal uPC      : unsigned(5 downto 0)  := to_unsigned(0, 6);    -- micro Program Counter
  signal SEQ      : unsigned(3 downto 0)  := to_unsigned(0, 4);    -- uPC controller
  signal uAddr_s  : unsigned(5 downto 0)  := to_unsigned(0, 6);    -- micro Address
  signal TB       : unsigned(2 downto 0)  := to_unsigned(0, 3);    -- To Bus field
  signal FB       : unsigned(2 downto 0)  := to_unsigned(0, 3);    -- From Bus field
  signal ALU      : unsigned(2 downto 0)  := to_unsigned(0, 3);    -- ALU operand
  signal K1       : unsigned (5 downto 0) := to_unsigned(0, 6);    -- K1 signal
  signal K2       : unsigned (5 downto 0) := to_unsigned(0, 6);    -- K2 signal
  -- program memory signals
  signal PM       : unsigned(15 downto 0) := to_unsigned(0, 16);    -- Program Memory output
  signal PC       : unsigned(8 downto 0)  := to_unsigned(0, 9);     -- Program Counter
  signal PCsig    : std_logic             := '0';                   -- 0:PC=PC, 1:PC++ 
  signal ASR      : unsigned(8 downto 0)  := to_unsigned(0, 9);     -- Address Register
  signal IR       : unsigned(15 downto 0) := to_unsigned(0, 16);    -- Instruction Register
  signal DATA_BUS : unsigned(15 downto 0) := to_unsigned(0, 16);    -- Data Bus
  signal RW_s     : std_logic             := '0';                   -- Read/Write signal to pMem
  -- Registers
  signal AR       : unsigned(15 downto 0) := to_unsigned(0, 16);    -- AR register for ALU
  signal AR_pre   : unsigned(15 downto 0) := to_unsigned(0, 16);    -- AR_pre register used when checking for overflow
  signal HELP_REG : unsigned(15 downto 0) := to_unsigned(0, 16);    -- Help register
  signal GR       : unsigned(15 downto 0) := to_unsigned(0, 16);   
  signal GR0      : unsigned(15 downto 0) := to_unsigned(0, 16);   
  signal GR1      : unsigned(15 downto 0) := to_unsigned(1, 16);   
  signal GR2      : unsigned(15 downto 0) := to_unsigned(0, 16);   
  signal GR3      : unsigned(15 downto 0) := to_unsigned(0, 16);    -- millisecond clock
  -- IR parts
  signal OP       : unsigned(3 downto 0)  := to_unsigned(0, 4);   
  signal GRX      : unsigned(1 downto 0)  := to_unsigned(0, 2);
  signal M        : std_logic             := '0';
  signal ADR      : unsigned(8 downto 0)  := to_unsigned(0, 9);   
  -- Flags
  signal Z        : std_logic             := '0'; -- Z = 1 if value @ AR == 0 else N = 0
  signal N        : std_logic             := '0'; -- N = 1 if value @ AR < 0 else N = 0
  signal O        : std_logic             := '0'; -- O = 1 if operation in ALU caused overflow
  -- General signals
  signal counter  : unsigned(31 downto 0) := to_unsigned(0, 32);   
  --signal KBD_en_pre : std_logic;

begin
  GR2 <= vga_in;
  vga_out <= GR1;
  -- real time counter
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        counter <= (others => '0');
        GR3 <= (others => '0');
      else
        counter <= counter + 1;
        if counter = 1000000 then
          GR3 <= GR3 + 1;
          counter <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  -- mPC : micro Program Counter
  process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        uPC <= (others => '0');
      else
        case SEQ is
          when "0000" => uPC <= uPC + 1;
          when "0001" => uPC <= K1;
          when "0010" => uPC <= K2;
          when "0011" => uPC <= to_unsigned(0, 6);
          when "0101" => uPc <= uAddr_s;
          when "1000" =>
            if (Z = '1') then -- If flagged value zero -> jump to given adress
              uPC <= uAddr_s;
            else
              uPc <= uPC + 1;
            end if;
          when "1001" =>
            if (N = '1') then -- If flagged negative value -> jump to given adress
              uPC <= uAddr_s;
            else
              uPc <= uPC + 1;
            end if;
          when "1011" =>
            if (O = '1') then  -- If flagged overflow -> jump to given adress
              uPC <= uAddr_s;
            else
              uPc <= uPC + 1;
            end if;
          when "1111" =>
            -- Do some bamboozle thingy
          when others =>
            null;
        end case;
      end if;
    end if;
  end process;

  -- PC : Program Counter
  process(clk) begin
    if rising_edge(clk) then
      if (rst = '1') then
        PC <= (others => '0');
      elsif (FB = "011") then
        PC <= DATA_BUS(8 downto 0);
      elsif (PCsig = '1') then
        PC <= PC + 1;
      else 
        null;
      end if;
    end if;
  end process;

  -- IR : Instruction Register
  process(clk) begin
    if rising_edge(clk) then
      if (rst = '1') then
        IR <= (others => '0');
      elsif (FB = "001") then
        IR <= DATA_BUS;
      end if;
    end if;
  end process;

  -- ASR : Address Register
  process(clk) begin
    if rising_edge(clk) then
      if (rst = '1') then
        ASR <= (others => '0');
      elsif (FB = "111") then
        ASR <= DATA_BUS(8 downto 0);
      end if;
    end if;
  end process;

  -- ALU component
  process(clk) begin
    if rising_edge(clk) then
      if (rst = '1') then
        AR <= (others => '0');
      else
        case ALU is
          when "001" => -- AR := BUSS
            AR <= DATA_BUS;
          when "010" => -- SYNC
            move_pepe <= movement_in;
          when "011" => -- AR := 0
            AR <= to_unsigned(0, 16);
          when "100" => -- AR := AR + BUSS
            AR_pre <= AR;
            AR <= AR + DATA_BUS;
          when "101" => -- AR := AR - BUSS
            AR_pre <= AR;
            AR <= AR - DATA_BUS; 
          when "110" => -- AR := AR && BUSS
            AR <= AR and DATA_BUS;
          when "111" => -- AR := AR || BUSS
            AR <= AR or DATA_BUS;
          when others => -- NOP
            null;
        end case;
      end if;
    end if;
  end process;  
  
  Z <= '1' when (AR = 0) else '0';
  N <= '1' when (AR(15 downto 15) = 1) else '0';
  O <= '1' when ((AR_pre(15 downto 15) = DATA_BUS(15 downto 15)) and (AR(15 downto 15) /= (AR_pre(15 downto 15)))) else '0';

 -- General registers 
  process(clk) begin
    if rising_edge(clk) then
      if rst = '1' then
        GR1 <= (others => '0');
        GR0 <= (others => '0');
      elsif FB = "110" then
        case GRX is
        when "00" =>
          GR0 <= DATA_BUS;
        when "01" =>
          GR1 <= DATA_BUS;
        when others =>
          null;
        end case;  
      end if;
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
    to_unsigned(24, 6)  when "1000", -- Micro adress to HALT
    to_unsigned(25, 6)  when "1001", -- Micro adress to MOVE
    to_unsigned(26, 6)  when "1111", -- Micro adress to NOP
    to_unsigned(0, 6)   when others;
  -- K2 assignment
  with M select K2 <=
    to_unsigned(3, 6)   when '0', -- Direct mode
    to_unsigned(4, 6)   when '1', -- Immediate mode
    to_unsigned(0, 6)   when others;
  -- micro memory component connection
  U0 : uMem port map(uAddr=>uPC, uData=>uM);

  -- program memory component connection
  U1 : pMem port map(clk=>clk, rst=>rst, pAddr=>ASR, pData_out=>PM, pData_in=>DATA_BUS, RW=>RW_s);

  -- micro memory signal assignments
  uAddr_s <= uM(5 downto 0);
  SEQ     <= uM(9 downto 6);
  PCsig   <= uM(10);
  FB      <= uM(13 downto 11);
  TB      <= uM(16 downto 14);
  ALU     <= uM(19 downto 17);
  
  -- Instruction register signal assignments
  OP     <= IR(15 downto 12);
  GRX    <= IR(11 downto 10);
  M      <= IR(9);
  ADR    <= IR(8 downto 0);

  -- data bus assignment
  DATA_BUS <= 
    IR                        when (TB = "001") else
    PM                        when (TB = "010") else
    to_unsigned(0, 16) + PC   when (TB = "011") else
    AR                        when (TB = "100") else
    GR                        when (TB = "110") else
    (others => '0');

  -- MuX for general registers
  with GRX select GR <=
    GR0       when "00",
    GR1       when "01",
    GR2       when "10",
    GR3       when "11",
    GR0       when others;
  
  RW_s <= '1' when (uPC = "000110") else '0';

end Behavioral;
