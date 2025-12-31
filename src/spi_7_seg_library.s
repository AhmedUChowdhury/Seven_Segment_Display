	.data

memory_for_read_str:.string "                 ",0

	.text
	.global spi_init
	.global uart_init
	.global timer_interrupt_init
	.global read_string
	.global output_string
	.global string2int
U0FR: 	.equ 0x18	; UART0 Flag Register

ptr_to_readstr:			.word memory_for_read_str

li .macro reg, data
    mov  reg, #(data & 0x0000FFFF)
    movt reg, #((data & 0xFFFF0000) >> 16)
    .endm

spi_init:
	PUSH {r4-r12,lr}
	;---------------------
	; GPIO INITIALIZATION
	;---------------------
	li r4, 0x400FE000
	LDR r0, [r4, #0x608]
	ORR r0, r0, #0x06
	STR r0, [r4, #0x608] ;RCGCGPIO Enable for Port B & C

	NOP
	NOP
	NOP
	NOP
	NOP
	NOP

	li r4, 0x40005000
	LDR r0, [r4, #0x51C]
	ORR r0, r0, #0x90
	STR r0, [r4, #0x51C];Digital enable for Port B for Pins 4 & 7

	LDR r0, [r4, #0x400]
	ORR r0, r0, #0x90
	STR r0, [r4, #0x400];Direction (Input/Output) for Port B for Pins 4 & 7

	LDR r0, [r4, #0x420]
	ORR r0, r0, #0x90
	STR r0, [r4, #0x420];AFSEL for Port B for Pins 4 & 7

	LDR r0, [r4, #0x52C]
	ORR r0, r0, #(0x2 << 28)
	ORR r0, r0, #(0x2 << 16)
	STR r0, [r4, #0x52C];AFSEL for Port B for Pins 4 & 7

	li r4, 0x40006000
	LDR r0, [r4, #0x51C]
	ORR r0, r0, #0x80
	STR r0, [r4, #0x51C];Digital enable for Port C for Pin 7

	LDR r0, [r4, #0x400]
	ORR r0, r0, #0x80
	STR r0, [r4, #0x400];Direction (Input/Output) for Port C for Pins 7

	;---------------------
	; SSI INITIALIZATION
	;---------------------

	li r4, 0x400FE000
	LDR r0, [r4, #0x61C]
	ORR r0, r0, #0x4
	STR r0, [r4, #0x61C]; Enabling SSI2 in RCGCSSI

	NOP
	NOP
	NOP
	NOP
	NOP
	NOP

	li r4, 0x4000A000
	LDR r0, [r4, #0x004]
	BIC r0, r0, #0x6
	STR r0, [r4, #0x004] ;Enabling MS & disabling SSI using SSICR1

	LDR r0, [r4, #0xFC8]
	BIC r0, r0, #0xF
	STR r0, [r4, #0xFC8] ;Setting 0 to use sysclk

	LDR r0, [r4, #0x010]
	ORR r0, r0, #0x4
	STR r0, [r4, #0x010] ;Setting 4 for a sysclk divide by 4

	LDR r0, [r4, #0x000]
	ORR r0, r0, #0xF
	STR r0, [r4, #0x000] ;Setting a 16-bit data size

	LDR r0, [r4, #0x004]
	ORR r0, r0, #0x3
	STR r0, [r4, #0x004] ;Enabling LBM & SSI using SSICR1

	POP {r4-r12,lr}
	MOV pc, lr

uart_init:
	;-----------------------------
	;Initializes the user UART for use
	;_____________________________
	PUSH {r4-r12,lr}	; Spill registers to stack

          ; Your code is placed here
	MOV r4, #0xE000
	MOVT r4, #0x400F
	LDR r5, [r4, #0x618] ;Provide clock to UART0
	ORR r5, r5, #1
	STR r5, [r4, #0x618]

	LDR r5, [r4, #0x608] ;Enable clock to PortA
	ORR r5, r5, #1
	STR r5, [r4, #0x608]

	MOV r4, #0xC000 ;Disable UART0 Control
	MOVT r4, #0x4000
	LDR r5, [r4, #0x30]
	AND r5, r5, #0
	STR r5, [r4, #0x30]

	 ;Set UART0_IBRD_R for 115,200 baud
	LDR r5, [r4, #0x24]
	ORR r5, r5, #8
	STR r5, [r4, #0x24]

	;Set UART0_FBRD_R for 115,200 baud
	LDR r5, [r4, #0x28]
	ORR r5, r5, #44
	STR r5, [r4, #0x28]

	;Use System Clock
	LDR r5, [r4, #0xFC8]
	AND r5, r5, #0
	STR r5, [r4, #0xFC8]

	;Use 8-bit word length, 1 stop bit, no parity
	LDR r5, [r4, #0x2C]
	ORR r5, r5, #0x60
	STR r5, [r4, #0x2C]

	;Enable UART0 Control
	LDR r5, [r4, #0x30]
	MOV r7, #0x301
	ORR r5, r5, r7
	STR r5, [r4, #0x30]

	MOV r4, #0x4000 ;Make PA0 and PA1 as Digital Ports
	MOVT r4, #0x4000
	LDR r5, [r4, #0x51C]
	ORR r5, r5, #0x03
	STR r5, [r4, #0x51C]

	LDR r5, [r4, #0x420] ;Change PA0,PA1 to Use an Alternate Function
	ORR r5, r5, #0x03
	STR r5, [r4, #0x420]

	LDR r5, [r4, #0x52C] ;Configure PA0 and PA1 for UART
	ORR r5, r5, #0x11
	STR r5, [r4, #0x52C]

	POP {r4-r12,lr}  	; Restore registers from stack
	MOV pc, lr

timer_interrupt_init:
	PUSH {r4-r12, lr}
	MOV r0, #0xE000
	MOVT r0, #0x400F

	LDRB r1, [r0, #0x604]
	ORR r1, r1, #0x1
	STRB r1, [r0, #0x604]

	MOV r0, #0x0000
	MOVT r0, #0x4003

	LDRB r1, [r0, #0x00C]
	BIC r1, r1, #0x1
	STRB r1, [r0, #0x00C]

	LDRB r1, [r0, #0x000]
	MOV r5, #0x7
	BIC r1, r1, r5
	STRB r1, [r0, #0x000]

	LDRB r1, [r0, #0x004]
	ORR r1, r1, #0x2
	STRB r1, [r0, #0x004]

	li r1, 0xFFFF
	STR r1, [r0, #0x028]

	LDRB r1, [r0, #0x018]
	ORR r1, r1, #0x1
	STRB r1, [r0, #0x018]

	MOV r0, #0xE000
	MOVT r0, #0xE000

	LDR r1, [r0, #0x100]
	MOV r2, #0x0000
	MOVT r2, #0x0008
	ORR r1, r1, r2
	STR r1, [r0, #0x100]

	MOV r0, #0x0000
	MOVT r0, #0x4003

	LDRB r1, [r0, #0x00C]
	ORR r1, r1, #0x1
	STRB r1, [r0, #0x00C]

	POP {r4-r12, lr}
	MOV pc, lr

output_character:
	;---------------------------------------------------------------------------
	;Transmits a character passed into the routine in r0 to PuTTy via the UART.
	;___________________________________________________________________________
	PUSH {r4-r12,lr}	; Spill registers to stack

	MOV r5, #0xC000
	MOVT r5, #0x4000

load_r1: LDRB r1, [r5, #U0FR]
	MOV r3, #32 ; this is so we can do the masking on bit #5,
	MOV r4, #0
	AND r4, r1, r3	;AND r1 and r3 and store result in r4, if r4 is 32 that means
					; mask bit(bit #5)is 1 and not 0, if it is 0 that means r4 = 0 and we are good to write

	CMP r4, #32
	BEQ load_r1 ; redo loop until mask bit is 0

	STRB r0, [r5]

	;0x4000C000 is the base address

          ; Your code is placed here

	POP {r4-r12,lr}  	; Restore registers from stack
	MOV pc, lr

output_string:
    ;-------------------------------------------------------------------------------------------------
    ;Displays a null-terminated string in PuTTy. The base address of the string should be
    ;passed into the routine in r0.
    ;__________________________________________________________________________________________________


    PUSH {r4-r12,lr}    ; Spill registers to stack

          ; Your code is placed here
    MOV r10, r0 ;put r0 in r10 cuz r0 changes with output_character
    MOV r11, #0  ;offset counter
outputting: LDRB r8, [r10, r11]
    CMP r8, #0x00 ;Compare with NULL
    BEQ end_output_string
    MOV r0, r8
    BL output_character
    ADD r11, r11, #1
    B outputting

end_output_string:


    MOV r0, r10 ;put r0 back cuz why not.

    POP {r4-r12,lr}      ; Restore registers from stack
    MOV pc, lr

read_character:
	;---------------------------------------------------------------------------
	;Reads a character from PuTTy via the UART, and returns the character in r0.
	;___________________________________________________________________________
	PUSH {r4-r12,lr}	; Spill registers to stack

	MOV r5, #0xC000
	MOVT r5, #0x4000

read_bro: LDRB r1, [r5, #U0FR]
	MOV r3, #16 ; this is so we can do the masking on bit #4,
	MOV r4, #0
	AND r4, r1, r3	;AND r1 and r3 and store result in r4, if r4 is 16 that means
					; mask bit(bit #4)is 1 and not 0, if it is 0 that means r4 = 0 and we are good to write

	CMP r4, #16
	BEQ read_bro ; redo loop until mask bit is 0

	LDRB r0, [r5]
		; Your code to receive a character obtained from the keyboard
		; in PuTTy is placed here.  The character is returned in r0.

	POP {r4-r12,lr}  	; Restore registers from stack
	MOV pc, lr


read_string:
    ;-------------------------------------------------------------------------------------------------
    ;Reads a string entered in PuTTy and stores it as a null-terminated string in memory.
    ;The user terminates the string by hitting Enter. The base address of the string should be passed
    ;into the routine in r0. The carriage return should NOT be stored in the string.
    ;__________________________________________________________________________________________________

    PUSH {r4-r12,lr}    ; Spill registers to stack

          ; Your code is placed here
    BL free_memory_for_read_str
    MOV r10, r0 ;put r0 in r10 cuz r0 changes with read_character and output_character
    MOV r11, #0
reading:
    BL read_character
    CMP r0, #13 ;Carriage Return
    BEQ end_read_string
    BL output_character


    STRB r0, [r10, r11]
    ADD r11, r11, #1
    B reading

end_read_string:
    MOV r0, #0x0A
    BL output_character
    MOV r0, #0x0D
    BL output_character


    MOV r0, #0x00
    STRB r0, [r10, r11]

    MOV r0, r10 ;put r0 back

    POP {r4-r12,lr}      ; Restore registers from stack
    MOV pc, lr

free_memory_for_read_str:
    PUSH {r4-r12,lr}

    LDR r0, ptr_to_readstr
    MOV r4, #0
    MOV r5, #17

clear_loop:
    STRB r4, [r0], #1
    SUB r5, r5, #1
    CMP r5, #0
    BNE clear_loop

    POP {r4-r12,lr}
    MOV pc, lr

string2int:
	PUSH {r4-r12,lr} 	; Store any registers in the range of r4 through r12
				; that are used in your routine.  Include lr if this
				; routine calls another routine.

		; Your code for your string2int routine is placed here
	MOV r1, #0
	MOV r8, #0
	MOV r10, #10 ;storing 10 in r10 as we cannot use immediate values for MUL

MainStringInt: LDRB r5, [r0, r1]
	CMP r5, #0x00
	BEQ END ;If NULL END THE PROGRAM
	CMP r5, #44
	BEQ COMMACHECKER ;MAKE SURE TO SKIP THE COMMA

	SUB r2, r5, #0x30 ;r2 has the number we just turned into an int

	ADD r8, r8, r2 	  ;r8 has the total number

	;now we have to check if there is a number after the one we
	; just loaded so we know if we have to multiply r8 by 10
	ADD r1, r1, #1 ;Increment our counter by 1 to see what is ahead
					; so that we can know if we need to multiply r8 by 10

	LDRB r5, [r0, r1]
	CMP r5, #0x00
	BEQ MainStringInt  ;If NULL Dont multiple by 10

	MUL r8, r8, r10
	B MainStringInt

END: MOV r0, r8
	POP {r4-r12,lr}   	; Restore registers all registers preserved in the
				; PUSH at the top of this routine from the stack.
	mov pc, lr


; Additional subroutines may be included here
COMMACHECKER:
	ADD r1, r1, #1
	B MainStringInt

	.end
