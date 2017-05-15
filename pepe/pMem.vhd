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
x"9000",
x"6000",
x"0601",
x"0040",
x"0203",
x"0020",
x"1006",
x"1407",
x"6000",
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

