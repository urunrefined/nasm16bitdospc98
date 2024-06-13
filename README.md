### Assorted NASM PC98 DOS 16=BIT .COM examples

## What
The examples contained in this repository illustrate many functions one
would like to do in a PC98/DOS environment. All resulting files will be
.COM executeables and rely on a segmented memory model. There has been an
effort made to not rely on any writeable global data and use only temporary memory on
the stack for large additional in/out values.

This is just a repository which I will update as I go along. While the focus
will be programs which will run on the pc98, most of these programs should
run on plain "PC" (IBM) machines and their clones.

## Why
For some reason there are no easy to follow NASM examples
for PC98 running MSDOS out there. Hope this helps a bit.
Please note there are many instructions which do not technically need to
be there, however they are there to clarify what is being done. Most of the time
this will be just clearing the A* register, in order to make sure it is 0,
even though it should (looking at the previous instructions) be 0
anyway, or resetting the stack, even though the program will exit anyway, or
stuff like using MOV REG 0 instead of XOR REG REG.
This code is purely for understanding, not optimization. This is
also why a lot of CALL instructions are used and all used registers are
saved / restored in each function. It is neither fast, nor is it trying to be.
An effort has been made to not rely on any writeable, global data and
use only temporary memory on the stack for large additional in/out values.

## Info
All the created executeables will work in the assumption the the memory
management is "segmented", as described in Intels "INTEL 80386 programmers
reference manual". Many of the programs will also work on a non PC98 system,
however eventually I will add some which require this (graphics/sound
stuff).

## COM loading
The PSP is loaded at 0 to (including) 0xff, the code from the COM file loaded
at 0x100 -> end. This is why these nasm files have an ORG 0x100 hint at the
top, except the dummy, which does not need this information to work.

For reading how this stuff works I recommend the following:
* INTEL 80386 PROGRAMMER'S REFERENCE MANUAL 1986 (The current manual is incomprehensable -- Just too much stuff)
* Ralf Brown's Interrupt List
* Program_Segment_Prefix page on Wikipedia
* DOS FUNCTIONS AND INTERRUPTS(KEYBOARD AND VIDEO PROCESSING) (lecture 6 : Programming with 8086 Microprocessor from some university)

## Assembling
*make* will create all binaries necessary.
Each file should be well documented, including what all the calls are.
In general all parameters are passed through registers.
The DOS API you need to run these examples will be 2.0 or greater. 1.x is
not supported.
You need at least a 386 (Some of these programs won't require it -- most
will).

## Disassembling
I recommend the following command to disassemble COM files:
* objdump -D -b binary -mi386 -Maddr16,data16,intel 'executeable' * 
Be aware the data section will also be disassembled, giving you garbage
operations at the end. There is no easy way to add data/code segment
information to COM files, so this is the way it will be.

## Examples

### dummy.nasm
Doesnt do anything. Exits immediately

### psppparm.nasm
Prints the first 0xff bytes of the current DS segment
Please note the previous data of whatever was in this
segment before is not scrubbed, as such you will see
data from the previous process after the 0D in the
commandline.

### hexdump.nasm 
Opens a file given as the argument, hexdumps its content.

### argsplit.nasm
Prints the commandline arguments by copying the program cmdline in the PSP
to a stack allocated buffer and zero terminating it. Then prints the
contained arguments one by one by splitting them with using the spaces, which
separate one argument from another. Other ways of doing this (for example
using some sort of quotes) are not considered.

### callback.nasm
Very simple example showing how to invoke a callback. In this case the
printdirect procedure is invoked 10 times, which prints
an 'A', which was set before calling the callback.

### printmem.nasm
Simple example printing memory. Takes three arguments, segment, offset,
count. Hexprints from SEGMENT:OFFSET for COUNT bytes.

### softir.nasm
Simple example how to register a software interrupt. Takes one argument, the
interrupt number, installs an internal software-routine to this number,
then calls INT on this number, setting the content of a specific address in memory, 
which was 0, to 1.

If you would like to check that this indeed has worked, try to
print the IRTable before and after. For example:

```
A:¥>printmem 20 0 8
73 36 60 00 73 36 60 00
```

This prints interrupt 0x80, 0x81 (0x20(DEC 32) *
0x10 (BytesPerSegment (DEC 16)) / (PTRSize)0x04)

These are two IR addresses (LE - Low bytes printed first).
The values of these vectors do not have to be the same as
in the example above, depending on what you have loaded onto
your system.

Now use softir to try a software interrupt on 0x80:
```
A:¥>softir 80
[...]
00007AD9
[...]
```

Aftwards use printmem with the same parameters again. It should look something like:
```
D9 7A 00 00 73 36 60 00
```

Note that the output here is reversed (Lower Byte printed first), in contrast
to softir, which prints the "value" as one would expect in modern times
(positional notation, higher exponent to the left).
