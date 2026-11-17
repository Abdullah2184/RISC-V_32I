`timescale 1ns/1ps

// Immediate formats: 000=I, 001=S, 010=B, 011=U, 100=J.
module imm_generator (
    input  wire [31:0] instruction,
    input  wire [2:0]  imm_sel,
    output reg  [31:0] immediate
);
    always @(*) begin
        case (imm_sel)
            3'b000: immediate = {{20{instruction[31]}}, instruction[31:20]}; //20{} is a bit extender
            3'b001: immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            3'b010: immediate = {{19{instruction[31]}}, instruction[31], instruction[7],
                                 instruction[30:25], instruction[11:8], 1'b0};
            3'b011: immediate = {instruction[31:12], 12'b0};
            3'b100: immediate = {{11{instruction[31]}}, instruction[31], instruction[19:12],
                                 instruction[20], instruction[30:21], 1'b0};
            default: immediate = 32'b0;
        endcase
    end
endmodule
