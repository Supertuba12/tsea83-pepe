def assemble(assembly, settings):
    settings = read_settings(settings)
    opcodes = settings[0]
    adrmodes = settings[1]

    subr = {}
    adr = 0
    with open(assembly) as asm_file:
        for line in asm_file:
            line = line.split()
            if not line or ";" in line[0]:
                continue

            if not line[0] in opcodes:
                subr[line[0]] = adr
                if len(line) > 0:
                    line.remove(line[0])
                    continue
                else:
                    break

            print("OPCODE: ", line)
            output = ""
            if len(line) > 1:
                output = (handler(line[0]))(line[1:], opcodes, adrmodes, adr)
            else:
                output = (handler(line[0]))(opcodes)
            print(output)
            #print(format(int(output, 16), '016b'))

            adr += 1


def handler(opcode):
    return {
        'LOAD': load,
        'STORE': store,
        'HALT': halt,
    }[opcode]


def halt(opcodes):
    return opcodes['HALT'] + "000"



def load(line, opcodes, adrmodes, adr):
    line = line[0].split(',')

    if line[0] == "GR0":
        grx = 0
    else:
        grx = 0b100000000000

    if line[1][0] == "#":
        adrmode = int(adrmodes['DIRECT'])
        adr_pos = adr + 1
    else:
        adrmode = int(adrmodes['ABSOLUTE'])
        adr_pos = int(line[1][1:], 16)

    if adrmode == 1:
        adrmode_bin = 0b010000000000
    else:
        adrmode_bin = 0

    tail_num = format((grx + adrmode_bin + adr_pos), '03x')

    return opcodes['LOAD'] + str(tail_num)


def store(line):
    pass

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
