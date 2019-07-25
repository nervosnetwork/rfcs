from eaglesong import EaglesongHash
import sys
from binascii import hexlify

lines = sys.stdin.readlines()
input_bytes = "\n".join(lines)
input_bytes = bytearray(input_bytes, "utf8")
output_bytes = EaglesongHash(input_bytes)
print(hexlify(bytearray(output_bytes)))



