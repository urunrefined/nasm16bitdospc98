.PHONY: clean all

%.COM: %.nasm
	nasm -f bin $^ -o $@
	
all: dummy.COM hexdump.COM pspparam.COM argsplit.COM callback.COM printmem.COM softir.COM

clean:
	rm -f *.COM
