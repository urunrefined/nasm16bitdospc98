ORG 0x100

; Open existing file
; AH = 0x3D
; AL = mode
; DS:DX = PTR to filename
; CL = 0

; Allocate stack for print. Maximum values here is 127
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

; Use the next 128 bytes on the stack for the filename we want
; Move result DI from cutstring0d to input SI for getbetweenspace
MOV SI, DI
MOV DI, SP
ADD DI, 128
MOV CX, 128
MOV AX, 0

; Get first parameter
CALL getbetweenspace
JC exit
CALL printtozero
CALL printnewline

MOV AH, 0x3D
;; READ Only
MOV AL, 0x00
;; DX Contains string
MOV DX, DI
;; CL is irrelevant in our case, some strange networking stuff
MOV CL, 0x00
INT 0x21

; Carry flag signals error
JC exiterror
; OK, AX now holds the FD
JMP exitok

; exit
exiterror:
MOV DI, msg_openfail
CALL printtozero
JMP exit

exitok:

; AX still holds the FD
MOV BX, AX
CALL readhexfromfile

; Close the FD
; BX = FD to close
; AH = 0x3E = Close file
MOV AH, 0x3E
INT 21

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

;;;;;;;;;;;;;;;; readhexfromfile: read and print hex content from file until EOF
;;;;;;;;;;;;;;;; BX = filehandle
readhexfromfile:
PUSH AX
PUSH CX
PUSH DX

; We just read a max of 16 bytes in this example
; This saves us from doing some sort of separate buffer management
SUB SP, 16

readhexfromfileloop:
; READ command
MOV AH, 0x3F
; BX should be the file-handle, but it is already set on proc entry -- no need to set it
; CX should be the size to read, in this case 16 bytes
MOV CX, 16
; Set DX to our local variable, which we have allocated on the stack (see
; sub above). DS:DX is the buffer, into which will be read
MOV DX, SP
INT 0x21

; AX has number of bytes read ~
; Carry flag signals error -- in this case we simply leave
JC readhexfromfileend

; Check if EOF encountered
CMP AX, 0
JZ readhexfromfileend

; The only remaining possiblity should be AX = bytesread. 
; These bytes we will printed

MOV DI, SP
MOV CX, AX

CALL printmemory
CALL printspace
CALL printprintable
CALL printnewline

JMP readhexfromfileloop

readhexfromfileend:
ADD SP, 16

POP DX
POP CX
POP AX
RET

;;;;;;;;;;;;;;;; printtozero
printtozero:
PUSH AX
PUSH DX
PUSH BX

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

;;;;;;;;;;;;;;;; printspace: Prints a space
printspace:
PUSH AX
MOV AL, ' '
CALL printdirect
POP AX
RET

;;;;;;;;;;;;;;;; printnewline: Prints a newline
printnewline:
PUSH AX
MOV AL, 0x0D
CALL printdirect
MOV AL, 0x0A
CALL printdirect
POP AX
RET

;;;;;;;;;;;;;;;; printmemory: Print memory as hex starting from byte DS:DI, size CX
;;;;;;;;;;;;;;;; IN: *DS:DI Pointer to buffer, which is to be printed
;;;;;;;;;;;;;;;; IN: CX: Length of the buffer
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

;Pad
MOV CX, 16
SUB CX, BX
IMUL CX, 3
CALL printrep

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
;;;;;;;;;;;;;;;; IN: AL byte to be printed
printdirect:
PUSH AX
PUSH DX

MOV DL, AL
MOV AH, 0x02
INT 0x21

POP DX
POP AX

RET

;;;;;;;;;;;;;;;; printrep: print byte in AL CX times
;;;;;;;;;;;;;;;; IN: AL byte to be printed
;;;;;;;;;;;;;;;; IN: CX number of times to print the byte
printrep:
PUSH BX
PUSH CX

MOV BX, 0
printreploop:

CMP CX, BX
JZ printrepend

CALL printdirect
INC BX
JMP printreploop

printrepend:
POP CX
POP BX
RET


;;;;;;;;;;;;;;;; printhex: print hex representation of byte in AL
;;;;;;;;;;;;;;;; IN: AL byte to be printed as HEX
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

msg_openok:
db "Open success", 0x0D, 0x0A, 0

msg_openfail:
db "Open fail", 0x0D, 0x0A, 0
