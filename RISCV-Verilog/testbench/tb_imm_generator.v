`timescale 1ns/1ps
module tb_imm_generator;
    reg [31:0] instruction;
    reg [2:0] imm_sel;
    wire [31:0] immediate;

    imm_generator dut(.instruction(instruction), .imm_sel(imm_sel), .immediate(immediate));

    task check;
        input [31:0] expected;
        input [127:0] label;
        begin
            #1;
            if (immediate !== expected)
                $fatal(1, "Immediate %0s failed: got %h expected %h", label, immediate, expected);
            else $display("PASS immediate: %0s", label);
        end
    endtask

    initial begin
        instruction=32'hFFF00013; imm_sel=3'b000; check(32'hFFFFFFFF,"I = -1");
        instruction=(32'h7F << 25) | (32'd3 << 20) | (32'd2 << 15) |
                    (32'b010 << 12) | (32'd28 << 7) | 32'b0100011;
        imm_sel=3'b001; check(32'hFFFFFFFC,"S = -4");
        instruction=32'h00208463; imm_sel=3'b010; check(32'd8,"B = +8");
        instruction=32'h12345037; imm_sel=3'b011; check(32'h12345000,"U");
        instruction=32'h008000EF; imm_sel=3'b100; check(32'd8,"J = +8");
        $display("tb_imm_generator: all tests passed");
        $finish;
    end
endmodule
