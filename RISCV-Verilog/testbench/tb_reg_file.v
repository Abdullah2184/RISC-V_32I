`timescale 1ns/1ps
module tb_reg_file;
    reg clk, reset, write_enable;
    reg [4:0] read_addr1, read_addr2, write_addr;
    reg [31:0] write_data;
    wire [31:0] read_data1, read_data2;

    reg_file dut(
        .clk(clk), .reset(reset), .write_enable(write_enable),
        .read_addr1(read_addr1), .read_addr2(read_addr2), .write_addr(write_addr),
        .write_data(write_data), .read_data1(read_data1), .read_data2(read_data2)
    );

    initial clk=0;
    always #5 clk=~clk;

    initial begin
        reset=1; write_enable=0; read_addr1=0; read_addr2=0; write_addr=0; write_data=0;
        @(posedge clk); #1; reset=0;
        write_enable=1; write_addr=5'd5; write_data=32'h12345678;
        @(posedge clk); #1; write_enable=0;
        read_addr1=5'd5; read_addr2=5'd0; #1;
        if (read_data1 !== 32'h12345678) $fatal(1,"Register x5 read failed");
        if (read_data2 !== 32'd0) $fatal(1,"Register x0 is not zero");
        write_enable=1; write_addr=5'd0; write_data=32'hFFFFFFFF;
        @(posedge clk); #1; write_enable=0; read_addr1=0; #1;
        if (read_data1 !== 32'd0) $fatal(1,"Write to x0 was not ignored");
        $display("tb_reg_file: all tests passed");
        $finish;
    end
endmodule
