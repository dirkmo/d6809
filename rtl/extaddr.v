module ExtendedAddressing(
    clk,
    start,
    active,
    mem_read_pc,
    pc_inc,
    ar_fetch
);

input clk;
input start;
output active;

output reg mem_read_pc;
output reg pc_inc;
output reg [1:0] ar_fetch;

reg [4:0] state;
reg [4:0] next_state;

always @(posedge clk)
begin
    state <= next_state;
end

localparam
    IDLE           = 'd0,
    FETCH_ADDRHIGH = 'd1,
    FETCH_ADDRLOW  = 'd2;

assign active = state != IDLE;

always @(*)
begin
    next_state = IDLE;
    mem_read_pc = 0;
    ar_fetch = 'd0;
    pc_inc = 0;
    case( state )
        IDLE: begin
            if( start ) begin
                next_state = FETCH_ADDRHIGH;
            end
        end
        FETCH_ADDRHIGH: begin
            next_state = FETCH_ADDRLOW;
            mem_read_pc = 1;
            pc_inc = 1;
            ar_fetch[1] = 1;
        end
        FETCH_ADDRLOW: begin
            next_state = IDLE;
            mem_read_pc = 1;
            pc_inc = 1;
            ar_fetch[0] = 1;
        end
    endcase
end

endmodule
