`timescale 1ns/1ps

module control_unit (
    input  wire [31:0] instruction,
    input  wire        br_eq,
    input  wire        br_lt,
    output reg         pc_sel,
    output reg  [2:0]  imm_sel,
    output reg         reg_wen,
    output reg         br_un,
    output reg         asel,
    output reg         bsel,
    output reg  [3:0]  alu_sel,
    output reg         mem_rw,
    output reg  [1:0]  wb_sel
);
    wire [6:0] opcode   = instruction[6:0];
    wire [2:0] funct3   = instruction[14:12];
    wire       funct7_5 = instruction[30];

    always @(*) begin
        // Safe defaults
        pc_sel  = 1'b0;
        imm_sel = 3'b000;
        reg_wen = 1'b0;
        br_un   = 1'b0;
        asel    = 1'b0;
        bsel    = 1'b0;
        alu_sel = 4'b0000;
        mem_rw  = 1'b0;
        wb_sel  = 2'b00;

        case (opcode)
            7'b0110011: begin // R-type: ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
                reg_wen = 1'b1;
                asel    = 1'b0;
                bsel    = 1'b0;
                wb_sel  = 2'b01; // alu
                case (funct3)
                    3'b000: alu_sel = funct7_5 ? 4'b0001 : 4'b0000; // SUB : ADD
                    3'b001: alu_sel = 4'b0010;                      // SLL
                    3'b010: alu_sel = 4'b0011;                      // SLT
                    3'b011: alu_sel = 4'b0100;                      // SLTU
                    3'b100: alu_sel = 4'b0101;                      // XOR
                    3'b101: alu_sel = funct7_5 ? 4'b0111 : 4'b0110; // SRA : SRL
                    3'b110: alu_sel = 4'b1000;                      // OR
                    3'b111: alu_sel = 4'b1001;                      // AND
                endcase
            end

            7'b0010011: begin // I-type ALU: ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
                imm_sel = 3'b000; // I
                reg_wen = 1'b1;
                asel    = 1'b0;
                bsel    = 1'b1;   // Imm
                wb_sel  = 2'b01;  // alu
                case (funct3)
                    3'b000: alu_sel = 4'b0000;                      // ADDI
                    3'b001: alu_sel = 4'b0010;                      // SLLI
                    3'b010: alu_sel = 4'b0011;                      // SLTI
                    3'b011: alu_sel = 4'b0100;                      // SLTIU
                    3'b100: alu_sel = 4'b0101;                      // XORI
                    3'b101: alu_sel = funct7_5 ? 4'b0111 : 4'b0110; // SRAI : SRLI
                    3'b110: alu_sel = 4'b1000;                      // ORI
                    3'b111: alu_sel = 4'b1001;                      // ANDI
                endcase
            end

            7'b0000011: begin // Load: LB, LH, LW, LBU, LHU
                imm_sel = 3'b000; // I
                reg_wen = 1'b1;
                asel    = 1'b0;
                bsel    = 1'b1;   // Imm
                alu_sel = 4'b0000; // ADD
                mem_rw  = 1'b0;
                wb_sel  = 2'b00;  // mem
            end

            7'b0100011: begin // Store: SB, SH, SW
                imm_sel = 3'b001; // S
                reg_wen = 1'b0;
                asel    = 1'b0;
                bsel    = 1'b1;   // Imm
                alu_sel = 4'b0000; // ADD
                mem_rw  = 1'b1;
            end

            7'b1100011: begin // Branch: BEQ, BNE, BLT, BGE, BLTU, BGEU
                imm_sel = 3'b010; // B
                reg_wen = 1'b0;
                asel    = 1'b1;   // pc
                bsel    = 1'b1;   // Imm
                alu_sel = 4'b0000; // ADD (PC + Imm)
                mem_rw  = 1'b0;
                case (funct3)
                    3'b000: begin br_un = 1'b0; pc_sel = br_eq;  end // BEQ
                    3'b001: begin br_un = 1'b0; pc_sel = ~br_eq; end // BNE
                    3'b100: begin br_un = 1'b0; pc_sel = br_lt;  end // BLT
                    3'b101: begin br_un = 1'b0; pc_sel = ~br_lt; end // BGE
                    3'b110: begin br_un = 1'b1; pc_sel = br_lt;  end // BLTU
                    3'b111: begin br_un = 1'b1; pc_sel = ~br_lt; end // BGEU
                    default: begin br_un = 1'b0; pc_sel = 1'b0;  end
                endcase
            end

            7'b1101111: begin // JAL
                pc_sel  = 1'b1;
                imm_sel = 3'b100; // J
                reg_wen = 1'b1;
                asel    = 1'b1;   // pc
                bsel    = 1'b1;   // Imm
                alu_sel = 4'b0000; // ADD
                mem_rw  = 1'b0;
                wb_sel  = 2'b10;  // pc + 4
            end

            7'b1100111: begin // JALR
                pc_sel  = 1'b1;
                imm_sel = 3'b000; // I
                reg_wen = 1'b1;
                asel    = 1'b0;   // Reg[rs1]
                bsel    = 1'b1;   // Imm
                alu_sel = 4'b0000; // ADD
                mem_rw  = 1'b0;
                wb_sel  = 2'b10;  // pc + 4
            end

            7'b0110111: begin // LUI
                pc_sel  = 1'b0;
                imm_sel = 3'b011; // U
                reg_wen = 1'b1;
                bsel    = 1'b1;   // Imm
                alu_sel = 4'b1010; // BSEL
                mem_rw  = 1'b0;
                wb_sel  = 2'b01;  // alu
            end

            7'b0010111: begin // AUIPC
                pc_sel  = 1'b0;
                imm_sel = 3'b011; // U
                reg_wen = 1'b1;
                asel    = 1'b1;   // pc
                bsel    = 1'b1;   // Imm
                alu_sel = 4'b0000; // ADD
                mem_rw  = 1'b0;
                wb_sel  = 2'b01;  // alu
            end

            default: begin
                // Unsupported / NOP: all outputs remain at safe deasserted defaults
            end
        endcase
    end
endmodule
