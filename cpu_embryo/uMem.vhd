library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- uMem interface
entity uMem is
  port (
    uAddr : in unsigned(5 downto 0);
    uData : out unsigned(19 downto 0));
end uMem;

architecture Behavioral of uMem is

-- micro Memory
type u_mem_t is array (0 to 19) of unsigned(19 downto 0);
constant u_mem_c : u_mem_t :=
   --OP_TB_FB_PC_uPC_uAddr
  (b"000_011_111_0_0000_000000", -- ASR:=PC
   b"000_010_001_1_0000_000000", -- IR:=PM, PC++
   b"000_000_000_0_0010_000000", -- myPC:=K2
   b"000_001_111_0_0001_000000", -- ASR:=IR, myPC:=K1
   b"000_011_111_1_0001_000000", -- ASR:=PC, PC++, myPC:=K1
   b"000_101_110_0_0011_000000", -- GR:=PM
   b"000_110_010_0_0011_000000", -- PM(A):=GR
   b"001_110_000_0_0000_000000", -- AR:=GR
   b"100_010_000_0_0000_000000", -- AR:=AR+PM(A)
   b"000_100_110_0_0011_000000", -- GR:=AR
   b"001_110_000_0_0000_000000", -- AR:=GR
   b"101_010_000_0_0000_000000", -- AR:=AR-PM(A)
   b"000_100_110_0_0011_000000", -- GR:=AR
   b"001_110_000_0_0000_000000", -- AR:=GR
   b"110_010_000_0_0000_000000", -- AR:=AR && PM(A)
   b"000_100_110_0_0011_000000", -- GR:=AR
   b"000_000_000_0_1001_010010", -- IF(N) => myPC:=12
   b"000_000_000_0_1011_000000", -- IF(O) => myPC:=0
   b"000_000_000_0_0101_010100", -- myPC:=14 (JMP)
   b"000_000_000_0_1011_010100", -- IF(0) => myPC:=14 (JMP)
   b"000_000_000_0_0011_000000", -- myPC:=0
   b"000_001_011_0_0011_000000", -- PC:=IR, myPC:=0
   b"001_110_000_0_0000_000000", -- AR:=GR
   b"101_010_000_0_0011_000000", -- AR:=AR-PM(A), myPC:=0
   b"000_000_000_0_1111_000000"); -- HALT

signal u_mem : u_mem_t := u_mem_c;

begin  -- Behavioral
  uData <= u_mem(to_integer(uAddr));

end Behavioral;
