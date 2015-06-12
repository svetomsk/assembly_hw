all:
	yasm -f elf32 -g dwarf2 hw_sprintf.asm -o hw_sprintf.o
	gcc -g -c test.c -o test.o -m32
	gcc  -o hw1 hw_sprintf.o test.o  -m32

clean:
	rm test.o 
	rm hw_sprintf.o 
	rm hw1
