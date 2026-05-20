# AI Context: Vectrex 6809 Development

This repository contains Vectrex demos written in Motorola 6809 assembly.

`AGENTS.md` is the source of truth for AI assistants. Use it before generating
or modifying code.

## Target

- Original Vectrex console
- Original Vectrex BIOS ROM
- Real hardware compatibility

## Toolchain

- `lwasm`
- `lwlink`
- `make`
- MAME, RetroArch with VecX, or jsvecx for emulation

## Project Rules

- Use LWASM-compatible Motorola 6809 assembly.
- Prefer official Vectrex BIOS symbols.
- Avoid hardcoded BIOS addresses.
- Reuse existing includes from `include/`.
- Keep generated code compact, readable, and commented.
- Preserve public labels and local style when editing existing code.

## Common Commands

```bash
make all
make clean
make run_mame
make run_retroarch
make run_jsvecx
```

## Useful References

- `AGENTS.md`
- `README.md`
- `docs/6809_STYLE.md`
- `docs/VECTREX_BIOS_SYMBOLS.md`
- `docs/PROMPTS.md`
