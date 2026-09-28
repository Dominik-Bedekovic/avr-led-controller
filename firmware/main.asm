; ATmega16A LED Controller — integrated adaptation of AVR lab concepts.
; AVRA / AVRASM syntax. Clock must actually be 7.3728 MHz.
.include "m16def.inc"
.equ F_CPU = 7372800
.equ TICK_TOP = F_CPU / 64 / 100 - 1
.def tmp = r16
.def sample = r17
.def changed = r18
.def scratch = r19
.def mode = r20
.def paused = r21
.def pattern = r22
.def ticks = r23
.def events = r24
.def interval = r25
; X/Y/Z pointer registers are intentionally used as state; no indirect access.
.def brightness = r26
.def direction = r27
.def lock0 = r28
.def lock1 = r29
.def lastButtons = r30
.def buttonTicks = r31

.cseg
.org 0
    jmp reset
.org INT0addr
    jmp modeInterrupt
.org INT1addr
    jmp pauseInterrupt
.org OC1Aaddr
    jmp timerTick
; Reserve the complete ATmega16 interrupt table, including unused vectors.
.org INT_VECTORS_SIZE
reset:
    cli
    ldi tmp, high(RAMEND)
    out SPH, tmp
    ldi tmp, low(RAMEND)
    out SPL, tmp
    clr mode
    clr paused
    clr ticks
    clr events
    clr direction
    clr lock0
    clr lock1
    clr buttonTicks
    ldi pattern, 0
    ldi interval, 20
    ldi brightness, 128
    ldi tmp, 3
    sts candidate, tmp
    ldi lastButtons, 3

    ; Eight active-low LEDs: VCC -> resistor -> LED -> PAx.
    ldi tmp, 255
    out PORTA, tmp
    out DDRA, tmp
    ; PB0/PB1 buttons to GND, with internal pull-ups.
    clr tmp
    out DDRB, tmp
    ldi tmp, 3
    out PORTB, tmp
    ; PD2/PD3 buttons; PD7 is a separate active-low PWM LED.
    ldi tmp, (1 << PD2) | (1 << PD3) | (1 << PD7)
    out PORTD, tmp
    ldi tmp, (1 << PD7)
    out DDRD, tmp

    ; Timer2 phase-correct inverted PWM: true off/on at OCR2 = 0/255.
    out OCR2, brightness
    ldi tmp, (1 << WGM20) | (1 << COM21) | (1 << COM20) | (1 << CS22)
    out TCCR2, tmp

    ; Timer1 CTC, prescaler 64: exactly 100 compare events/s at F_CPU.
    clr tmp
    out TCCR1A, tmp
    out TCNT1H, tmp
    out TCNT1L, tmp
    ldi tmp, high(TICK_TOP)
    out OCR1AH, tmp
    ldi tmp, low(TICK_TOP)
    out OCR1AL, tmp
    ldi tmp, (1 << WGM12) | (1 << CS11) | (1 << CS10)
    out TCCR1B, tmp
    ldi tmp, (1 << OCIE1A)
    out TIMSK, tmp
    ldi tmp, (1 << ISC01) | (1 << ISC11)
    out MCUCR, tmp
    ldi tmp, (1 << INTF0) | (1 << INTF1)
    out GIFR, tmp
    ldi tmp, (1 << INT0) | (1 << INT1)
    out GICR, tmp
    sei
main:
    rjmp main

; External ISRs queue events and mask their input until it has been
; released for three timer ticks. No busy-wait delay inside an ISR.
modeInterrupt:
    push tmp
    in tmp, SREG
    push tmp
    ori events, 1
    ldi lock0, 3
    in tmp, GICR
    andi tmp, 255-(1 << INT0)
    out GICR, tmp
    pop tmp
    out SREG, tmp
    pop tmp
    reti
pauseInterrupt:
    push tmp
    in tmp, SREG
    push tmp
    ori events, 2
    ldi lock1, 3
    in tmp, GICR
    andi tmp, 255-(1 << INT1)
    out GICR, tmp
    pop tmp
    out SREG, tmp
    pop tmp
    reti

timerTick:
    push tmp
    in tmp, SREG
    push tmp
    push sample
    push changed
    push scratch
    rcall releaseButtons
    rcall pollButtons
    sbrs events, 0
    rjmp checkPause
    inc mode
    cpi mode, 4
    brlo modeReady
    clr mode
modeReady:
    clr pattern
patternReady:
    clr ticks
    clr direction
checkPause:
    sbrs events, 1
    rjmp eventsDone
    ldi tmp, 1
    eor paused, tmp
eventsDone:
    clr events
    tst paused
    brne tickEnd
    inc ticks
    cp ticks, interval
    brlo tickEnd
    clr ticks
    cpi mode, 0
    breq blink
    cpi mode, 1
    breq chase
    cpi mode, 2
    breq fill
    rjmp fade
blink:
    com pattern
    rjmp showPattern
chase:
    lsl pattern
    brne showPattern
    ldi pattern, 1
    rjmp showPattern
fill:
    lsl pattern
    ori pattern, 1
    cpi pattern, 255
    brne showPattern
    ; Display full bar once; next update starts again at one LED.
    clr pattern
    ldi tmp, 0
    out PORTA, tmp
    rjmp tickEnd
fade:
    tst direction
    brne fadeDown
    cpi brightness, 247
    brsh fadeTop
    subi brightness, -8
    rjmp showBrightness
fadeTop:
    ldi brightness, 255
    ldi direction, 1
    rjmp showBrightness
fadeDown:
    cpi brightness, 8
    brlo fadeBottom
    subi brightness, 8
    rjmp showBrightness
fadeBottom:
    clr brightness
    clr direction
showBrightness:
    out OCR2, brightness
    rjmp tickEnd
showPattern:
    mov tmp, pattern
    com tmp
    out PORTA, tmp
tickEnd:
    pop scratch
    pop changed
    pop sample
    pop tmp
    out SREG, tmp
    pop tmp
    reti

releaseButtons:
    tst lock0
    breq release1
    sbis PIND, PD2
    ldi lock0, 4
    dec lock0
    brne release1
    ldi tmp, (1 << INTF0)
    out GIFR, tmp
    in tmp, GICR
    ori tmp, (1 << INT0)
    out GICR, tmp
release1:
    tst lock1
    breq releaseDone
    sbis PIND, PD3
    ldi lock1, 4
    dec lock1
    brne releaseDone
    ldi tmp, (1 << INTF1)
    out GIFR, tmp
    in tmp, GICR
    ori tmp, (1 << INT1)
    out GICR, tmp
releaseDone:
    ret

; Require three matching samples before accepting a PB0/PB1 transition.
; Candidate lives in SRAM; stable value lives in lastButtons.
pollButtons:
    in sample, PINB
    andi sample, 3
    lds tmp, candidate
    cp tmp, sample
    breq sameSample
    sts candidate, sample
    ldi buttonTicks, 1
    ret
sameSample:
    cpi buttonTicks, 3
    brsh buttonsDone
    inc buttonTicks
    cpi buttonTicks, 3
    brne buttonsDone
    mov changed, sample
    com changed
    and changed, lastButtons
    mov lastButtons, sample
    sbrs changed, 0
    rjmp checkBrightness
    ; Animation intervals: 20 -> 10 -> 5 -> 20 ticks.
    cpi interval, 5
    breq slowSpeed
    lsr interval
    rjmp checkBrightness
slowSpeed:
    ldi interval, 20
checkBrightness:
    sbrs changed, 1
    rjmp buttonsDone
    ; Manual brightness: steps of 32, wrapping after the top range.
    cpi brightness, 224
    brsh brightnessWrap
    subi brightness, -32
    rjmp brightnessWrite
brightnessWrap:
    clr brightness
brightnessWrite:
    out OCR2, brightness
buttonsDone:
    ret

.dseg
candidate: .byte 1
