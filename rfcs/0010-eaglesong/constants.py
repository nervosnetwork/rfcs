from CompactFIPS202 import SHAKE256

num_rounds = 43
num_constants = 16 * num_rounds
num_bytes = num_constants * 4

def padhex( integer, number_digits ):
    return "0x" + ("0" * (number_digits - len(hex(integer))+2)) + hex(integer)[2:]

#randomness = SHAKE256(bytearray("I have always been on the machines' side."), num_bytes)
randomness = SHAKE256(bytearray("The various ways in which the knowledge on which people base their plan is communicated to them is the crucial problem for any theory explaining the economic process, and the problem of what is the best way to utilizing knowledge initially dispersed among all the people is at least one of the main problems of economic policy - or of designing an efficient economic system."), num_bytes)

constants = []
for i in range(0, num_constants):
    integer = sum(256**j * randomness[i*4 + j] for j in range(0,4))
    constants.append(integer)

#print "constants = [", ", ".join(hex(c) for c in constants), "]"
print "injection_constants = [",
for i in range(0, num_constants):
    print padhex(constants[i], 8),
    if i != num_constants - 1:
        print ", ",
    if i%8 == 7 and i != num_constants - 1:
        print ""
print "]"

