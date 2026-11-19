`timescale 1ns/1ps

// Byte-addressable data memory supporting LB/LH/LW/LBU/LHU and SB/SH/SW.
// Halfword and word accesses are expected to be naturally aligned.
module data_mem #(
    parameter DEPTH_BYTES = 4096
) (
    input  wire        clk,
    input  wire        mem_read, //control signals
    input  wire        mem_write,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    input  wire [2:0]  funct3,
    output reg  [31:0] read_data
);
    reg [7:0] mem [0:DEPTH_BYTES-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH_BYTES; i = i + 1)
            mem[i] = 8'h00; //byte-addressable //setting all bytes to zero
    end

    // Asynchronous load path.
    always @(*) begin
        read_data = 32'd0;
        if (mem_read) begin
            case (funct3)
                3'b000: read_data = {{24{mem[address][7]}}, mem[address]}; // LB (sign-extended to 32 bits)
                3'b001: read_data = {{16{mem[address + 32'd1][7]}},
                                      mem[address + 32'd1], mem[address]}; // LH (sign-extended)
                3'b010: read_data = {mem[address + 32'd3], mem[address + 32'd2],
                                     mem[address + 32'd1], mem[address]}; // LW
                3'b100: read_data = {24'd0, mem[address]}; // LBU
                3'b101: read_data = {16'd0, mem[address + 32'd1], mem[address]};
                default: read_data = 32'd0;
            endcase
        end
    end

    // Synchronous store path. Little-endian byte ordering.
    always @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                3'b000: mem[address] <= write_data[7:0];
                3'b001: begin
                    mem[address]              <= write_data[7:0];
                    mem[address + 32'd1]     <= write_data[15:8];
                end
                3'b010: begin
                    mem[address]              <= write_data[7:0];
                    mem[address + 32'd1]     <= write_data[15:8];
                    mem[address + 32'd2]     <= write_data[23:16];
                    mem[address + 32'd3]     <= write_data[31:24];
                end
                default: begin
                    // Unsupported store width: no write.
                end
            endcase
        end
    end
endmodule
