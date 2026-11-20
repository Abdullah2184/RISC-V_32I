`timescale 1ns/1ps

// alu_op comes from the main control unit:
// 00 = ADD, 01 = decode funct3/funct7, 10 = SUB, 11 = BSEL (LUI).
module alu_control (
    input  wire [1:0] alu_op,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    input  wire       is_r_type,
    output reg  [3:0] alu_ctrl
);
    // PDF Table 3.8 ALUSel Encoding
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_SLL  = 4'b0010;
    localparam ALU_SLT  = 4'b0011;
    localparam ALU_SLTU = 4'b0100;
    localparam ALU_XOR  = 4'b0101;
    localparam ALU_SRL  = 4'b0110;
    localparam ALU_SRA  = 4'b0111;
    localparam ALU_OR   = 4'b1000;
    localparam ALU_AND  = 4'b1001;
    localparam ALU_BSEL = 4'b1010;

    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl = ALU_ADD;
            2'b10: alu_ctrl = ALU_SUB;
            2'b11: alu_ctrl = ALU_BSEL;
            2'b01: begin
                case (funct3)
                    3'b000: alu_ctrl = (is_r_type && (funct7 == 7'b0100000)) ? ALU_SUB : ALU_ADD;
                    3'b001: alu_ctrl = ALU_SLL;
                    3'b010: alu_ctrl = ALU_SLT;
                    3'b011: alu_ctrl = ALU_SLTU;
                    3'b100: alu_ctrl = ALU_XOR;
                    3'b101: alu_ctrl = funct7[5] ? ALU_SRA : ALU_SRL;
                    3'b110: alu_ctrl = ALU_OR;
                    3'b111: alu_ctrl = ALU_AND;
                    default: alu_ctrl = ALU_ADD;
                endcase
            end
            default: alu_ctrl = ALU_ADD;
        endcase
    end
endmodule
