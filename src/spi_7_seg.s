		.data

dsp0:		.byte 0x00
dsp1:		.byte 0x00
dsp2:		.byte 0x00
dsp3:		.byte 0x00
counter:	.byte 0x00 ;based on counter value we change display -0 -> DSP0
						;1 -> DSP1 2-> DSP2 3 -> DSP3

fourth_selection:		.string "Enter 1s value: ", 0xA, 0xD,0
third_selection:		.string "Enter 10s value: ", 0xA, 0xD,0
second_selection:		.string "Enter 100s digit: ", 0xA, 0xD,0
first_selection:		.string "Enter 1000s digit:: ", 0xA, 0xD,0
quit:					.string "Quit(y/n): ", 0xA, 0xD,0
fourth:					.space 256
third:					.space 256
second:					.space 256
first:					.space 256
quitted:				.space 256

	.text
	.global spi_init
	.global spi
	.global uart_init
	.global timer_interrupt_init
	.global read_string
	.global output_string
	.global string2int
	.global Timer_Handler

li .macro reg, data
    mov  reg, #(data & 0x0000FFFF)
    movt reg, #((data & 0xFFFF0000) >> 16)
    .endm

ptr_to_fourth_selection: 		.word fourth_selection
ptr_to_third_selection:			.word third_selection
ptr_to_second_selection:		.word second_selection
ptr_to_first_selection: 		.word first_selection
ptr_to_quit:			 		.word quit
ptr_to_fourth:					.word fourth
ptr_to_third:					.word third
ptr_to_second:					.word second
ptr_to_first:					.word first
ptr_to_quitted:					.word quitted

ptr_to_dsp0:		.word dsp0
ptr_to_dsp1:		.word dsp1
ptr_to_dsp2:		.word dsp2
ptr_to_dsp3:		.word dsp3
ptr_to_counter:		.word counter

spi:
	PUSH {r4-r12,lr}
	bl spi_init
	bl uart_init
	bl timer_interrupt_init

SPI_LOOP:
	LDR r4, ptr_to_fourth_selection
	LDR r5, ptr_to_third_selection
	LDR r6, ptr_to_second_selection
	LDR r7, ptr_to_first_selection

	MOV r0, r4
	BL output_string
	LDR r4, ptr_to_fourth
	MOV r0, r4
	BL read_string
	BL string2int
	LDR r4, ptr_to_dsp0
	STRB r0, [r4]

	MOV r0, r5
	BL output_string
	LDR r5, ptr_to_third
	MOV r0, r5
	BL read_string
	BL string2int
	LDR r5, ptr_to_dsp1
	STRB r0, [r5]

	MOV r0, r6
	BL output_string
	LDR r6, ptr_to_second
	MOV r0, r6
	BL read_string
	BL string2int
	LDR r6, ptr_to_dsp2
	STRB r0, [r6]

	MOV r0, r7
	BL output_string
	LDR r7, ptr_to_first
	MOV r0, r7
	BL read_string
	BL string2int
	LDR r7, ptr_to_dsp3
	STRB r0, [r7]

	LDR r6, ptr_to_quit
	MOV r0, r6
	BL output_string
	LDR r6, ptr_to_quitted
	MOV r0, r6
	BL read_string
	LDRB r0, [r0]
	CMP r0, #0x79
	BNE SPI_LOOP

	POP {r4-r12,lr}
	MOV pc, lr

Timer_Handler:
	PUSH {r4-r12,lr}

	li r4, 0x40030000
	LDRB r5, [r4, #0x024]
	ORR r5, r5, #0x1
	STRB r5, [r4, #0x024]

	LDR r1, ptr_to_counter
	LDRB r0, [r1]
	MOV r2, r0
	CMP r0, #3
	ITE NE
	ADDNE r0, r0, #1
	MOVEQ r0, #0
	STRB r0, [r1]

	CMP r2, #0
	BEQ disp0

	CMP r2, #1
	BEQ disp1

	CMP r2, #2
	BEQ disp2

	CMP r2, #3
	BEQ disp3

end_timer:
	ORR r0, r2, r0, LSL #8

	li r4, 0x400063FC
	LDRB r1, [r4]
	BIC r1, r1, #0x80
	STRB  r1, [r4]

	MOV r1, r0

	li r4, 0x4000A00C
timer_loop1:
	LDRB r0, [r4]
	AND r0, r0, #0x10
	CMP r0, #0x10
	BEQ timer_loop1

	li r4, 0x4000A008
	STRH r1, [r4]

	li r4, 0x4000A00C
timer_loop2:
	LDRB r0, [r4]
	AND r0, r0, #0x10
	CMP r0, #0x10
	BEQ timer_loop2

	li r4, 0x400063FC
	LDRB r1, [r4]
	ORR r1, r1, #0x80
	STRB  r1, [r4]

	POP {r4-r12,lr}
	BX lr

disp0:
	MOV r2, #1
	LDR r4, ptr_to_dsp0
	LDRB r0, [r4]
	BL num_conv
	B end_timer

disp1:
	MOV r2, #2
	LDR r4, ptr_to_dsp1
	LDRB r0, [r4]
	BL num_conv
	B end_timer

disp2:
	MOV r2, #4
	LDR r4, ptr_to_dsp2
	LDRB r0, [r4]
	BL num_conv
	B end_timer

disp3:
	MOV r2, #8
	LDR r4, ptr_to_dsp3
	LDRB r0, [r4]
	BL num_conv
	B end_timer


num_conv:
	PUSH {r4-r12,lr}

	CMP r0, #0
	IT EQ
	MOVEQ r0, #0xC0
	BEQ num_conv_end

	CMP r0, #1
	IT EQ
	MOVEQ r0, #0xF9
	BEQ num_conv_end

	CMP r0, #2
	IT EQ
	MOVEQ r0, #0xA4
	BEQ num_conv_end

	CMP r0, #3
	IT EQ
	MOVEQ r0, #0xB0
	BEQ num_conv_end

	CMP r0, #4
	IT EQ
	MOVEQ r0, #0x99
	BEQ num_conv_end

	CMP r0, #5
	IT EQ
	MOVEQ r0, #0x92
	BEQ num_conv_end

	CMP r0, #6
	IT EQ
	MOVEQ r0, #0x82
	BEQ num_conv_end

	CMP r0, #7
	IT EQ
	MOVEQ r0, #0xF8
	BEQ num_conv_end

	CMP r0, #8
	IT EQ
	MOVEQ r0, #0x80
	BEQ num_conv_end

	CMP r0, #9
	IT EQ
	MOVEQ r0, #0x90

num_conv_end:
	POP {r4-r12,lr}
	MOV pc,lr

    .end
