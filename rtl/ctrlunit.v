module CtrlUnit(
    clk,
    reset,
    IR,
    postbyte,
    PC,
    AR,
    SP,
    US,
    A,
    B,
    T,
    DP,
    X,
    Y,
    CC,
    output_on_ab,
    output_on_db,
    fetch_from_ab,
    fetch_from_db,
    inc,
    dec
);

`include "opcodes.v"
`include "defines.v"

input clk;
input reset;
input [7:0] IR;
input [7:0] postbyte;
input [15:0] AR;
input [15:0] PC;
input [15:0] SP; // hardware stack pointer
input [15:0] US; // user stack pointer
input [7:0] A;
input [7:0] B;
input [7:0] T;
input [7:0] DP;
input [15:0] X;
input [15:0] Y;
input [7:0] CC;
output reg [3:0] output_on_ab;
output reg [4:0] output_on_db;
output reg [15:0] fetch_from_ab;
output reg [16:0] fetch_from_db;
output reg [3:0] inc;
output reg [3:0] dec;

reg [15:0] opcode_addr; // opcode address for relative branching

reg [4:0] state;
reg [4:0] next_state;

always @(posedge clk)
begin
    if( reset ) begin
        state <= 'd0;
    end else begin
        if( state == FETCH_OP ) begin
            opcode_addr = PC;
        end
        state <= next_state;
    end
end

localparam
    IDLE          = 0,
    FETCH_OP      = 1,
    DECODE        = 2,
    EXTADDR1      = 3,
    EXTADDR2      = 4,
    DIRECT        = 5,
    RELATIVE      = 6,
    RELATIVE_LONG = 7,
    INDEXED       = 8,
    INDEXED1      = 9,
    INDEXED2      = 10,
    INDEXED3      = 11,
    EXECUTE       = 15;

always @(*)
begin
    next_state = IDLE;
    fetch_from_ab = 'd0;
    fetch_from_db = 'd0;
    output_on_db = 'd0;
    output_on_ab = 'd0;
    inc = 'd0;
    dec = 'd0;
    case( state )
        IDLE: begin
            next_state = FETCH_OP;
        end
        FETCH_OP: begin
            next_state = DECODE;
            output_on_ab = AB_PC;
            output_on_db = DB_MEM;
            fetch_from_db[DB_IR] = 1;
            inc = AB_PC;
        end
        DECODE: begin
            $display("opcode: %02X", IR);
            // extended addressing $7X, $BX, $FX
            if ( IR[7:4] == 4'h7 || IR[7:4] == 4'hF || IR[7:4] == 4'hB )
            begin
                $display("extended addressing");
                next_state = EXTADDR1;
                output_on_ab = AB_PC;
                output_on_db = DB_MEM;
                inc = AB_PC;
                fetch_from_db[DB_ARH] = 1;
            end else

            // immediate addressing $CX, $80-$8C, $8E, $34-$37
            if ( IR[7:4] == 4'hC || ( IR >= 8'h80 && IR <= 8'h8C ) || IR == 8'h8E || 
               ( IR >= 8'h34 && IR <= 8'h37) || IR == IMM_ORCC || IR == IMM_ANDCC ||
                 IR == IMM_EXG || IR == IMM_TFR )
            begin
                $display("immediate addressing");
                // put byte from memory into T
                next_state = EXECUTE;
                output_on_ab = AB_PC;
                output_on_db = DB_MEM;
                fetch_from_db[DB_T] = 1;
                inc = AB_PC;
            end else

            // inherent addressing $39-$5F, NOP, SYNC, DAA, SEX
            if( IR >= 8'h39 && IR <= 8'h5F || IR == INH_NOP || IR == INH_SYNC || IR == INH_DAA || 
                IR == INH_SEX )
            begin
                $display("inherent addressing");
                next_state = EXECUTE;
            end else

            // direct addressing
            if( (IR >= 8'h00 && IR <= 8'h0F) || (IR >= 8'h90 && IR <= 8'h9F) || (IR >= 8'hD0 && IR <= 8'hDF))
            begin
                $display("direct addressing");
                // load lower address byte into AR[7:0]
                next_state = DIRECT;
                output_on_ab = AB_PC;
                output_on_db = DB_MEM;
                fetch_from_db[DB_ARL] = 1;
                inc = AB_PC;
            end else

            // indexed addressing
            if( (IR>=8'h30 && IR<=8'h33) || (IR>=8'h60 && IR<=8'h6F) || (IR>=8'hA0 && IR<=8'hAF) || (IR>=8'hE0 && IR<=8'hEF) ) 
            begin
                $display("indexed addressing");
                // fetch postbyte
                next_state = INDEXED;
                output_on_ab = AB_PC;
                output_on_db = DB_MEM;
                inc = AB_PC;
                fetch_from_db[DB_PB] = 1;
            end else

            // relative addressing
            if( IR==REL_LBRA || IR==REL_LBSR || (IR>=8'h20 && IR<=8'h2F) || IR==REL_BSR )
            begin
                next_state = RELATIVE;
                output_on_ab = AB_PC;
                output_on_db = DB_MEM;
                fetch_from_db[DB_ARL] = 1;
                inc = AB_PC;
                // long relative addressing
                if( IR==REL_LBRA || IR==REL_LBSR )
                begin
                    $display("long relative addressing");
                    next_state = RELATIVE_LONG;
                end else begin
                    $display("short relative addressing");
                end
            end else

            begin
                $display("Unknown opcode %02X", IR);
            end
        end

        // extended addressing
        EXTADDR1: begin // fetch lower address byte
            next_state = EXTADDR2;
            output_on_ab = AB_PC;
            output_on_db = DB_MEM;
            inc = AB_PC;
            fetch_from_db[DB_ARL] = 1;
        end
        EXTADDR2: begin // fetch data from memory into T
            next_state = EXECUTE;
            output_on_ab = AB_AR;
            output_on_db = DB_MEM;
            fetch_from_db[DB_T] = 1;
        end

        DIRECT: begin
            // read data from memory into T
            output_on_ab = AB_DP_ARL;
            output_on_db = DB_MEM;
            fetch_from_db[DB_T] = 1;
            next_state = EXECUTE;
        end

        RELATIVE_LONG: begin
            next_state = RELATIVE;
            output_on_ab = AB_PC;
            output_on_db = DB_MEM;
            fetch_from_db[DB_ARL] = 1;
            inc = AB_PC;
        end
        
        RELATIVE: begin
            if( IR==REL_LBRA ) begin
                // LBRA: long branch always
            end else if( IR==REL_LBSR ) begin
                // LBSR: long branch to subroutine
                $display("LBSR not implemented yet.");
            end else if (IR>=8'h20 && IR<=8'h2F) begin

            end else if( IR==REL_BSR ) begin
                // BSR: branch to subroutine
                $display("BSR not implemented yet.");
            end
        end

        INDEXED: begin
            next_state = INDEXED1;
        end

        INDEXED1: begin
            next_state = INDEXED2;
        end

        INDEXED2: begin
            next_state = INDEXED3;
        end

        INDEXED3: begin
            next_state = EXECUTE;
        end

        EXECUTE:
        begin
        end

    endcase
end

initial $dumpvars;

endmodule
