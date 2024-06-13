ORG 0x100

; Allocate stack for print. Maximum value here is 127
; (max size in PSP) +1 NUL terminator
MOV CX, 128
; Allocate buffers on stack. One 128 byte buffer for the NUL terminated
; string, one for each subparam (ASCII values between spaces (' ') )
SUB SP, 256
; 0D terminated cmdline args begin in PSP at 0x81
MOV SI, 0x81
; DI will grow up into the stack we have pushed down
MOV DI, SP
CALL cutstring0d
; Not going to check for errs; DI should be set to local stack
;CALL printtozero
;CALL printnewline

; Use the next 128 bytes on the stack for each parameter
; Move result DI from cutstring0d to input SI for getbetweenspace
MOV SI, DI
MOV DI, SP
ADD DI, 128
MOV CX, 128

;;; Argument 0
CALL getbetweenspace
JC exit
CALL strtos
JC exit
PUSH DX

;;; Argument 1
CALL getbetweenspace
JC exit
CALL strtos
JC exit
PUSH DX

;;; Argument 2
CALL getbetweenspace
JC exit
CALL strtos
JC exit
PUSH DX
;;;;;

; Segment (Argument 0)
MOV SI, SP
PUSH DS

MOV DS, [SS:SI + 4]

; Offset (Argument 1)
MOV DI, [SS:SI + 2]

; Count (Argument 2)
MOV CX, [SS:SI + 0]

CALL printmemory

;Reset DS
POP DS

; Remove arguments
ADD SP, 6
; clear cut / last argument on stack
ADD SP, 256

exit:
MOV AH, 0x4C
INT 0x21

;;;;;;;;;;;;;;;; getbetweenspace:
;;;;;;;;;;;;;;;; cutstring0d: Cut the string from the next non-space to
;;;;;;;;;;;;;;;; the next space encountered.
;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;; IN:  DS:SI Pointer to ASCII start
;;;;;;;;;;;;;;;; OUT: [DS:DI] Pointer to be written
;;;;;;;;;;;;;;;; IN:  CX Maximum amount of bytes to be written
;;;;;;;;;;;;;;;; OUT: DS:SI Pointer to last byte processed

getbetweenspace:
PUSH AX
PUSH BX
PUSH CX
PUSH DX

CMP CX, 0
JNZ getbetweenspacesetup
; Set Carry flag signaling error
STC
RET

getbetweenspacesetup:
DEC CX
MOV BX, 0
JMP getbetweenspaceloop

getbetweenspaceloopinc:
INC SI

getbetweenspaceloop:
; Scan till first non-space character or NUL
CMP byte [DS:SI], ' '
JZ getbetweenspaceloopinc
; Check for null byte
CMP byte [DS:SI], 0
JZ getbetweenspaceenderr

; SI is sitting at the first character
getbetweenspacenext:
; Scan until the next space or NUL or the buffer is full
CMP BX, CX
JZ getbetweenspaceendok
CMP byte [DS:SI + BX], ' '
JZ getbetweenspaceendok;
CMP byte [DS:SI + BX], 0
JZ getbetweenspaceendok;
MOV DL, [DS:SI + BX]
MOV [DS:DI + BX], DL
INC BX
JMP getbetweenspacenext

getbetweenspaceendok:
; Terminate with NUL
MOV byte [DS:DI + BX], 0
ADD SI, BX
CLC
JMP getbetweenspaceend

getbetweenspaceenderr:
STC
getbetweenspaceend:
POP DX
POP CX
POP BX
POP AX
RET

;;;;;;;;;;;;;;;; cutstring0d: Cut the string to 0D (replace with \0) and
;;;;;;;;;;;;;;;; place in given buffer
;;;;;;;;;;;;;;;; This means the resulting string will be an asciiz string
;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;; IN:  DS:SI Pointer to 0D terminated string
;;;;;;;;;;;;;;;; OUT: DS:DI Pointer to space to be written
;;;;;;;;;;;;;;;; IN:  CX: Maximum bytecount to be written (buffer size)
;;;;;;;;;;;;;;;; err: Carry flag is set (will only happen if CX is 0)
;;;;;;;;;;;;;;;; ok:  Carry flag is not set

cutstring0d:
CMP CX, 0
JNZ cutstring0dsetup
; Set Carry flag signaling error
STC
RET

cutstring0dsetup:
PUSH AX
PUSH BX
PUSH CX

MOV BX, 0
DEC CX

cutstring0dloop:
CMP BX, CX
JZ cutstring0dend

CMP byte [DS:SI + BX], 0x0D
JZ cutstring0dend
MOV AL, [DS:SI + BX]
MOV [DS:DI + BX], AL

INC BX
JMP cutstring0dloop

cutstring0dend:
MOV byte [DS:DI + BX], 0

POP CX
POP BX
POP AX
CLC
RET

;;;;;;;;;;;;;;;; printtozero
;;;;;;;;;;;;;;;; Print DS:DI until NUL terminator
printtozero:
PUSH AX
PUSH DX
PUSH BX

MOV BX, 0

printtozeroloop:
MOV DL, [DS:DI + BX]

CMP DL, 0
jz printtozeroend

MOV AH, 0x02
INT 0x21

INC BX
JMP printtozeroloop

printtozeroend:
POP BX
POP DX
POP AX
RET

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

;;;;;;;;;;;;;;;; printspace
printspace:
PUSH AX
PUSH DX

MOV AH, 0x02
MOV DL, ' '
INT 0x21

POP DX
POP AX
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

;;;;;;;;;;;;;;;; printhex16: print hex representation of byte in AH, then AL
printhex16:
PUSH AX
MOV AL, AH
CALL printhex
POP AX
CALL printhex
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
MOV DL, [ES:SI]
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
MOV DL, [ES:SI]
MOV AH, 0x02
INT 0x21

POP AX
POP DX
POP SI
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


; IN AX
; OUT AX
; error: carry flag set, AX is undefined
; ok: carry flag not set, AX is set from 0 - 15
chtos:
SUB AL, 48
JL chtoserr
CMP AL, 10
JL chtossucc

SUB AL, (65 - 48)
JL chtoserr
CMP AL, 6
JL chtossucc16

SUB AL, (97 - 65)
JL chtoserr
CMP AL, 6
JL chtossucc16

JMP chtoserr

chtossucc16:
ADD AL, 10

chtossucc:
CLC
RET

chtoserr:
STC
RET


; strlen
; IN: DS:DI, ASCIIZ to parse
; OUT: BX Result
strlen:
MOV BX, 0
strlenloop:
CMP byte [DS:DI + BX], 0
JZ strlenexit
INC BX
JMP strlenloop 
strlenexit:
RET
strlenerr:
STC
RET


; strtos
; IN: *DS:DI, ASCIIZ to parse
; OUT: DX strtos result
; error: carry flag set, DX undefined
; ok: carry flag not set, DX holds result
strtos:
PUSH AX
PUSH BX
PUSH CX

CALL strlen
MOV CX, BX

CMP CX, 0
JZ strtoserr

CMP CX, 4
JG strtoserr

DEC CX

; AX set below
MOV BX, 0
; CX set above in strlen
MOV DX, 0

strtosloop:
MOV AH, 0
MOV AL, [DS:DI + BX]
CMP AL, 0
JZ strtosok

;Get the value of the digit and put into AL
CALL chtos
JC strtoserr

; Shift CX according to the current position (MUL 4)
SHL CX, 2
; Then shift the result by CL
SHL AX, CL
ADD DX, AX
; The shift CX back to what it was
SHR CX, 2

CMP CX, 0
JZ strtosok
INC BX
DEC CX
JMP strtosloop

strtosok:
CLC
JMP strtosend

strtoserr:
STC

strtosend:
POP CX
POP BX
POP AX
RET

section .data

hexenc:
db \
'0', '1', '2', '3', \
'4', '5', '6', '7', \
'8', '9', 'A', 'B', \
'C', 'D', 'E', 'F'
