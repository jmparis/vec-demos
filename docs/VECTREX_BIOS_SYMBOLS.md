# Vectrex BIOS Symbols

Prefer named BIOS symbols from the project includes over hardcoded addresses.

This file is a quick AI-facing reminder. For complete behavior, timings, and
calling conventions, refer to the Vectrex BIOS documentation listed in
`AGENTS.md`.

## Display And Frame

- `Wait_Recal`: wait for frame recalibration and reset the beam reference.
- `Intensity_a`: set vector brightness using the value in register `A`.
- `Reset0Ref`: reset the beam position to the screen origin/reference point.

## Text

- `Print_Str_d`: print a BIOS-format string at the position in `D`.
- `Print_List_hw`: print a list of strings using BIOS text helpers.

## Movement And Vectors

- `Moveto_d`: move the beam by the signed `Y,X` delta in `D`.
- `Draw_Line_d`: draw a line using the signed `Y,X` delta in `D`.
- `Draw_VL_a`: draw a vector list using BIOS vector-list format.
- `Draw_VL_ab`: draw a vector list with scale or count parameters in
  registers, depending on the include definitions and BIOS reference.

## Sound And Input

- Prefer BIOS sound routines when they fit the use case.
- Avoid direct PSG writes unless they are necessary and clearly commented.
- Document any direct VIA or PSG access with the hardware register purpose and
  timing assumptions.

## Reminder For AI Assistants

Before using a numeric BIOS address, search `include/` for an existing symbol.
Use `JSR Wait_Recal` style calls instead of hardcoded `JSR` addresses.
