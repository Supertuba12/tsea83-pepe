"""
      Assembler for TSEA83 project  
    Run with: python3 -c 'from assemble import *; assemble("example", "settings")'
          or: python3 assemble.py example settings

    Output implemntation in opcalls.py
"""
import sys
import opcalls

COMMENTS = False

def assemble(assembly, settings):
    """ Run assemble with your assembly code as arg0 settings as arg1 """
    settings = read_settings(settings)
    opcodes = settings[0]
    adrmodes = settings[1]
    output_file = open('code', 'w+')

    subr = {}
    adr = [0]

    eval_subr(assembly, adr, subr, opcodes)
    print(subr)
    adr = [0]

    with open(assembly) as asm_file:
        for line in asm_file:
            line = line.split()
            if not line or ";" in line[0]:
                continue

            if not line[0] in opcodes:
                if len(line) > 1:
                    line.remove(line[0])
                else:
                    continue

            if len(line) > 0:
                print("OPCODE: ", line[0:2])
                if len(line) == 1 or ";" in line[1]: # HALT
                    output = (handler(line[0]))(opcodes)
                elif "," not in line[1]: # JMP, BGE, BEQ, SYNC etc
                    output = (handler(line[0]))(line[1:2], opcodes, subr)
                else: # STORE, LOAD, ADD, SUB etc
                    output = (handler(line[0]))(line[1:2], opcodes, adrmodes, adr)
            else:
                continue

            if COMMENTS:
                if "\n" in output:
                    output = output.split("\n")
                    output_file.write(format((adr[0] - 1), 'x') + ": " + output[0] + "\n")
                    output_file.write(format(adr[0], 'x') + ": " + output[1] + "\n")
                else:
                    output_file.write(format(adr[0], 'x') + ": " + output + "\n")
            else:
                output_file.write(output + "\n")

            adr[0] += 1

    output_file.close()


def eval_subr(assembly, adr, subr, opcodes):
    """ Finds all subroutines """
    with open(assembly) as asm_file:
        empty_row = False
        subr_cp = ""
        for line in asm_file:
            line = line.split()
            if not line or ";" in line[0]:
                continue

            if empty_row:
                subr[subr_cp] = adr[0]
                empty_row = False

            if not line[0] in opcodes:
                if len(line) > 1:
                    subr[line[0]] = adr[0]
                    line.remove(line[0])
                else:
                    subr_cp = line[0]
                    empty_row = True
                    continue

            if len(line) > 1 and "#" in line[1]:
                adr[0] += 1

            adr[0] += 1


def handler(opcode):
    """ Python with switch """
    return {
        'LOAD': opcalls.load,
        'STORE': opcalls.store,
        'ADD': opcalls.add,
        'SUB': opcalls.sub,
        'CMP': opcalls.op_cmp,
        'BGE': opcalls.bge,
        'AND': opcalls.op_and,
        'HALT': opcalls.halt,
        'JMP': opcalls.jmp,
        'MOVE': opcalls.move,
    }[opcode]


def read_settings(settings):
    """ Reads the settings file. """
    with open(settings) as conf_file:
        for line in conf_file:
            if "OP" in line:
                opcodes = unpack(conf_file)
            if "MODES" in line:
                adrmodes = unpack(conf_file)

    return (opcodes, adrmodes)


def unpack(file):
    """ Unpacks each section of settings. """
    unpacked_values = {}
    for line in file:
        if "\n" in line[0]:
            break
        line = line.split(",")
        unpacked_values[line[0]] = line[1].rstrip()

    return unpacked_values

if __name__ == "__main__":
    assemble(sys.argv[1], sys.argv[2])
