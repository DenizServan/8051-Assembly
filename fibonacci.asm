ORG 0H
        MOV SP, #70H
        ACALL CONFIGURE_LCD
        MOV R0, #30H    ; input storage
        MOV R1, #40H    ; input in decimal
        MOV R2, #01H
        MOV R3, #50H    ; low result
        MOV R4, #60H    ; high result
        MOV R5, #00H   
        MOV R6, #00H    ; input digit counter
        MOV R7, #00H    ; fib loop counter

COLLECT_NUMBER:
        ACALL KEYBOARD
        CJNE A, #'#', STORE_DIGIT
        SJMP PROCESS_NUMBER	; Exits when '#' pressed

STORE_DIGIT:
        CLR C
        SUBB A, #'0'
        MOV @R0, A
        INC R0		;this is our pointer, points to our input mem adress
        INC R6		;this is our counter
        SJMP COLLECT_NUMBER

PROCESS_NUMBER:
        MOV 37H, R6
        CJNE R6, #01H, pc2
        SJMP onecase
pc2:
        CJNE R6, #02H, false_input
        SJMP twocase
false_input:
        SJMP COLLECT_NUMBER

onecase:
        DEC R0
        MOV A, @R0
        MOV @R1, A
        SJMP fib_calc

twocase:
        DEC R0		
        DEC R0
        MOV A, @R0
        MOV B, A
        MOV A, #10
        MUL AB
        MOV B, A
        INC R0
        MOV A, @R0
        ADD A, B
        MOV @R1, A
        SJMP fib_calc

fib_calc:
        CJNE @R1, #0, n1	;zero case
        MOV 60H, #00H
        MOV 50H, #00H
        SJMP display_result
n1:
        CJNE @R1, #1, n2	;one case
        MOV 60H, #00H
        MOV 50H, #01H
        SJMP display_result
n2:
        CJNE @R1, #2, ns	;two case 
        MOV 60H, #00H
        MOV 50H, #01H		
        SJMP display_result
ns:
        MOV A, @R1	;main calculation starts;;;;;;;;;;;;;;;;;;;;;;;;
        MOV R7, A
        DEC R7
        DEC R7
        MOV R1, #01H
        MOV R2, #00H
        MOV R5, #01H
        MOV R6, #00H
fib_loop:
        MOV A, R1
        ADD A, R5
        MOV R3, A
        MOV A, R2
        ADDC A, R6
        MOV R4, A


;;;;;;;;;;;;shifting section;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
        MOV A, R5
        MOV R1, A
        
        MOV A, R6
        MOV R2, A
        
        MOV A, R4
        MOV R6, A

        
        MOV A, R3
        MOV R5, A
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,
        
        DJNZ R7, fib_loop	;storing values to the mem adress
        MOV 60H, R4
        MOV 50H, R3
        SJMP display_result


DISPLAY_RESULT:
        ACALL HEX_TO_DEC_INPUT  ; input digits to 20H
        ACALL BASE_CONVERT      ; fib digits to 26H
        ACALL LCD_OUTPUT
        sjmp END_PROG

END_PROG:
        SJMP END_PROG

BASE_CONVERT:
        PUSH 0
        PUSH 1
        PUSH 4
        PUSH 5
        MOV R0, #2BH    ; end of buffer
        MOV R1, #0      ; digit counter
        MOV R2, 60H     ; high byte
        MOV R3, 50H     ; low byte
        
divide_loop:
        
;;;;;;;;;;;;;;  Quotient in R2R3, remainder in B ;;;;;;;;;;;;;;;
        MOV R4, #0      ; Remainder high
        MOV R5, #0      ; Remainder low
        MOV R7, #16     ; 16-bit counter
div_bit_loop:
        ; Shift left dividend and remainder
        CLR C
        MOV A, R3
        RLC A
        MOV R3, A
        MOV A, R2
        RLC A
        MOV R2, A
        MOV A, R5
        RLC A
        MOV R5, A
        MOV A, R4
        RLC A
        MOV R4, A
        
        ; Subtract 10 from remainder
        CLR C
        MOV A, R5
        SUBB A, #10
        MOV R6, A       ; temporary low
        MOV A, R4
        SUBB A, #0
        JC skip_sub     ; if remainder less then 10
        
;;;;;;;;;;;;;;;;;;; Update remainder and set quotient bit
        MOV R4, A
        MOV A,R6
        MOV R5,A
        
        INC R3          ; set LSB of the quotient number value 
skip_sub:
        DJNZ R7, div_bit_loop
        
        ; Remainder is in R5 
        MOV B, R5       ; to store
        DEC R0
        MOV @R0, B
        INC R1
        
;;;;;;;;;;;;;; ; checking if quotient  is zero
        MOV A, R2
        ORL A, R3
        JNZ divide_loop
        
        MOV 31H, R1     ; Store digit count
        MOV 32H, R0     ; Store starting address
        POP 5
        POP 4
        POP 1
        POP 0
        RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;below are initial subroutines ;;;;;;;;;;;;;;;;;;;,        
CONFIGURE_LCD:
        MOV A, #38H
        ACALL SEND_COMMAND
        MOV A, #0FH
        ACALL SEND_COMMAND
        MOV A, #06H
        ACALL SEND_COMMAND
        MOV A, #01H
        ACALL SEND_COMMAND
        MOV A, #80H
        ACALL SEND_COMMAND
        RET

SEND_COMMAND:
        MOV P1, A
        CLR P3.5
        CLR P3.6
        SETB P3.7
        ACALL DELAY
        CLR P3.7
        RET

SEND_DATA:
        MOV P1, A
        SETB P3.5
        CLR P3.6
        SETB P3.7
        ACALL DELAY
        CLR P3.7
        RET

DELAY:
        PUSH 0
        PUSH 1
        MOV R0, #50
DELAY_OUTER_LOOP:
        MOV R1, #255
        DJNZ R1, $
        DJNZ R0, DELAY_OUTER_LOOP
        POP 1
        POP 0
        RET

KEYBOARD:
        MOV P0, #0FFH
K1:
        MOV P2, #0
        MOV A, P0
        ANL A, #00001111B
        CJNE A, #00001111B, K1
K2:
        ACALL DELAY
        MOV A, P0
        ANL A, #00001111B
        CJNE A, #00001111B, KB_OVER
        SJMP K2
KB_OVER:
        ACALL DELAY
        MOV A, P0
        ANL A, #00001111B
        CJNE A, #00001111B, KB_OVER1
        SJMP K2
KB_OVER1:
        MOV P2, #11111110B
        MOV A, P0
        ANL A, #00001111B
        CJNE A, #00001111B, ROW_0
        MOV P2, #11111101B
        MOV A, P0
        ANL A, #00001111B
        CJNE A, #00001111B, ROW_1
        MOV P2, #11111011B
        MOV A, P0
        ANL A, #00001111B
        CJNE A, #00001111B, ROW_2
        MOV P2, #11110111B
        MOV A, P0
        ANL A, #00001111B
        CJNE A, #00001111B, ROW_3
        LJMP K2
ROW_0:
        MOV DPTR, #KCODE0
        SJMP KB_FIND
ROW_1:
        MOV DPTR, #KCODE1
        SJMP KB_FIND
ROW_2:
        MOV DPTR, #KCODE2
        SJMP KB_FIND
ROW_3:
        MOV DPTR, #KCODE3
KB_FIND:
        RRC A
        JNC KB_MATCH
        INC DPTR
        SJMP KB_FIND
KB_MATCH:
        CLR A
        MOVC A, @A+DPTR
        RET

KCODE0: DB '1', '2', '3', 'A'
KCODE1: DB '4', '5', '6', 'B'
KCODE2: DB '7', '8', '9', 'C'
KCODE3: DB '*', '0', '#', 'D'
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NUMBER_TXT: DB 'N=', 0		; i added this part
RESULT_TXT: DB 'FIB(n)=', 0


LCD_OUTPUT:
        MOV A, #01H
        ACALL SEND_COMMAND	;clear lcd
        MOV DPTR, #NUMBER_TXT
        ACALL DISPLAY_STRING
        MOV R0, #20H
        MOV R6, 30H
input_dec_loop:		;this loops reads and writes the input decimal onto the lcd ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        MOV A, @R0
        ADD A, #'0'
        ACALL SEND_DATA
        INC R0
        DJNZ R6, input_dec_loop
        MOV A, #0C0H
        ACALL SEND_COMMAND
        MOV DPTR, #RESULT_TXT
        ACALL DISPLAY_STRING
        MOV R0, 32H    
        MOV R6, 31H     ; Digit count
fib_dec_loop:			; this loop is for the result of the calculated fib value;;;;;;;;;;;;;;;;;;;
        MOV A, @R0
        ADD A, #'0'
        ACALL SEND_DATA
        INC R0
        DJNZ R6, fib_dec_loop
        RET

HEX_TO_DEC_INPUT:		
        PUSH 0			;save r0 and r1 to stack , this is to preserve registers we will pop them at the end
        PUSH 1
        MOV R0, #20H
        MOV R7, #0	;reset digit counter
        MOV R3, 40H     
DIGIT_LOOP_INPUT:
        MOV A, R3	;load
        MOV B, #10
        DIV AB
        MOV @R0, B
        INC R0
        INC R7
        MOV R3, A
        JNZ DIGIT_LOOP_INPUT	;loops until the quotient is zero , all the digits are found when its zero
        ; Reverse digits
        MOV A, R7		; loads digit count to r2
        MOV R2, A
        MOV R1, #20H
        MOV A, R0
        DEC A
        MOV R0, A
REVERSE_LOOP:
        MOV A, R1
        CLR C
        SUBB A, R0	;if r1>r0 stop reversing
        JNC REVERSE_DONE
        MOV A, @R1
        XCH A, @R0	;i learned this from other similar codes, this swaps accumulator with memory adress pointed by r0 register
        MOV @R1, A
        INC R1		;move start pointer forward
        DEC R0		;move end pointer back
        SJMP REVERSE_LOOP
REVERSE_DONE:
        MOV 30H, R2	;save final count 
        POP 1
        POP 0
        RET

DISPLAY_STRING:
        CLR A
        MOVC A, @A+DPTR
        JZ ds_done
        ACALL SEND_DATA
        INC DPTR
        SJMP DISPLAY_STRING
ds_done:
        RET

END
