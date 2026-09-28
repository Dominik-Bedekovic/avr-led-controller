# Wiring and controls

These are MCU port names, not development-board connector numbers. Consult the schematic for your exact board and package.

| MCU pin / port | Connection | Function |
| --- | --- | --- |
| PA0–PA7 | Individual LEDs from VCC through a resistor and LED to each pin | Active-low pattern display |
| PD7 / OC2 | Separate LED from VCC through a resistor and LED to the pin | Active-low PWM brightness |
| PD2 / INT0 | Pushbutton to GND | Next mode |
| PD3 / INT1 | Pushbutton to GND | Pause/resume animation |
| PB0 | Pushbutton to GND | Cycle update interval: 200 → 100 → 50 ms |
| PB1 | Pushbutton to GND | Increase PWM brightness in steps; wrap to off |

Buttons use internal pull-ups. All components share ground. An LED's anode faces VCC and its cathode faces the MCU pin. Select resistor values for the supply and LED forward voltage, keeping per-pin and total port currents within the datasheet limits. Do not connect LEDs directly without resistors.

Connect VCC, AVCC, and all GND pins correctly; PORTA requires AVCC even when the ADC is unused. Provide appropriate decoupling, reset wiring, and an ISP header or the board's existing programming interface. Check the board schematic before attaching external circuitry to occupied pins.

Mode order is **blink → running light → filling bar → fade → blink**. Startup selects blink, the slow interval, and approximately half brightness on the separate PWM LED. First pattern output occurs after 200 ms.

In fade mode, the eight pattern LEDs retain their last output and PD7 fades. In the other modes PD7 holds its brightness. Pause freezes automatic pattern/fade updates; the mode, speed, and manual brightness buttons still work. Mode changes reset pattern state and take effect at the next scheduled update after resuming.

INT0/INT1 accept the first falling edge and ignore further presses until the input has been released for three 10 ms samples. PB0/PB1 require three matching samples. Actual switch bounce behavior still needs hardware testing.

Reference: [Microchip ATmega16A datasheet](https://ww1.microchip.com/downloads/en/DeviceDoc/Atmel-8154-8-bit-AVR-ATmega16A_Datasheet.pdf).
