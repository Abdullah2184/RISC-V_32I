`timescale 1ns/1ps
module tb_instruction_mem;
    reg [31:0] address;
    wire [31:0] instruction;

    instruction_mem #(.DEPTH_WORDS(4)) dut(.address(address), .instruction(instruction));

    initial begin
        #1;
        dut.mem[0]=32'h00500093;
        dut.mem[1]=32'h00700113;
        address=32'd0; #1;
        if (instruction !== 32'h00500093) $fatal(1,"Instruction read at 0 failed");
        address=32'd4; #1;
        if (instruction !== 32'h00700113) $fatal(1,"Instruction read at 4 failed");
        address=32'd100; #1;
        if (instruction !== 32'h00000013) $fatal(1,"Out-of-range read should return NOP");
        $display("tb_instruction_mem: all tests passed");
        $finish;
    end
endmodule
