# Design and validation

## Implementation

Timer1 runs in CTC mode with a /64 prescaler and OCR1A = 1151. At 7.3728 MHz this produces a 100 Hz scheduler. It debounces buttons, handles queued mode/pause events, and advances animation at the selected interval.

Timer2 drives inverted phase-correct PWM on OC2/PD7, with a /64 prescaler (approximately 226 Hz). The LED is active-low: OCR2 = 0 is off and OCR2 = 255 is on. Fade mode changes OCR2 by up to eight per animation update.

INT0/INT1 queue events and temporarily mask their own interrupt. The timer rearms them after release. Interrupts are not nested. ISRs preserve SREG and temporary registers; dedicated persistent state registers are intentionally modified. The foreground loop does not modify this shared state. X/Y/Z registers hold state rather than pointers.

The assembler's `m16def.inc` supplies the ATmega16 register and vector definitions used by this ATmega16A-targeted firmware; it is supplied by AVRA, not vendored here. Only INT0, INT1, and Timer1 compare A are enabled. Other vector slots are reserved but do not contain handlers; add handlers before enabling further interrupt sources.

## Validation

The supplied source was assembled using AVRA 1.4.2 and its m16def.inc, with no assembly errors. AVRA reports six alias warnings because r26–r31 already have X/Y/Z pointer aliases. Their use as state is intentional. The device include also produces ignored-pragma notices.

Assembly checks syntax and branch/address constraints. It does not establish that a particular board's wiring, clock configuration, timing, or behavior is correct. No physical-board or simulator validation has been performed.

Suggested hardware checks: verify the clock and active-low LEDs, confirm mode order, hold each button to check that it triggers once, check pause/resume and all speed settings, then verify PD7 brightness and fading, including off/on endpoints.

## Relationship to the lab material

| Material | Concepts used |
| --- | --- |
| Lab04 exercises | External interrupts, button input, LED patterns |
| Lab05 exercises | Timer scheduling and CTC timing |
| L06 exercises | PWM brightness and fading |

This project implements a new combined application. It does not reproduce all fifteen exercises or promise drop-in compatibility with their original circuits. In particular, brightness uses a separate LED on Timer2 OC2, leaving Timer1 available for scheduling.

The original archives remain separate because their licensing and authorship are unknown. Do not label them as newly authored work or apply a repository license to them without establishing the necessary rights.
