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
x"1cee",
x"00ee",
x"2203",
x"000a",
x"10ee",
x"9000",
x"6054",
x"1cef",
x"00ef",
x"70ee",
x"500c",
x"6005",
x"00fa",
x"220e",
x"0001",
x"7210",
x"000a",
x"503c",
x"10fa",
x"6000",
x"00fb",
x"2216",
x"0001",
x"7218",
x"000a",
x"5040",
x"10fb",
x"6000",
x"00fc",
x"221e",
x"0001",
x"7220",
x"000a",
x"5044",
x"10fc",
x"6000",
x"00fd",
x"2226",
x"0001",
x"7228",
x"000a",
x"5048",
x"10fd",
x"6000",
x"00fe",
x"222e",
x"0001",
x"7230",
x"000a",
x"504c",
x"10fe",
x"6000",
x"00ff",
x"2236",
x"0001",
x"7238",
x"000a",
x"5050",
x"10ff",
x"6000",
x"023d",
x"0000",
x"10fa",
x"6014",
x"0241",
x"0000",
x"10fb",
x"601c",
x"0245",
x"0000",
x"10fc",
x"6024",
x"0249",
x"0000",
x"10fd",
x"602c",
x"024d",
x"0000",
x"10fe",
x"6034",
x"0251",
x"0000",
x"10ff",
x"6000",
x"18ea",
x"00ea",
x"7257",
x"0006",
x"5069",
x"725a",
x"0005",
x"506b",
x"725d",
x"0004",
x"506d",
x"7260",
x"0003",
x"506f",
x"7263",
x"0002",
x"5071",
x"7266",
x"0001",
x"5073",
x"6075",
x"04fa",
x"6007",
x"04fb",
x"6007",
x"04fc",
x"6007",
x"04fd",
x"6007",
x"04fe",
x"6007",
x"04ff",
x"6007",
x"1ced",
x"04ed",
x"6007",
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
