# 6809 Assembly Style

Use this style guide together with `AGENTS.md`.

## Syntax

- Use LWASM-compatible Motorola 6809 syntax.
- Keep code compatible with real Vectrex hardware.
- Prefer simple, maintainable instruction sequences over obscure cycle tricks.
- Comment any intentional timing or size optimization.

## Naming

- Labels: `PascalCase`
- Constants: `UPPER_CASE`
- Macros: `snake_case`

Examples:

```asm
FRAME_INTENSITY  EQU $5F

MainLoop:
        JSR     Wait_Recal      ; BIOS: synchronize display frame.
```

## Comments

Comments are expected for:

- BIOS calls
- VIA, PSG, or other hardware register access
- Timing-sensitive code
- Vector coordinate calculations
- Non-trivial optimizations

Keep comments useful. Explain intent, hardware constraints, register usage, or
timing assumptions rather than restating the instruction.

## BIOS Usage

Prefer:

```asm
        JSR     Wait_Recal      ; BIOS: recalibrate the display each frame.
```

Avoid:

```asm
        JSR     $F192           ; Hardcoded BIOS address.
```

Search the project includes before introducing new BIOS constants.

## Data Layout

- Name vector lists and tables clearly.
- Document coordinate order when a table uses packed `Y,X` bytes.
- Document terminators such as `$01` or `$FF` according to the BIOS routine
  being used.
