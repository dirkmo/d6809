module bench();

`include "defines.v"

reg [7:0] mem[65535:0];

reg [7:0] IR;
reg [7:0] postbyte;
reg [15:0] AR;
reg [15:0] PC;
reg [15:0] SP; // hardware stack pointer
reg [15:0] US; // user stack pointer
reg [7:0] A;
reg [7:0] B;
reg [7:0] T;
reg [7:0] DP;
reg [15:0] X;
reg [15:0] Y;
reg [7:0] CC;

wire [15:0] fetch;
wire [3:0] output_on_ab;
wire [4:0] output_on_db;
wire [15:0] fetch_from_ab;
wire [16:0] fetch_from_db;
wire [3:0] inc;
wire [3:0] dec;

reg reset;
reg clk;

reg [7:0] db; // data bus
reg [15:0] ab; // address bus


CtrlUnit ctrlunit(
    .clk(clk),
    .reset(reset),
    .IR(IR),
    .postbyte(postbyte),
    .PC(PC),
    .AR(AR),
    .SP(SP),
    .US(US),
    .T(T),
    .DP(DP),
    .A(A),
    .B(B),
    .X(X),
    .Y(Y),
    .CC(CC),
    .output_on_ab(output_on_ab),
    .output_on_db(output_on_db),
    .fetch_from_ab(fetch_from_ab),
    .fetch_from_db(fetch_from_db),
    .inc(inc),
    .dec(dec)
);

always #5 clk = ~clk;

always @(output_on_ab)
begin
    ab = 'hX;
    case(output_on_ab)
        AB_PC:     ab = PC;
        AB_AR:     ab = AR;
        AB_DP_ARL: ab = {DP,AR[7:0]};
        AB_D:      ab = {A,B};
        AB_SP:     ab = SP;
        AB_US:     ab = US;
    endcase
end

always @(output_on_db)
begin
    case(output_on_db)
        DB_IR:  db = IR;
        DB_ARL: db = AR[7:0];
        DB_ARH: db = AR[15:8];
        DB_T:   db = T;
        DB_A:   db = A;
        DB_B:   db = B;
        DB_XL:  db = X[7:0];
        DB_XH:  db = X[15:8];
        DB_YL:  db = Y[7:0];
        DB_YH:  db = Y[15:8];
        DB_PB:  db = postbyte;
        DB_CC:  db = CC;
        DB_USH: db = US[15:8];
        DB_USL: db = US[7:0];
        DB_SPH: db = SP[15:8];
        DB_SPL: db = SP[7:0];
        DB_MEM: db = mem[ab]; // read memory
    endcase
end

always @(posedge clk)
begin
    // increment / decrement address registers
    if( inc ) begin
        case( inc )
            AB_PC: PC <= PC + 'd1;
            AB_SP: SP <= SP + 'd1;
            AB_US: US <= US + 'd1;
            AB_AR: AR <= AR + 'd1;
            AB_D:  {A,B} <= {A,B} + 'd1;
        endcase
    end else if( dec ) begin
        case( dec )
            AB_PC: PC <= PC - 'd1;
            AB_SP: SP <= SP - 'd1;
            AB_US: US <= US - 'd1;
            AB_AR: AR <= AR - 'd1;
            AB_D:  {A,B} <= {A,B} - 'd1;
        endcase
    end
end

always @(posedge clk)
begin
    // fetch registers from data bus
    if( fetch_from_db[DB_IR] ) IR <= db;
    if( fetch_from_db[DB_ARL] ) AR[7:0] <= db;
    if( fetch_from_db[DB_ARH] ) AR[15:8] <= db;
    if( fetch_from_db[DB_T] ) T <= db;
    if( fetch_from_db[DB_A] ) A <= db;
    if( fetch_from_db[DB_B] ) B <= db;
    if( fetch_from_db[DB_XL] ) X[7:0] <= db;
    if( fetch_from_db[DB_XH] ) X[15:8] <= db;
    if( fetch_from_db[DB_YL] ) Y[7:0] <= db;
    if( fetch_from_db[DB_YH] ) Y[15:8] <= db;
    if( fetch_from_db[DB_CC] ) CC[7:0] <= db;
    if( fetch_from_db[DB_PB] ) postbyte[7:0] <= db;
    if( fetch_from_db[DB_USH] ) US[15:8] <= db;
    if( fetch_from_db[DB_USL] ) US[7:0] <= db;
    if( fetch_from_db[DB_SPH] ) SP[15:8] <= db;
    if( fetch_from_db[DB_SPL] ) SP[7:0] <= db;
    if( fetch_from_db[DB_MEM] ) mem[ab] <= db; // write to memory
end

always @(posedge clk)
begin
    // fetch registers from address bus
    if( fetch_from_ab[AB_PC] ) PC    <= ab;
    if( fetch_from_ab[AB_AR] ) AR    <= ab;
    if( fetch_from_ab[AB_D]  ) {A,B} <= ab;
    if( fetch_from_ab[AB_SP] ) SP    <= ab;
    if( fetch_from_ab[AB_US] ) US    <= ab;
end


initial begin
    clk = 0;
    IR = 0;
    PC = 0;
    DP = 0;
    postbyte = 0;
    $readmemh( "memory.hex", mem );
    //$dumpfile("test.vcd");
    $dumpvars;
    reset = 1; #10; reset = 0; #15;
    #100;

    $finish;
end

endmodule
