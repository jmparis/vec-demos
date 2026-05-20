# Useful AI Prompts

Reusable prompts for Codex, ChatGPT, GitHub Copilot Chat, or other assistants.

## Create A Vectrex Demo

Using the rules in `AGENTS.md`, create a directly compilable Vectrex demo in
LWASM-compatible Motorola 6809 assembly.

The demo must:

- Use the original Vectrex BIOS.
- Prefer BIOS symbols over hardcoded addresses.
- Start the display loop with `Wait_Recal`.
- Set vector intensity through `Intensity_a`.
- Include useful comments for BIOS calls, timing, and vector calculations.
- Build with the project `Makefile`.

## Review Vectrex Assembly

Review this Motorola 6809 assembly code for:

- LWASM compatibility
- Vectrex BIOS usage
- Real hardware compatibility
- Timing risks
- Hardcoded BIOS addresses
- Missing comments around hardware access or vector math
- Register clobbering assumptions

Return concrete findings first, with file and line references when available.

## Refactor Vectrex Assembly

Refactor this Vectrex assembly code while preserving behavior.

Follow `AGENTS.md`.

Goals:

- Keep the code compact and readable.
- Preserve public labels.
- Reuse existing includes and macros.
- Replace hardcoded BIOS addresses with symbols when possible.
- Add comments only where they clarify BIOS behavior, hardware access, timing,
  or vector calculations.

## Add A BIOS Helper

Add a reusable helper or macro for this Vectrex project.

Before adding it:

- Check whether an existing BIOS routine or include already covers the need.
- Keep the helper LWASM-compatible.
- Use `snake_case` for macros.
- Document inputs, outputs, clobbered registers, and timing assumptions.
