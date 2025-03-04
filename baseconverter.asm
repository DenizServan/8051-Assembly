ORG 0H
        MOV SP, #60H
        ACALL CONFIGURE_LCD

        MOV R0, #30H            ;this is where input is stored
        MOV R1, #40H            ; this is base storage
        MOV R6, #0H             ; Digit counter (initially 0) also we use r7 
        MOV R2, #20H            ; this is result storage


COLLECT_BASE:
        ACALL KEYBOARD
        CJNE A, #'2', BASE4
        MOV @R1, #2
        SJMP COLLECT_NUMBER
BASE4:
        CJNE A, #'4', BASE8
        MOV @R1, #4
        SJMP COLLECT_NUMBER
BASE8:
        CJNE A, #'8', COLLECT_BASE ; Loops until 2 or 4 or 8 is pressed
        MOV @R1, #8


COLLECT_NUMBER:
        ACALL KEYBOARD
        CJNE A, #'#', STORE_DIGIT
        SJMP PROCESS_CONVERSION  ; Exits when '#' pressed

STORE_DIGIT:
        CLR C	;clearing the carry flag
        SUBB A, #'0'            ; convert ascii to integer by 33h-30h
        MOV @R0, A              ; Storing
        INC R0
        INC R6                  ;digit counter
        SJMP COLLECT_NUMBER


PROCESS_CONVERSION:
        ACALL BASE_CONVERT
        ACALL LCD_OUTPUT
HALT:
        SJMP HALT               ; this allows to loop itself and freeze

; initial subroutines;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CONFIGURE_LCD:	;THIS SUBROUTINE SENDS THE INITIALIZATION COMMANDS TO THE LCD
	mov a,#38H	;TWO LINES, 5X7 MATRIX
	acall SEND_COMMAND
	mov a,#0FH	;DISPLAY ON, CURSOR BLINKING
	acall SEND_COMMAND
	mov a,#06H	;INCREMENT CURSOR (SHIFT CURSOR TO RIGHT)
	acall SEND_COMMAND
	mov a,#01H	;CLEAR DISPLAY SCREEN
	acall SEND_COMMAND
	mov a,#80H	;FORCE CURSOR TO BEGINNING OF THE FIRST LINE
	acall SEND_COMMAND
	ret



SEND_COMMAND:
	mov p1,a		;THE COMMAND IS STORED IN A, SEND IT TO LCD
	clr p3.5		;RS=0 BEFORE SENDING COMMAND
	clr p3.6		;R/W=0 TO WRITE
	setb p3.7	;SEND A HIGH TO LOW SIGNAL TO ENABLE PIN
	acall DELAY
	clr p3.7
	ret


SEND_DATA:
	mov p1,a		;SEND THE DATA STORED IN A TO LCD
	setb p3.5	;RS=1 BEFORE SENDING DATA
	clr p3.6		;R/W=0 TO WRITE
	setb p3.7	;SEND A HIGH TO LOW SIGNAL TO ENABLE PIN
	acall DELAY
	clr p3.7
	ret


DELAY:
	push 0
	push 1
	mov r0,#50
DELAY_OUTER_LOOP:
	mov r1,#255
	djnz r1,$
	djnz r0,DELAY_OUTER_LOOP
	pop 1
	pop 0
	ret


KEYBOARD: ;takes the key pressed from the keyboard and puts it to A
	mov	P0, #0ffh	;makes P0 input
K1:
	mov	P2, #0	;ground all rows
	mov	A, P0 
	anl	A, #00001111B ;and gate 
	cjne	A, #00001111B, K1 ;compare and jump if not equal
K2:
	acall	DELAY
	mov	A, P0
	anl	A, #00001111B
	cjne	A, #00001111B, KB_OVER
	sjmp	K2 ;short jump
KB_OVER:
	acall DELAY
	mov	A, P0
	anl	A, #00001111B
	cjne	A, #00001111B, KB_OVER1
	sjmp	K2
KB_OVER1:
	mov	P2, #11111110B
	mov	A, P0
	anl	A, #00001111B
	cjne	A, #00001111B, ROW_0
	mov	P2, #11111101B
	mov	A, P0
	anl	A, #00001111B
	cjne	A, #00001111B, ROW_1
	mov	P2, #11111011B
	mov	A, P0
	anl	A, #00001111B
	cjne	A, #00001111B, ROW_2
	mov	P2, #11110111B
	mov	A, P0
	anl	A, #00001111B
	cjne	A, #00001111B, ROW_3
	ljmp	K2
	
ROW_0:
	mov	DPTR, #KCODE0
	sjmp	KB_FIND
ROW_1:
	mov	DPTR, #KCODE1
	sjmp	KB_FIND
ROW_2:
	mov	DPTR, #KCODE2
	sjmp	KB_FIND
ROW_3:
	mov	DPTR, #KCODE3
KB_FIND:
	rrc	A
	jnc	KB_MATCH
	inc	DPTR
	sjmp	KB_FIND
KB_MATCH:
	clr	A
	movc	A, @A+DPTR; get ASCII code from the table 
	ret

;ASCII look-up table
KCODE0:	DB	'1', '2', '3', 'A'
KCODE1:	DB	'4', '5', '6', 'B'
KCODE2:	DB	'7', '8', '9', 'C'
KCODE3:	DB	'*', '0', '#', 'D'
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; i wrote below for displaying strings;;;;;;;;;;;;;;;;;;;
NUMBER_TXT: DB 'NUM=' , 0
BASE_TXT:   DB 'BASE=', 0
RESULT_TXT: DB 'RES=', 0


BASE_CONVERT:
       
   
        MOV R0, #40H
        MOV A, @R0
        MOV R7, A
    
    ; Convert input digits (at 30H) to decimal number in R3
        MOV R0, #30H
        MOV R3, #0
        MOV A, R6
        JZ end_convert   ; if no digits, skip
        MOV R5, A
    
build_decimal:
        MOV A, R3
        MOV B, #10
        MUL AB           ; Multiply by 10
        MOV R3, A
        MOV A, @R0
        ADD A, R3
        MOV R3, A        ; Update total
        INC R0
        DJNZ R5, build_decimal
    
    ; Convert decimal (R3) to target base
	MOV A,R2
	MOV R0,A

     ; Result buffer start (20H)
        MOV R4, #0       ;counter for result
    
divide_loop:
        MOV A, R3
        MOV B, R7
        DIV AB           ; A = quotient, B = remainder
        MOV @R0, B
        INC R0
        INC R4
        MOV R3, A        ; update quotient
        JNZ divide_loop  ; continue if quotient not equal to zero
    
end_convert:
        RET

LCD_OUTPUT:
        MOV A, #01H           ; Clear LCD
        ACALL SEND_COMMAND
    
    ; Line 1: "N="
        MOV DPTR, #NUMBER_TXT
        ACALL DISPLAY_STRING
    
    ; Display input number (from 30H, R6 digits)
        MOV R0, #30H  
	MOV A,R6
	MOV R5,A
               
             
input_loop:
        MOV A, @R0
        ADD A, #'0'          ; integer to ascii transform
        ACALL SEND_DATA
        INC R0
        DJNZ R5, input_loop
    
   
        MOV A, #' '	;spacing
        ACALL SEND_DATA
    
  
        MOV DPTR, #BASE_TXT
        ACALL DISPLAY_STRING
    
    ; Display base (from 40H)
        MOV R0, #40H
        MOV A, @R0
        ADD A, #'0'          ; integer to ascii transform
        ACALL SEND_DATA
    
    
        MOV A, #0C0H          ;line 2
        ACALL SEND_COMMAND
    
    
        MOV DPTR, #RESULT_TXT
        ACALL DISPLAY_STRING
    
    ; Display result reverse order
        MOV A, R2
        ADD A, R4
        DEC A
        MOV R0, A
	MOV A,R4
	MOV R5,A


result_loop:
        MOV A, @R0
        ADD A, #'0'          ; integer to ascii transform
        ACALL SEND_DATA
        DEC R0
        DJNZ R5, result_loop
    
        RET



DISPLAY_STRING:
        CLR A
        MOVC A, @A+DPTR
        JZ ds_done           ; end on null 
        ACALL SEND_DATA
        INC DPTR
        SJMP DISPLAY_STRING
ds_done:
        RET

END
