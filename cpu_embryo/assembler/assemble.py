"""
    ~ Assembler for TSEA83 project ~
    Run with: python3 -c 'from assemble import *; assemble("example", "settings")'

    Output implemntation in opcalls.py
"""
import opcalls

def assemble(assembly, settings):
    """ Run assemble with your assembly code as arg0 settings as arg1 """
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
            elif "," not in line[1]: # JMP, BGE, BEQ etc
                output = (handler(line[0]))(line[1:], opcodes, adr, subr)
            else: # STORE, LOAD, ADD, SUB etc
                output = (handler(line[0]))(line[1:], opcodes, adrmodes, adr)

            output_file.write(output + "\n")

            adr[0] += 1

    output_file.close()


def handler(opcode):
    """ Python with switch """
    return {
        'LOAD': opcalls.load,
        'STORE': opcalls.store,
        'ADD': opcalls.add,
        'HALT': opcalls.halt,
        'JMP': opcalls.jmp,
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
