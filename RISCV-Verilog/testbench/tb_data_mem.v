`timescale 1ns/1ps
module tb_data_mem;
    reg clk, mem_read, mem_write;
    reg [31:0] address, write_data;
    reg [2:0] funct3;
    wire [31:0] read_data;

    data_mem #(.DEPTH_BYTES(64)) dut(
        .clk(clk), .mem_read(mem_read), .mem_write(mem_write), .address(address),
        .write_data(write_data), .funct3(funct3), .read_data(read_data)
    );
    initial clk=0;
    always #5 clk=~clk;

    initial begin
        mem_read=0; mem_write=0; address=0; write_data=0; funct3=0;
        // Store 0x80FF7F01 as a word at byte address 4.
        @(negedge clk); address=4; write_data=32'h80FF7F01; funct3=3'b010; mem_write=1;
        @(posedge clk); #1; mem_write=0;

        mem_read=1; funct3=3'b010; address=4; #1;
        if (read_data !== 32'h80FF7F01) $fatal(1,"LW failed: %h",read_data);
        funct3=3'b000; address=7; #1;
        if (read_data !== 32'hFFFFFF80) $fatal(1,"LB failed: %h",read_data);
        funct3=3'b100; address=7; #1;
        if (read_data !== 32'h00000080) $fatal(1,"LBU failed: %h",read_data);
        funct3=3'b001; address=6; #1;
        if (read_data !== 32'hFFFF80FF) $fatal(1,"LH failed: %h",read_data);
        funct3=3'b101; address=6; #1;
        if (read_data !== 32'h000080FF) $fatal(1,"LHU failed: %h",read_data);

        mem_read=0; mem_write=1; funct3=3'b000; address=12; write_data=32'hAABBCCDD;
        @(posedge clk); #1; mem_write=0; mem_read=1; #1;
        if (read_data !== 32'h000000DD) $fatal(1,"SB failed: %h",read_data);
        $display("tb_data_mem: all tests passed");
        $finish;
    end
endmodule
