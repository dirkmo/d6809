module bench();

`include "defines.v"

reg [7:0] mem[65535:0];

reg [15:0] IR;
reg [15:0] AR;
reg [15:0] PC;
reg [7:0] A;
reg [7:0] B;
reg [7:0] T;
reg [7:0] DP;
reg [15:0] X;
reg [15:0] Y;

wire [15:0] fetch;
wire [3:0] mem_read;
wire pc_inc;

reg reset;
reg clk;

reg [7:0] db; // data bus

CtrlUnit ctrlunit(
    .clk(clk),
    .reset(reset),
    .IR(IR),
    .PC(PC),
    .AR(AR),
    .T(T),
    .DP(DP),
    .A(A),
    .B(B),
    .X(X),
    .Y(Y),
    .fetch(fetch),
    .pc_inc(pc_inc),
    .mem_read(mem_read)
);

always #5 clk = ~clk;

integer addr;

always @(mem_read)
begin
    db = 'hXX;
    case( mem_read )
        MEMREAD_PC: addr = PC;
        MEMREAD_AR: addr = AR;
        MEMREAD_DP_ARL: addr = {DP,AR[7:0]};
        MEMREAD_D: addr = {A,B};
    endcase
    db = mem[addr];
    $display("mem_read(%04X) = %02X", addr, db);
end

always @(posedge clk)
begin
    if( pc_inc ) begin
        PC <= PC + 'd1;
    end
    if( fetch[FETCH_IR] ) IR <= db;
    if( fetch[FETCH_ARL] ) AR[7:0] <= db;
    if( fetch[FETCH_ARH] ) AR[15:8] <= db;
    if( fetch[FETCH_T] ) T <= db;
    if( fetch[FETCH_A] ) A <= db;
    if( fetch[FETCH_B] ) B <= db;
    if( fetch[FETCH_XL] ) X[7:0] <= db;
    if( fetch[FETCH_XH] ) X[15:8] <= db;
    if( fetch[FETCH_YL] ) Y[7:0] <= db;
    if( fetch[FETCH_YH] ) Y[15:8] <= db;
end

integer idx;

initial begin
    clk = 0;
    IR = 0;
    PC = 0;
    $readmemh( "memory.hex", mem );
    //$dumpfile("test.vcd");
    $dumpvars;
    reset = 1; #10; reset = 0; #15;
    #100;

    $finish;
end

endmodule
