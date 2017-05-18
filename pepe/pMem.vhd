library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- pMem interface
entity pMem is
  port(clk        : in std_logic;
       rst        : in std_logic;
       pAddr      : in unsigned(8 downto 0); -- changed to 8 from 15
       pData_out  : out unsigned(15 downto 0);
       pData_in   : in unsigned(15 downto 0);
       RW         : in std_logic
       );
end pMem;

architecture Behavioral of pMem is

-- program Memory
type p_mem_t is array (0 to 511) of unsigned(15 downto 0);
constant p_mem_c : p_mem_t :=
  (
x"0201",
x"0000",
x"10fa",
x"10fb",
x"10fc",
x"10fd",
x"10fe",
x"10ff",
x"10ee",
x"10ed",
x"10ea",
x"1cee",
x"00ee",
x"220e",
x"000a",
x"10ee",
x"9000",
x"605f",
x"1cef",
x"00ef",
x"70ee",
x"5017",
x"6010",
x"00fa",
x"2219",
x"0001",
x"721b",
x"000a",
x"5047",
x"10fa",
x"600b",
x"00fb",
x"2221",
x"0001",
x"7223",
x"000a",
x"504b",
x"10fb",
x"600b",
x"00fc",
x"2229",
x"0001",
x"722b",
x"000a",
x"504f",
x"10fc",
x"600b",
x"00fd",
x"2231",
x"0001",
x"7233",
x"000a",
x"5053",
x"10fd",
x"600b",
x"00fe",
x"2239",
x"0001",
x"723b",
x"000a",
x"5057",
x"10fe",
x"600b",
x"00ff",
x"2241",
x"0001",
x"7243",
x"000a",
x"505b",
x"10ff",
x"600b",
x"0248",
x"0000",
x"10fa",
x"601f",
x"024c",
x"0000",
x"10fb",
x"6027",
x"0250",
x"0000",
x"10fc",
x"602f",
x"0254",
x"0000",
x"10fd",
x"6037",
x"0258",
x"0000",
x"10fe",
x"603f",
x"025c",
x"0000",
x"10ff",
x"600b",
x"18ea",
x"00ea",
x"7262",
x"0006",
x"5074",
x"7265",
x"0005",
x"5076",
x"7268",
x"0004",
x"5078",
x"726b",
x"0003",
x"507a",
x"726e",
x"0002",
x"507c",
x"7271",
x"0001",
x"507e",
x"6080",
x"04fa",
x"6012",
x"04fb",
x"6012",
x"04fc",
x"6012",
x"04fd",
x"6012",
x"04fe",
x"6012",
x"04ff",
x"6012",
x"1ced",
x"04ed",
x"6012",
others => x"0000");
  signal p_mem : p_mem_t := p_mem_c;

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
