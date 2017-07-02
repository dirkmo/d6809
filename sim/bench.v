module bench();

`include "defines.v"

reg [7:0] mem[0:65535];

reg [15:0] IR;
reg [15:0] AR;
reg [15:0] PC;
reg [7:0] A;
reg [7:0] B;
reg [7:0] T;
reg [15:0] X;
reg [15:0] Y;

wire [3:0] fetch;
wire [3:0] mem_read;
wire pc_inc;

reg reset;
reg clk;

CtrlUnit ctrlunit(
    .clk(clk),
    .reset(reset),
    .IR(IR),
    .PC(PC),
    .AR(AR),
    .T(T),
    .A(A),
    .B(B),
    .X(X),
    .Y(Y),
    .fetch(fetch),
    .pc_inc(pc_inc),
    .mem_read(mem_read)
);

always #5 clk = ~clk;

initial begin
    clk = 0;
    IR = 0;
    PC = 0;
    $readmemh( "memory.hex", mem );
    //$dumpfile("test.vcd");
    $dumpvars;
    reset = 1; #10; reset = 0; #10;
    #100;

    $finish;
end

endmodule
