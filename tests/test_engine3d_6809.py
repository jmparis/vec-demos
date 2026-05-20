import subprocess
import unittest
from pathlib import Path

from test_engine3d import Ansi, ColoredTestRunner, color


ROOT = Path(__file__).resolve().parents[1]
HARNESS_ASM = ROOT / "tests" / "engine3d_6809_test.asm"
HARNESS_BIN = ROOT / "build" / "engine3d_6809_test.bin"
LOAD_ADDRESS = 0x8000
TEST_STATUS = 0xC980
SUCCESS_STATUS = 0xAA


class Cpu6809:
    def __init__(self, program, load_address):
        self.mem = bytearray(0x10000)
        self.mem[load_address : load_address + len(program)] = program
        self.pc = load_address
        self.s = 0xD000
        self.a = 0
        self.b = 0
        self.x = 0
        self.u = 0
        self.n = False
        self.z = False
        self.c = False
        self.halted = False

    @property
    def d(self):
        return ((self.a & 0xFF) << 8) | (self.b & 0xFF)

    @d.setter
    def d(self, value):
        value &= 0xFFFF
        self.a = (value >> 8) & 0xFF
        self.b = value & 0xFF

    def read8(self, address):
        return self.mem[address & 0xFFFF]

    def write8(self, address, value):
        self.mem[address & 0xFFFF] = value & 0xFF

    def read16(self, address):
        return (self.read8(address) << 8) | self.read8(address + 1)

    def write16(self, address, value):
        self.write8(address, (value >> 8) & 0xFF)
        self.write8(address + 1, value & 0xFF)

    def fetch8(self):
        value = self.read8(self.pc)
        self.pc = (self.pc + 1) & 0xFFFF
        return value

    def fetch16(self):
        high = self.fetch8()
        low = self.fetch8()
        return (high << 8) | low

    def push16(self, value):
        self.s = (self.s - 1) & 0xFFFF
        self.write8(self.s, value & 0xFF)
        self.s = (self.s - 1) & 0xFFFF
        self.write8(self.s, (value >> 8) & 0xFF)

    def pull16(self):
        high = self.read8(self.s)
        self.s = (self.s + 1) & 0xFFFF
        low = self.read8(self.s)
        self.s = (self.s + 1) & 0xFFFF
        return (high << 8) | low

    def set_nz8(self, value):
        value &= 0xFF
        self.z = value == 0
        self.n = bool(value & 0x80)

    def set_nz16(self, value):
        value &= 0xFFFF
        self.z = value == 0
        self.n = bool(value & 0x8000)

    def branch_offset(self):
        offset = self.fetch8()
        return offset - 0x100 if offset & 0x80 else offset

    def indexed_address(self):
        postbyte = self.fetch8()
        if postbyte == 0x84:  # ,X
            return self.x
        if postbyte == 0x80:  # ,X+
            address = self.x
            self.x = (self.x + 1) & 0xFFFF
            return address
        if postbyte == 0xC0:  # ,U+
            address = self.u
            self.u = (self.u + 1) & 0xFFFF
            return address
        if postbyte == 0x01:  # 1,X
            return (self.x + 1) & 0xFFFF
        if postbyte == 0x02:  # 2,X
            return (self.x + 2) & 0xFFFF
        if postbyte == 0x41:  # 1,U
            return (self.u + 1) & 0xFFFF
        raise NotImplementedError(f"Unsupported indexed postbyte ${postbyte:02X} at ${self.pc - 1:04X}")

    def load_effective_address_x(self):
        postbyte = self.fetch8()
        if postbyte == 0x86:  # A,X
            self.x = (self.x + self.a) & 0xFFFF
            return
        raise NotImplementedError(f"Unsupported LEAX postbyte ${postbyte:02X} at ${self.pc - 1:04X}")

    def load_effective_address_u(self):
        postbyte = self.fetch8()
        if postbyte == 0xC6:  # A,U
            self.u = (self.u + self.a) & 0xFFFF
            return
        raise NotImplementedError(f"Unsupported LEAU postbyte ${postbyte:02X} at ${self.pc - 1:04X}")

    def step(self):
        opcode = self.fetch8()

        if opcode == 0x3F:  # SWI
            self.halted = True
        elif opcode == 0x39:  # RTS
            self.pc = self.pull16()
        elif opcode == 0x8D:  # BSR
            offset = self.branch_offset()
            self.push16(self.pc)
            self.pc = (self.pc + offset) & 0xFFFF
        elif opcode == 0xBD:  # JSR extended
            address = self.fetch16()
            self.push16(self.pc)
            self.pc = address
        elif opcode == 0x20:  # BRA
            offset = self.branch_offset()
            self.pc = (self.pc + offset) & 0xFFFF
        elif opcode == 0x7E:  # JMP extended
            self.pc = self.fetch16()
        elif opcode == 0x26:  # BNE
            offset = self.branch_offset()
            if not self.z:
                self.pc = (self.pc + offset) & 0xFFFF
        elif opcode == 0x27:  # BEQ
            offset = self.branch_offset()
            if self.z:
                self.pc = (self.pc + offset) & 0xFFFF
        elif opcode == 0x2A:  # BPL
            offset = self.branch_offset()
            if not self.n:
                self.pc = (self.pc + offset) & 0xFFFF
        elif opcode == 0x8B:  # ADDA immediate
            self.a = (self.a + self.fetch8()) & 0xFF
            self.set_nz8(self.a)
        elif opcode == 0xBB:  # ADDA extended
            self.a = (self.a + self.read8(self.fetch16())) & 0xFF
            self.set_nz8(self.a)
        elif opcode == 0xB3:  # SUBD extended
            self.d = (self.d - self.read16(self.fetch16())) & 0xFFFF
            self.set_nz16(self.d)
        elif opcode == 0xD3:  # ADDD direct
            address = self.fetch8()
            self.d = (self.d + self.read16(address)) & 0xFFFF
            self.set_nz16(self.d)
        elif opcode == 0xF3:  # ADDD extended
            self.d = (self.d + self.read16(self.fetch16())) & 0xFFFF
            self.set_nz16(self.d)
        elif opcode == 0xC3:  # ADDD immediate
            self.d = (self.d + self.fetch16()) & 0xFFFF
            self.set_nz16(self.d)
        elif opcode == 0x81:  # CMPA immediate
            self.set_nz8((self.a - self.fetch8()) & 0xFF)
        elif opcode == 0xC1:  # CMPB immediate
            self.set_nz8((self.b - self.fetch8()) & 0xFF)
        elif opcode == 0x4F:  # CLRA
            self.a = 0
            self.set_nz8(self.a)
        elif opcode == 0x7F:  # CLR extended
            self.write8(self.fetch16(), 0)
            self.set_nz8(0)
        elif opcode == 0x4A:  # DECA
            self.a = (self.a - 1) & 0xFF
            self.set_nz8(self.a)
        elif opcode == 0x5A:  # DECB
            self.b = (self.b - 1) & 0xFF
            self.set_nz8(self.b)
        elif opcode == 0x4C:  # INCA
            self.a = (self.a + 1) & 0xFF
            self.set_nz8(self.a)
        elif opcode == 0x84:  # ANDA immediate
            self.a &= self.fetch8()
            self.set_nz8(self.a)
        elif opcode == 0x88:  # EORA immediate
            self.a ^= self.fetch8()
            self.set_nz8(self.a)
        elif opcode == 0x40:  # NEGA
            self.a = (-self.a) & 0xFF
            self.set_nz8(self.a)
        elif opcode == 0x50:  # NEGB
            self.b = (-self.b) & 0xFF
            self.set_nz8(self.b)
        elif opcode == 0x43:  # COMA
            self.a = (~self.a) & 0xFF
            self.set_nz8(self.a)
        elif opcode == 0x53:  # COMB
            self.b = (~self.b) & 0xFF
            self.set_nz8(self.b)
        elif opcode == 0x47:  # ASRA
            self.c = bool(self.a & 0x01)
            self.a = (self.a & 0x80) | (self.a >> 1)
            self.set_nz8(self.a)
        elif opcode == 0x56:  # RORB
            carry_in = 0x80 if self.c else 0
            self.c = bool(self.b & 0x01)
            self.b = carry_in | (self.b >> 1)
            self.set_nz8(self.b)
        elif opcode == 0x1F:  # TFR
            postbyte = self.fetch8()
            if postbyte != 0x98:  # B,A
                raise NotImplementedError(f"Unsupported TFR postbyte ${postbyte:02X}")
            self.a = self.b
            self.set_nz8(self.a)
        elif opcode == 0x3A:  # ABX
            self.x = (self.x + self.b) & 0xFFFF
        elif opcode == 0x3D:  # MUL
            self.d = (self.a * self.b) & 0xFFFF
            self.set_nz16(self.d)
        elif opcode == 0xA6:  # LDA indexed
            self.a = self.read8(self.indexed_address())
            self.set_nz8(self.a)
        elif opcode == 0xB6:  # LDA extended
            self.a = self.read8(self.fetch16())
            self.set_nz8(self.a)
        elif opcode == 0x86:  # LDA immediate
            self.a = self.fetch8()
            self.set_nz8(self.a)
        elif opcode == 0xE6:  # LDB indexed
            self.b = self.read8(self.indexed_address())
            self.set_nz8(self.b)
        elif opcode == 0xF6:  # LDB extended
            self.b = self.read8(self.fetch16())
            self.set_nz8(self.b)
        elif opcode == 0xC6:  # LDB immediate
            self.b = self.fetch8()
            self.set_nz8(self.b)
        elif opcode == 0xCC:  # LDD immediate
            self.d = self.fetch16()
            self.set_nz16(self.d)
        elif opcode == 0xFC:  # LDD extended
            self.d = self.read16(self.fetch16())
            self.set_nz16(self.d)
        elif opcode == 0x8E:  # LDX immediate
            self.x = self.fetch16()
            self.set_nz16(self.x)
        elif opcode == 0xBE:  # LDX extended
            self.x = self.read16(self.fetch16())
            self.set_nz16(self.x)
        elif opcode == 0xCE:  # LDU immediate
            self.u = self.fetch16()
            self.set_nz16(self.u)
        elif opcode == 0xFE:  # LDU extended
            self.u = self.read16(self.fetch16())
            self.set_nz16(self.u)
        elif opcode == 0xA7:  # STA indexed
            self.write8(self.indexed_address(), self.a)
            self.set_nz8(self.a)
        elif opcode == 0xB7:  # STA extended
            self.write8(self.fetch16(), self.a)
            self.set_nz8(self.a)
        elif opcode == 0xE7:  # STB indexed
            self.write8(self.indexed_address(), self.b)
            self.set_nz8(self.b)
        elif opcode == 0xF7:  # STB extended
            self.write8(self.fetch16(), self.b)
            self.set_nz8(self.b)
        elif opcode == 0xFD:  # STD extended
            self.write16(self.fetch16(), self.d)
            self.set_nz16(self.d)
        elif opcode == 0xBF:  # STX extended
            self.write16(self.fetch16(), self.x)
            self.set_nz16(self.x)
        elif opcode == 0xFF:  # STU extended
            self.write16(self.fetch16(), self.u)
            self.set_nz16(self.u)
        elif opcode == 0x6A:  # DEC indexed
            address = self.indexed_address()
            value = (self.read8(address) - 1) & 0xFF
            self.write8(address, value)
            self.set_nz8(value)
        elif opcode == 0x7A:  # DEC extended
            address = self.fetch16()
            value = (self.read8(address) - 1) & 0xFF
            self.write8(address, value)
            self.set_nz8(value)
        elif opcode == 0x7D:  # TST extended
            self.set_nz8(self.read8(self.fetch16()))
        elif opcode == 0x30:  # LEAX
            self.load_effective_address_x()
        elif opcode == 0x33:  # LEAU
            self.load_effective_address_u()
        else:
            raise NotImplementedError(f"Unsupported opcode ${opcode:02X} at ${self.pc - 1:04X}")

    def run(self, max_steps=200_000):
        for _ in range(max_steps):
            if self.halted:
                return
            self.step()
        raise TimeoutError("6809 harness did not halt")


class Engine3D6809Tests(unittest.TestCase):
    def test_engine3d_harness_passes_on_assembled_6809_code(self):
        """Assemble et exécute les routines Engine3D dans un environnement 6809."""
        HARNESS_BIN.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(
            [
                "lwasm",
                "-f",
                "raw",
                "-I",
                str(ROOT),
                "-o",
                str(HARNESS_BIN),
                str(HARNESS_ASM),
            ],
            cwd=ROOT,
            check=True,
        )

        cpu = Cpu6809(HARNESS_BIN.read_bytes(), LOAD_ADDRESS)
        cpu.run()

        status = cpu.read8(TEST_STATUS)
        self.assertEqual(
            SUCCESS_STATUS,
            status,
            f"6809 harness failed with TEST_STATUS=${status:02X}",
        )


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(Engine3D6809Tests)
    result = ColoredTestRunner(verbosity=0).run(suite)
    raise SystemExit(0 if result.wasSuccessful() else 1)
