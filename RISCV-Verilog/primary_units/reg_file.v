`timescale 1ns/1ps

module reg_file (
    input  wire        clk,
    input  wire        reset,
    input  wire        write_enable,
    input  wire [4:0]  read_addr1,
    input  wire [4:0]  read_addr2,
    input  wire [4:0]  write_addr,
    input  wire [31:0] write_data,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);
    reg [31:0] regs [0:31];
    integer i;

    // Asynchronous reads. x0 is hardwired to zero.
    assign read_data1 = (read_addr1 == 5'd0) ? 32'd0 : regs[read_addr1];
    assign read_data2 = (read_addr2 == 5'd0) ? 32'd0 : regs[read_addr2];

    // Synchronous reset and write port.
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'd0; //reset all registers to zero
        end else if (write_enable && (write_addr != 5'd0)) begin
            regs[write_addr] <= write_data;
        end
    end
endmodule
