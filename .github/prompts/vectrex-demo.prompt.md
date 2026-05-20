---
mode: ask
description: Create or extend a Vectrex demo using the project conventions.
---

# Vectrex Demo Prompt

Create or extend a Vectrex demo in Motorola 6809 assembly.

Use `AGENTS.md` as the source of truth.

Requirements:

- Generate LWASM-compatible code.
- Target the original Vectrex BIOS.
- Prefer official BIOS symbols over hardcoded BIOS addresses.
- Use existing includes from `include/` when possible.
- Start the main display loop with `Wait_Recal` unless the requested design
  explicitly needs a different frame structure.
- Keep the code compact, readable, and directly compilable through the
  project `Makefile`.
- Add useful comments for BIOS calls, hardware access, timing-sensitive code,
  vector calculations, and non-trivial optimizations.
- Preserve public labels and existing project style when modifying code.

When answering, include:

- The changed or proposed assembly code.
- Any important register assumptions or clobbered registers.
- The build command to verify the ROM.
