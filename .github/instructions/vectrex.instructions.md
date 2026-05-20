---
applyTo: "**/*.{asm,inc}"
---

# Vectrex 6809 Instructions

Follow `AGENTS.md` as the source of truth for this project.

When generating or modifying assembly code:

- Use LWASM-compatible Motorola 6809 syntax.
- Prefer official Vectrex BIOS symbols such as `Wait_Recal`, `Intensity_a`,
  `Print_Str_d`, `Moveto_d`, and `Draw_Line_d`.
- Do not hardcode BIOS addresses when a named symbol exists in the project
  includes.
- Reuse existing files from `include/` before creating new symbols or macros.
- Keep labels in `PascalCase`, constants in `UPPER_CASE`, and macros in
  `snake_case`.
- Comment BIOS calls, hardware accesses, timing-sensitive code, vector math,
  and non-trivial optimizations.
- Keep code compact, readable, and compatible with real Vectrex hardware.

Before proposing code, check whether an existing BIOS routine or project macro
already solves the problem.
