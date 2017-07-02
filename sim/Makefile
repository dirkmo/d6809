all:
	iverilog -Wall -I../rtl -o test ../rtl/ctrlunit.v bench.v

sim: all
	./test
	gtkwave dump.vcd config.gtkw &
