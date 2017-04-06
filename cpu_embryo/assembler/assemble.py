def assemble(assembly, settings):
    settings = read_settings(settings)
    opcodes = settings[0]
    adrmodes = settings[1]
    output_file = open('code', 'w+')

    subr = {}
    adr = [0]

    with open(assembly) as asm_file:
        for line in asm_file:
            line = line.split()
            if not line or ";" in line[0]:
                continue

            if not line[0] in opcodes:
                subr[line[0]] = adr[0]
                if len(line) > 0:
                    line.remove(line[0])
                else:
                    break

            print("OPCODE: ", line)
            output = ""
            if len(line) == 1: # HALT
                output = (handler(line[0]))(opcodes)
            elif "," not in line[1]: # LOAD, STORE
                output = (handler(line[0]))(line[1:], opcodes, adr, subr)
            else:
                output = (handler(line[0]))(line[1:], opcodes, adrmodes, adr)

            output_file.write(output + "\n")

            adr[0] += 1

    output_file.close()


def handler(opcode):
    return {
        'LOAD': load,
        'STORE': store,
        'HALT': halt,
        'JMP': jmp,
    }[opcode]


def halt(opcodes):
    return opcodes['HALT'] + "000"


def load(line, opcodes, adrmodes, adr):
    line = line[0].split(',')
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

    tail_num = format((grx + adrmode_bin + adr_pos), '03x')

    if direct:
        return opcodes['LOAD'] + tail_num + "\n" + format(int(line[1][1:], 16), '04x')
    else:
        return opcodes['LOAD'] + tail_num


def store(line):
    pass


def jmp(line, opcodes, adr, subr):
    adr_pos = format(subr[line[0]], '03x')
    return opcodes['JMP'] + adr_pos


def read_settings(settings):
    with open(settings) as conf_file:
        for line in conf_file:
            if "OP" in line:
                opcodes = unpack(conf_file)
            if "MODES" in line:
                adrmodes = unpack(conf_file)

    return (opcodes, adrmodes)


def unpack(file):
    unpacked_values = {}
    for line in file:
        if "\n" in line[0]:
            break
        line = line.split(",")
        unpacked_values[line[0]] = line[1].rstrip()

    return unpacked_values
