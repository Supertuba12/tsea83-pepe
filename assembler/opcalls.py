"""
    16-bit byte code:  |A |B C D        |
                       |OP|GRX + M + ADR|
    Bit size:          |4 | 2  + 1 + 9  |
"""

""" Commented output for debugging """
COMMENTS = False

def eval_args(line, adrmodes, adr):
    """Evaluates adress mode and GRx memory """
    direct = False

    if line[0] == "GR0":
        grx = 0
    elif line[0] == "GR1":
        grx = 0b010000000000
    elif line[0] == "GR2":
        grx = 0b100000000000
    elif line[0] == "GR3":
        grx = 0b110000000000

    if line[1][0] == "#":
        adrmode = int(adrmodes['DIRECT'])
        adr_pos = adr[0] + 1
        direct = True
        adr[0] += 1
    else:
        adrmode = int(adrmodes['ABSOLUTE'])
        adr_pos = int(line[1][1:], 16)

    if adrmode == 1:
        adrmode_bin = 0b001000000000
    else:
        adrmode_bin = 0

    return (direct, format((grx + adrmode_bin + adr_pos), '03x'))


def single_arg_op(line, opcodes, subr, opc):
    """ Implementations of all jumps are the same. """
    adr_pos = format(subr[line[0]], '03x')
    if COMMENTS:
        return opcodes[opc] + adr_pos + "; " + opc
    else:
        return opcodes[opc] + adr_pos


def double_arg_op(line, opcodes, adrmodes, adr, opc):
    """ The implementation of the basic version of all dual argument operations
        is the same. """
    line = line[0].split(',')
    arg_result = eval_args(line, adrmodes, adr)
    direct = arg_result[0]
    tail_num = arg_result[1]

    if COMMENTS:
        if direct:
            return opcodes[opc] + tail_num + "; " + opc + "\n" + format(int(line[1][1:], 16), '04x')
        else:
            return opcodes[opc] + tail_num + "; " + opc
    else:
        if direct:
            return opcodes[opc] + tail_num + "\n" + format(int(line[1][1:], 16), '04x')
        else:
            return opcodes[opc] + tail_num


def load(line, opcodes, adrmodes, adr):
    """ ~ Standard LOAD ~ GRx,(#X/$Y) """
    return double_arg_op(line, opcodes, adrmodes, adr, 'LOAD')


def store(line, opcodes, adrmodes, adr):
    """ ~ Standard STORE ~ GRx,(#X/$Y) """
    return double_arg_op(line, opcodes, adrmodes, adr, 'STORE')


def add(line, opcodes, adrmodes, adr):
    """ ~ Standard ADD ~ GRx,(#X/$Y) """
    return double_arg_op(line, opcodes, adrmodes, adr, 'ADD')


def sub(line, opcodes, adrmodes, adr):
    """ ~ Standard SUB ~ GRx,(#X/$Y) """
    return double_arg_op(line, opcodes, adrmodes, adr, 'SUB')


def op_cmp(line, opcodes, adrmodes, adr):
    """ ~ Standard CMP ~ GRx,(#X/$Y) """
    return double_arg_op(line, opcodes, adrmodes, adr, 'CMP')


def bge(line, opcodes, subr):
    """ ~ Standard BGE ~ SUBROUTINE """
    return single_arg_op(line, opcodes, subr, 'BGE')


def op_and(line, opcodes, adrmodes, adr):
    """ ~ Standard CMP ~ GRx,(#X/$Y) """
    return double_arg_op(line, opcodes, adrmodes, adr, 'AND')


def halt(opcodes):
    """ ~ HALT ~ """
    if COMMENTS:
        return opcodes['HALT'] + "000; HALT"
    else:
        return opcodes['HALT'] + "000"


def jmp(line, opcodes, subr):
    """ ~ Standard JMP ~ SUBROUTINE """
    return single_arg_op(line, opcodes, subr, 'JMP')
