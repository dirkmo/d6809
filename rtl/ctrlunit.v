module CtrlUnit(
    clk,
    reset,
    IR,
    PC,
    AR,
    A,
    B,
    T,
    X,
    Y,
    fetch,
    pc_inc,
    mem_read
);

`include "opcodes.v"
`include "defines.v"

input clk;
input reset;
input [15:0] IR;
input [15:0] AR;
input [15:0] PC;
input [7:0] A;
input [7:0] B;
input [7:0] T;
input [15:0] X;
input [15:0] Y;
output reg [3:0] mem_read;
output reg [3:0] fetch;
output reg pc_inc;

reg [4:0] state;
reg [4:0] next_state;

always @(posedge clk)
begin
    if( reset ) begin
        state <= 'd0;
    end else begin
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
    EXECUTE       = 10;

always @(*)
begin
    next_state = IDLE;
    mem_read = 'd0;
    fetch = 'd0;
    pc_inc = 0;
    case( state )
        IDLE: begin
        end
        FETCH_OP: begin
            mem_read[MEMREAD_PC] = 1;
            fetch[FETCH_IR] = 1;
            next_state = DECODE;
        end
        DECODE: begin

            // extended addressing $7X, $BX, $FX
            if ( IR[7:4] == 4'h7 || IR[7:4] == 4'hF || IR[7:4] == 4'hB )
            begin
                next_state = EXTADDR1;
                mem_read[MEMREAD_PC] = 1;
                pc_inc = 1;
                fetch[FETCH_ARH] = 1;
            end else

            // immediate addressing $CX, $80-$8C, $8E, $34-$37
            if ( IR[7:4] == 4'hC || ( IR >= 8'h80 && IR <= 8'h8C ) || IR == 8'h8E || 
               ( IR >= 8'h34 && IR <= 8'h37) || IR == IMM_ORCC || IR == IMM_ANDCC ||
                 IR == IMM_EXG || IR == IMM_TFR )
            begin
                // put byte from memory into T
                next_state = EXECUTE;
                mem_read[MEMREAD_PC] = 1;
                fetch[FETCH_T] = 1;
                pc_inc = 1;
            end else

            // inherent addressing $39-$5F, NOP, SYNC, DAA, SEX
            if( IR >= 8'h39 && IR <= 8'h5F || IR == INH_NOP || IR == INH_SYNC || IR == INH_DAA || 
                IR == INH_SEX )
            begin
                next_state = EXECUTE;
            end else

            // direct addressing
            if( (IR >= 8'h00 && IR <= 8'h0F) || (IR >= 8'h90 && IR <= 8'h9F) || (IR >= 8'hD0 && IR <= 8'hDF))
            begin
                // load lower address byte into AR[7:0]
                next_state = DIRECT;
                mem_read[MEMREAD_PC] = 1;
                fetch[FETCH_ARL] = 1;
                pc_inc = 1;
            end else

            // indexed addressing
            if( (IR>=8'h30 && IR<=8'h33) || (IR>=8'h60 && IR<=8'h6F) || (IR>=8'hA0 && IR<=8'hAF) || (IR>=8'hE0 && IR<=8'hEF) ) 
            begin

            end else

            // short relative addressing
            if( IR==REL_LBRA || IR==REL_LBSR || (IR>=8'h20 && IR<=8'h2F) || IR==REL_BSR )
            begin
                next_state = RELATIVE;
                mem_read[MEMREAD_PC] = 1;
                fetch[FETCH_ARL] = 1;
                pc_inc = 1;
                // long relative addressing
                if( IR==REL_LBRA || IR==REL_LBSR )
                begin
                    next_state = RELATIVE_LONG;
                end
            end else

            // indirect
            if( (IR>=8'h30 && IR<=8'h33) || (IR>=8'h60 && IR<=8'h6F) || (IR>=8'hA0 && IR<=8'hAF) || (IR>=8'hE0 && IR<=8'hEF) )
            begin
            end else

            begin
                $display("Unknown opcode %02X", IR);
            end
        end

        // extended addressing
        EXTADDR1: begin // fetch lower address byte
            next_state = EXTADDR2;
            mem_read[MEMREAD_PC] = 1;
            pc_inc = 1;
            fetch[FETCH_ARL] = 1;
        end
        EXTADDR2: begin // fetch data from memory into T
            next_state = EXECUTE;
            mem_read[MEMREAD_AR] = 1;
            fetch[FETCH_T] = 1;
        end

        DIRECT: begin
            // read data from memory into T
            mem_read[MEMREAD_DP_ARL] = 1;
            fetch[FETCH_T] = 1;
            next_state = EXECUTE;
        end

        RELATIVE_LONG: begin
            next_state = RELATIVE;
            mem_read[MEMREAD_PC] = 1;
            fetch[FETCH_ARL] = 1;
            pc_inc = 1;
        end
        
        RELATIVE: begin
        end

        EXECUTE:
        begin
        end

    endcase
end

initial $dumpvars;

endmodule
