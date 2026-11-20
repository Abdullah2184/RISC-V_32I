`timescale 1ns/1ps
module tb_alu;
    reg [31:0] a, b;
    reg [3:0] alu_ctrl; // ALUSel per Table 3.8
    wire [31:0] result;
    wire zero;

    alu dut(
        .A(a),
        .B(b),
        .ALUControl(alu_ctrl),
        .Result(result),
        .Zero(zero)
    );

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
        // Table 6-1: Verification of ALU Working (ALUSel encoding per Table 3.8)
        a = 32'h00000003; b = 32'h00000003; alu_ctrl = 4'b0000; check(32'h00000006, "ADD 3 + 3");
        a = 32'hFFFFFFFD; b = 32'h00000007; alu_ctrl = 4'b0000; check(32'h00000004, "ADD -3 + 7");
        a = 32'hFFFFFFFC; b = 32'h00000001; alu_ctrl = 4'b0001; check(32'hFFFFFFFB, "SUB -4 - 1");
        a = 32'h00000007; b = 32'h00000007; alu_ctrl = 4'b0001; check(32'h00000000, "SUB 7 - 7");
        a = 32'h00000001; b = 32'h00000004; alu_ctrl = 4'b0010; check(32'h00000010, "SLL");
        a = 32'hFFFFFFFF; b = 32'h00000001; alu_ctrl = 4'b0011; check(32'h00000001, "SLT signed");
        a = 32'hFFFFFFFF; b = 32'h00000001; alu_ctrl = 4'b0100; check(32'h00000000, "SLTU unsigned");
        a = 32'hAAAAAAAA; b = 32'hFFFF0000; alu_ctrl = 4'b0101; check(32'h5555AAAA, "XOR");
        a = 32'h80000000; b = 32'h00000004; alu_ctrl = 4'b0110; check(32'h08000000, "SRL");
        a = 32'h80000000; b = 32'h00000004; alu_ctrl = 4'b0111; check(32'hF8000000, "SRA");
        a = 32'h0000F0F0; b = 32'h00000F0F; alu_ctrl = 4'b1000; check(32'h0000FFFF, "OR");
        a = 32'hFFFF00FF; b = 32'h0F0F0F0F; alu_ctrl = 4'b1001; check(32'h0F0F000F, "AND");
        a = 32'h12345678; b = 32'hABCDE000; alu_ctrl = 4'b1010; check(32'hABCDE000, "BSEL");

        $display("tb_alu: all tests passed");
        $finish;
    end
endmodule