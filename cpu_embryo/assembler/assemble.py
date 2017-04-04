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

            print("OPCODE ", line[0])



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
