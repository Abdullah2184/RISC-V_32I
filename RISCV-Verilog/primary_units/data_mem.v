`timescale 1ns/1ps

module data_mem #(
    parameter DEPTH_BYTES = 1024
) (
    input  wire        clk,
    input  wire        mem_rw,     // MemRW: 0 = read, 1 = write
    input  wire [31:0] address,    // Byte address from ALU
    input  wire [31:0] write_data, // DataW = Reg[rs2]
    input  wire [2:0]  funct3,     // Inst[14:12]
    output reg  [31:0] read_data   // DataR (mem)
);
    reg [7:0] mem [0:DEPTH_BYTES-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH_BYTES; i = i + 1)
            mem[i] = 8'd0;
    end

    // Synchronous byte / half-word / word write (little-endian)
    always @(posedge clk) begin
        if (mem_rw) begin
            case (funct3)
                3'b000: begin // SB
                    if (address < DEPTH_BYTES)
                        mem[address] <= write_data[7:0];
                end
                3'b001: begin // SH
                    if ((address + 32'd1) < DEPTH_BYTES) begin
                        mem[address]        <= write_data[7:0];
                        mem[address + 32'd1] <= write_data[15:8];
                    end
                end
                3'b010: begin // SW
                    if ((address + 32'd3) < DEPTH_BYTES) begin
                        mem[address]        <= write_data[7:0];
                        mem[address + 32'd1] <= write_data[15:8];
                        mem[address + 32'd2] <= write_data[23:16];
                        mem[address + 32'd3] <= write_data[31:24];
                    end
                end
                default: ;
            endcase
        end
    end

    // Combinational read with sign/zero extension
    always @(*) begin
        read_data = 32'd0;
        if (!mem_rw) begin
            case (funct3)
                3'b000: begin // LB (signed byte)
                    if (address < DEPTH_BYTES)
                        read_data = {{24{mem[address][7]}}, mem[address]};
                end
                3'b001: begin // LH (signed half-word)
                    if ((address + 32'd1) < DEPTH_BYTES)
                        read_data = {{16{mem[address + 32'd1][7]}}, mem[address + 32'd1], mem[address]};
                end
                3'b010: begin // LW (word)
                    if ((address + 32'd3) < DEPTH_BYTES)
                        read_data = {mem[address + 32'd3], mem[address + 32'd2], mem[address + 32'd1], mem[address]};
                end
                3'b100: begin // LBU (unsigned byte)
                    if (address < DEPTH_BYTES)
                        read_data = {24'd0, mem[address]};
                end
                3'b101: begin // LHU (unsigned half-word)
                    if ((address + 32'd1) < DEPTH_BYTES)
                        read_data = {16'd0, mem[address + 32'd1], mem[address]};
                end
                default: read_data = 32'd0;
            endcase
        end
    end
endmodule