.PHONY: clean all

%.COM: %.nasm
	nasm -f bin $^ -o $@
	
all: dummy.COM hexdump.COM pspparam.COM argsplit.COM callback.COM
	
clean:
	rm -f *.COM
