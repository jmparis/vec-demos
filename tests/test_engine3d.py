import math
import re
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ENGINE3D_ASM = ROOT / "src" / "cube" / "engine3d.asm"
CUBE_ASM = ROOT / "src" / "cube" / "cube.asm"
MAKEFILE = ROOT / "Makefile"
TRIG_TABLE_SIZE = 128
Q6_SCALE = 64
Q6_MAX_ROUNDING_ERROR = 0.5 / Q6_SCALE


class Ansi:
    RESET = "\033[0m"
    BOLD = "\033[1m"
    BLUE = "\033[1;34m"
    CYAN = "\033[1;36m"
    GREEN = "\033[1;32m"
    RED = "\033[1;31m"
    YELLOW = "\033[1;33m"


def color(text, code):
    return f"{code}{text}{Ansi.RESET}"


def read_text(path):
    return path.read_text(encoding="utf-8")


def parse_number(token):
    token = token.strip()
    if token.startswith("-$"):
        return -int(token[2:], 16)
    if token.startswith("$"):
        return int(token[1:], 16)
    return int(token)


def extract_fcb_table(text, label):
    lines = text.splitlines()
    values = []
    in_table = False
    label_pattern = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*:")

    for line in lines:
        if line.startswith(f"{label}:"):
            in_table = True
            continue
        if in_table and label_pattern.match(line):
            break
        if not in_table or "FCB" not in line:
            continue

        payload = line.split("FCB", 1)[1].split(";", 1)[0]
        values.extend(parse_number(token) for token in payload.split(",") if token.strip())

    return values


def assert_q6_table_matches_function(test_case, table, trig_function):
    max_error = 0.0
    max_error_index = None

    test_case.assertEqual(TRIG_TABLE_SIZE, len(table))
    for index, raw_value in enumerate(table):
        angle = 2 * math.pi * index / TRIG_TABLE_SIZE
        actual = raw_value / Q6_SCALE
        expected = trig_function(angle)
        error = abs(actual - expected)
        if error > max_error:
            max_error = error
            max_error_index = index
        with test_case.subTest(index=index, raw_value=raw_value):
            test_case.assertLessEqual(
                error,
                Q6_MAX_ROUNDING_ERROR + 1e-12,
                (
                    f"index={index}, raw={raw_value}, actual={actual:.6f}, "
                    f"expected={expected:.6f}, error={error:.6f}"
                ),
            )

    return max_error_index, max_error


class Engine3DTableTests(unittest.TestCase):
    def setUp(self):
        self.engine_text = read_text(ENGINE3D_ASM)

    def test_angle_mask_matches_128_entries(self):
        """Vérifie que le masque d'angle couvre les 128 entrées."""
        self.assertIn("ENGINE3D_ANGLE_MASK EQU         $7F", self.engine_text)

    def test_cos_table_stays_close_to_real_cosine(self):
        """Compare la table Cosine Q6 aux vraies valeurs math.cos."""
        cos_table = extract_fcb_table(self.engine_text, "Engine3D_CosTable")
        max_error_index, max_error = assert_q6_table_matches_function(self, cos_table, math.cos)

        self.assertLessEqual(max_error, Q6_MAX_ROUNDING_ERROR + 1e-12)
        self.assertIsNotNone(max_error_index)

    def test_sin_table_stays_close_to_real_sine(self):
        """Compare la table Sine Q6 aux vraies valeurs math.sin."""
        sin_table = extract_fcb_table(self.engine_text, "Engine3D_SinTable")
        max_error_index, max_error = assert_q6_table_matches_function(self, sin_table, math.sin)

        self.assertLessEqual(max_error, Q6_MAX_ROUNDING_ERROR + 1e-12)
        self.assertIsNotNone(max_error_index)

    def test_trig_tables_are_separate_and_loaded_directly(self):
        """Vérifie que Cosine et Sine sont séparées et indexées directement."""
        self.assertIn("Engine3D_CosTable:", self.engine_text)
        self.assertIn("Engine3D_SinTable:", self.engine_text)
        self.assertNotIn("CubeTrigTable", self.engine_text)

        load_trig = self.engine_text.split("Engine3D_LoadTrig:", 1)[1]
        load_trig = load_trig.split("Engine3D_ProjectCurrentVertex:", 1)[0]

        self.assertGreaterEqual(load_trig.count("LDX     #Engine3D_CosTable"), 2)
        self.assertGreaterEqual(load_trig.count("LDX     #Engine3D_SinTable"), 2)
        self.assertNotIn("ASLB", load_trig)


class Engine3DIntegrationTests(unittest.TestCase):
    def setUp(self):
        self.cube_text = read_text(CUBE_ASM)
        self.makefile_text = read_text(MAKEFILE)

    def test_cube_demo_includes_and_calls_engine(self):
        """Vérifie que la démo cube inclut et appelle le moteur 3D."""
        self.assertIn('INCLUDE "engine3d.asm"', self.cube_text)
        self.assertIn("JSR     Engine3D_ProjectVertices", self.cube_text)
        self.assertNotIn("CubeTrigTable", self.cube_text)

    def test_cube_demo_passes_engine_project_inputs(self):
        """Vérifie que cube.asm passe X, U et A à Engine3D_ProjectVertices."""
        call_pattern = re.compile(
            r"LDX\s+#CubeVertexTable.*?"
            r"LDU\s+#CUBE_PROJECTED_RAM.*?"
            r"LDA\s+#CUBE_VERTEX_COUNT.*?"
            r"JSR\s+Engine3D_ProjectVertices",
            re.S,
        )
        self.assertRegex(self.cube_text, call_pattern)

    def test_cube_demo_uses_engine_angles(self):
        """Vérifie que cube.asm pilote les angles exposés par le moteur."""
        self.assertIn("ENGINE3D_YAW_ANGLE", self.cube_text)
        self.assertIn("ENGINE3D_PITCH_ANGLE", self.cube_text)
        self.assertIn("ENGINE3D_ANGLE_MASK", self.cube_text)

    def test_makefile_exposes_test_target(self):
        """Vérifie que le Makefile expose la target de tests unitaires."""
        self.assertIn("test:", self.makefile_text)
        self.assertIn("python3 tests/test_engine3d.py", self.makefile_text)


class ColoredTestResult(unittest.TextTestResult):
    def getDescription(self, test):
        doc = test.shortDescription() or "Sans description"
        return f"{test.__class__.__name__}.{test._testMethodName}: {doc}"

    def startTest(self, test):
        super().startTest(test)
        self.stream.writeln(color("RUN ", Ansi.BLUE) + self.getDescription(test))

    def addSuccess(self, test):
        super().addSuccess(test)
        self.stream.writeln("  " + color("OK", Ansi.GREEN))

    def addFailure(self, test, err):
        super().addFailure(test, err)
        self.stream.writeln("  " + color("FAIL", Ansi.RED))

    def addError(self, test, err):
        super().addError(test, err)
        self.stream.writeln("  " + color("ERROR", Ansi.RED))

    def addSkip(self, test, reason):
        super().addSkip(test, reason)
        self.stream.writeln("  " + color(f"SKIP: {reason}", Ansi.YELLOW))


class ColoredTestRunner(unittest.TextTestRunner):
    resultclass = ColoredTestResult

    def run(self, test):
        self.stream.writeln(color("Engine3D unit tests", Ansi.BOLD))
        self.stream.writeln(color("=" * 19, Ansi.CYAN))
        result = super().run(test)
        status = "OK" if result.wasSuccessful() else "FAILED"
        status_color = Ansi.GREEN if result.wasSuccessful() else Ansi.RED
        self.stream.writeln(color(f"Result: {status}", status_color))
        return result


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromModule(sys.modules[__name__])
    runner = ColoredTestRunner(verbosity=0)
    test_result = runner.run(suite)
    raise SystemExit(0 if test_result.wasSuccessful() else 1)
