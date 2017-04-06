def eval_args(line, opcodes, adrmodes, adr):
    direct = False

    if line[0] == "GR0":
        grx = 0
    else:
        grx = 0b100000000000

    if line[1][0] == "#":
        adrmode = int(adrmodes['DIRECT'])
        adr_pos = adr[0] + 1
        direct = True
        adr[0] += 1
    else:
        adrmode = int(adrmodes['ABSOLUTE'])
        adr_pos = int(line[1][1:], 16)

    if adrmode == 1:
        adrmode_bin = 0b010000000000
    else:
        adrmode_bin = 0

    return (direct, format((grx + adrmode_bin + adr_pos), '03x'))


def load(line, opcodes, adrmodes, adr):
    line = line[0].split(',')
    arg_result = eval_args(line, opcodes, adrmodes, adr)
    direct = arg_result[0]
    tail_num = arg_result[1]

    if direct:
        return opcodes['LOAD'] + tail_num + "\n" + format(int(line[1][1:], 16), '04x')
    else:
        return opcodes['LOAD'] + tail_num


def store(line):
    pass


def add(line, opcodes, adrmodes, adr):
    line = line[0].split(',')
    arg_result = eval_args(line, opcodes, adrmodes, adr)
    direct = arg_result[0]
    tail_num = arg_result[1]

    if direct:
        return opcodes['ADD'] + tail_num + "\n" + format(int(line[1][1:], 16), '04x')
    else:
        return opcodes['ADD'] + tail_num


def sub():
    pass


def op_cmp():
    pass


def bge():
    pass


def op_and():
    pass


def halt(opcodes):
    return opcodes['HALT'] + "000"


def jmp(line, opcodes, adr, subr):
    adr_pos = format(subr[line[0]], '03x')
    return opcodes['JMP'] + adr_pos
