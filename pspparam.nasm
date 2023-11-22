ORG 0x100

; Set DI to 0
XOR DI, DI
MOV CX, 16

mainloop:
; Print CX bytes of deref DS:DI

; Print the Address
MOV AX, DI
MOV AL, AH
CALL printhex

MOV AX, DI
CALL printhex

MOV AL, ':'
CALL printdirect

MOV AL, ' '
CALL printdirect

; Print the mmopry as hex string
CALL printmemory

MOV AL, ' '
CALL printdirect

; Print the memory as a printable string, 
; nonprintable charas replaced with '.'
CALL printprintable
CALL printnewline
ADD DI, CX

; Do it until last byte of PSP (0xFF)
CMP DI, 0x100
JL mainloop

; exit
MOV AH, 0x4C
INT 0x21

;;;;;;;;;;;;;;;; printnewline
printnewline:
PUSH AX
PUSH DX

MOV AH, 0x02
MOV DL, 0x0D
INT 0x21
MOV DL, 0x0A
INT 0x21

POP DX
POP AX
RET

;;;;;;;;;;;;;;;; printmemory: Print memory as hex starting from byte DS:DI, size CX
printmemory:
PUSH DI
PUSH AX
PUSH BX
PUSH CX

CMP CX, 0
jz printmemoryend

XOR BX, BX

printmemoryloop:
MOV AL, [DS:DI + BX]
CALL printhex
INC BX
MOV AH, 0x02
MOV DL, ' '
INT 0x21

CMP BX, CX
jl printmemoryloop
printmemoryend:

POP CX
POP BX
POP AX
POP DI

RET

;;;;;;;;;;;;;;;; printprintable: Print memory as hex starting from byte DS:DI, size CX
;;;;;;;;;;;;;;;; print byte if printable, otherwise print '.'
;;;;;;;;;;;;;;;; This does not support multibyte charas
;;;;;;;;;;;;;;;; <x20 and >=x80 is printed as '.', otherwise printed _as is_
printprintable:
PUSH DI
PUSH AX
PUSH BX
PUSH CX

CMP CX, 0
jz printprintableend

XOR BX, BX

printprintableloop:
MOV AH, 0

MOV AL, [DS:DI + BX]
CMP AL, 0x20
MOV AL, '.'
JL printprintableprint

MOV AH, 0
MOV AL, [DS:DI + BX]
CMP AX, 0x80
JL printprintableprint

MOV AL, '.'

printprintableprint:
CALL printdirect

INC BX
CMP BX, CX
JL printprintableloop

printprintableend:
POP CX
POP BX
POP AX
POP DI

RET

;;;;;;;;;;;;;;;; printdirect: print byte in AL
printdirect:
PUSH AX
PUSH DX

MOV DL, AL
MOV AH, 0x02
INT 0x21

POP DX
POP AX

RET

;;;;;;;;;;;;;;;; printhex: print hex representation of byte in AL
printhex:
PUSH SI
PUSH DX
PUSH AX

MOV AH, 0
SHR AL, 4
MOV SI, hexenc
ADD SI, AX
MOV DL, [DS:SI]
MOV AH, 0x02
INT 0x21
;Reset AL
POP AX
PUSH AX

; Print low bits
MOV AH, 0
AND AL, 0xF
MOV SI, hexenc
ADD SI, AX
MOV DL, [DS:SI]
MOV AH, 0x02
INT 0x21

POP AX
POP DX
POP SI
RET

section .data

hexenc:
db \
'0', '1', '2', '3', \
'4', '5', '6', '7', \
'8', '9', 'A', 'B', \
'C', 'D', 'E', 'F'
