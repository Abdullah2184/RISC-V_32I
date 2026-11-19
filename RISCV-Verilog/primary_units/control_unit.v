`timescale 1ns/1ps

// Main instruction decoder for the supported RV32I subset.
module control_unit (
    input  wire [6:0] opcode,
    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        alu_src,
    output reg        alu_a_sel,  // 0: rs1, 1: PC (used by AUIPC)
    output reg        branch,
    output reg        jump,
    output reg        jalr,
    output reg [2:0]  imm_sel, 	  // I, S, B, U, J
    output reg [1:0]  alu_op,	 // First level of ALU decoding
    output reg [1:0]  wb_sel     // 00: ALU result, 01: memory (i.e. load), 10: PC+4
);
    always @(*) begin
        // Safe defaults
        reg_write = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        alu_src   = 1'b0;
        alu_a_sel = 1'b0;
        branch    = 1'b0;
        jump      = 1'b0;
        jalr      = 1'b0;
        imm_sel   = 3'b000;
        alu_op    = 2'b00;
        wb_sel    = 2'b00;

        case (opcode)
            7'b0110011: begin // OP: register-register arithmetic/logical
                reg_write = 1'b1;
                alu_op    = 2'b01;
            end
            7'b0010011: begin // OP-IMM: immediate arithmetic/logical
                reg_write = 1'b1;
                alu_src   = 1'b1;
                imm_sel   = 3'b000;
                alu_op    = 2'b01;
            end
            7'b0000011: begin // LOAD (LB, LH, LW, LBU, LHU)
                reg_write = 1'b1;
                mem_read  = 1'b1;
                alu_src   = 1'b1;
                imm_sel   = 3'b000;
                wb_sel    = 2'b01;
            end
            7'b0100011: begin // STORE (SB, SH, SW)
                mem_write = 1'b1;
                alu_src   = 1'b1;
                imm_sel   = 3'b001;
            end
            7'b1100011: begin // Conditional branches
                branch  = 1'b1;
                imm_sel = 3'b010;
                alu_op  = 2'b10;
            end
            7'b0110111: begin // LUI
                reg_write = 1'b1;
                alu_src   = 1'b1;
                imm_sel   = 3'b011;
                alu_op    = 2'b11;
            end
            7'b0010111: begin // AUIPC = PC + U-immediate
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_a_sel = 1'b1;
                imm_sel   = 3'b011;
            end
            7'b1101111: begin // JAL
                reg_write = 1'b1;
                jump      = 1'b1;
                imm_sel   = 3'b100;
                wb_sel    = 2'b10;
            end
            7'b1100111: begin // JALR
                reg_write = 1'b1;
                jump      = 1'b1;
                jalr      = 1'b1;
                alu_src   = 1'b1;
                imm_sel   = 3'b000;
                wb_sel    = 2'b10;
            end
            default: begin
                // NOP / unsupported instruction: all control signals stay deasserted.
            end
        endcase
    end
endmodule
