`timescale 1ns/1ps
module tb_alu;
    reg [31:0] a, b;
    reg [3:0] alu_ctrl;
    wire [31:0] result;

    alu dut(.a(a), .b(b), .alu_ctrl(alu_ctrl), .result(result));

    task check;
        input [31:0] expected;
        input [255:0] label;
        begin
            #1;
            if (result !== expected)
                $fatal(1, "ALU %0s failed: got %h expected %h", label, result, expected);
            else
                $display("PASS ALU: %0s", label);
        end
    endtask

    initial begin
        a = 32'd10; b = 32'd3;
        alu_ctrl = 4'b0000; check(32'd13, "ADD");
        alu_ctrl = 4'b0001; check(32'd7, "SUB");
        alu_ctrl = 4'b0010; check(32'd2, "AND");
        alu_ctrl = 4'b0011; check(32'd11, "OR");
        alu_ctrl = 4'b0100; check(32'd9, "XOR");
        alu_ctrl = 4'b0101; b = 32'd2; check(32'd40, "SLL");
        a = 32'h80000000; b = 32'd1;
        alu_ctrl = 4'b0110; check(32'h40000000, "SRL");
        alu_ctrl = 4'b0111; check(32'hC0000000, "SRA");
        a = 32'hFFFFFFFF; b = 32'd1;
        alu_ctrl = 4'b1000; check(32'h00000001, "SLT signed");
        alu_ctrl = 4'b1001; check(32'h00000000, "SLTU unsigned");
        alu_ctrl = 4'b1010; check(32'h00000001, "PASS_B");
        $display("tb_alu: all tests passed");
        $finish;
    end
endmodule
