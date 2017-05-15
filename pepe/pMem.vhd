library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- pMem interface
entity pMem is
  port(clk        : in std_logic;
       pAddr      : in unsigned(8 downto 0); -- changed to 8 from 15
       pData_out  : out unsigned(15 downto 0);
       pData_in   : in unsigned(15 downto 0);
       RW         : in std_logic
       );
end pMem;

architecture Behavioral of pMem is

-- program Memory
type p_mem_t is array (0 to 511) of unsigned(15 downto 0);
signal p_mem : p_mem_t :=
  (
x"2201",
x"0010",
x"10ee",
x"9000",
x"604e",
x"7cee",
x"5008",
x"6003",
x"00ee",
x"220a",
x"0010",
x"10ee",
x"00fa",
x"220e",
x"0001",
x"7210",
x"0010",
x"5036",
x"6003",
x"00fb",
x"2215",
x"0001",
x"7217",
x"0010",
x"503a",
x"6003",
x"00fc",
x"221c",
x"0001",
x"721e",
x"0010",
x"503e",
x"6003",
x"00fd",
x"2223",
x"0001",
x"7225",
x"0010",
x"5042",
x"6003",
x"00fe",
x"222a",
x"0001",
x"722c",
x"0010",
x"5046",
x"6003",
x"00ff",
x"2231",
x"0001",
x"7233",
x"0010",
x"504a",
x"6003",
x"0237",
x"0000",
x"10fa",
x"6013",
x"023b",
x"0000",
x"10fb",
x"601a",
x"023f",
x"0000",
x"10fc",
x"601a",
x"0243",
x"0000",
x"10fd",
x"6028",
x"0247",
x"0000",
x"10fe",
x"602f",
x"024b",
x"0000",
x"10ff",
x"6003",
x"7a4f",
x"0006",
x"506b",
x"7a52",
x"0005",
x"506b",
x"7a55",
x"0004",
x"506b",
x"7a58",
x"0003",
x"506b",
x"7a5b",
x"0002",
x"506b",
x"7a5e",
x"0001",
x"5061",
x"6005",
x"14fa",
x"6005",
x"14fb",
x"6005",
x"14fc",
x"6005",
x"14fd",
x"6005",
x"14fe",
x"6005",
x"14ff",
x"6005",
others => x"0000");


begin  -- pMem
  process(clk) begin
    if rising_edge(clk) then
      if RW = '1' then
        p_mem(to_integer(pAddr)) <= pData_in;
      end if;
    end if;
  end process;
  pData_out <= p_mem(to_integer(pAddr));
end Behavioral;

