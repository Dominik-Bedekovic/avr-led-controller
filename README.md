# ATmega16A LED Controller

An educational AVR assembly prototype combining LED patterns, external interrupts, timers, button handling, and PWM brightness control. Developed from concepts in university AVR lab material.

## Features

- Three patterns on eight LEDs: blink, running light, and filling bar.
- A fourth mode fades a separate PWM LED.
- Buttons select the mode, pause animation, change speed, and adjust brightness.
- Timer-driven updates, without blocking delay loops inside interrupts.

## Hardware

An **ATmega16A** with an actual **7.3728 MHz clock**, eight active-low LEDs on PA0–PA7, one separate active-low PWM LED on PD7, and four buttons connected to ground. Each LED needs its own current-limiting resistor.

See [wiring and controls](docs/wiring.md) before connecting or programming a board. Existing development boards may have different LED polarity, wiring, and clock settings.

## Build

Install Python 3 and AVRA, then run from this folder:

```sh
python tools/build.py
```

On systems where Python 3 is named `python3`, use that command instead. If AVRA cannot find its device definitions:

```sh
python tools/build.py --include /path/to/avra/includes
```

The include directory must contain `m16def.inc`. You can also pass `--assembler /path/to/avra`.

The output is **`build/main.hex`**. Flash this file using an AVR programmer and software configured for your ATmega16A and programmer. Building does not flash the board. This firmware runs on the microcontroller, not as a desktop Python application; Python only invokes the assembler.

Do not copy unknown clock fuse settings. Confirm your board's oscillator and clock configuration first. The source assumes 7.3728 MHz; changing `F_CPU` changes timer calculations, not the physical clock or fuses. Other frequencies may require timer and PWM adjustments.

## Project files

- `firmware/main.asm` — complete firmware and interrupt handlers.
- `tools/build.py` — small AVRA build helper.
- `docs/wiring.md` — connections and button controls.
- `docs/design.md` — implementation, validation, and provenance notes.

## Provenance and licensing

This project combines concepts from the supplied Lab04, Lab05, and L06 AVR exercises. The original solution archives are not included, and their authorship and redistribution permissions have not been established. Project integration and documentation were created with AI assistance.

No open-source license has been selected for this repository. Public visibility alone does not grant general permission to reuse the code. Confirm ownership and choose a license before presenting it as an open-source project.
