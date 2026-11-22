`timescale 1ns/1ps

module tb_alu_control;

    reg  [1:0] alu_op;
    reg  [2:0] funct3;
    reg  [6:0] funct7;
    reg        is_r_type;
    wire [3:0] alu_ctrl;

    integer errors;

    alu_control DUT (
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7(funct7),
        .is_r_type(is_r_type),
        .alu_ctrl(alu_ctrl)
    );

    task check_ctrl;
        input [1:0] t_op;
        input [2:0] t_f3;
        input [6:0] t_f7;
        input       t_rtype;
        input [3:0] expected;
        begin
            alu_op    = t_op;
            funct3    = t_f3;
            funct7    = t_f7;
            is_r_type = t_rtype;
            #5;
            if (alu_ctrl !== expected) begin
                $display("FAIL: op=%b f3=%b f7=%b rtype=%b | got=%b expected=%b",
                         t_op, t_f3, t_f7, t_rtype, alu_ctrl, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;

        // Fixed ALU_op modes
        check_ctrl(2'b00, 3'b010, 7'b1111111, 1'b0, 4'b0000); // ADD (Load/Store/AUIPC/JAL/JALR)
        check_ctrl(2'b10, 3'b000, 7'b0000000, 1'b0, 4'b0001); // SUB (Branch)
        check_ctrl(2'b11, 3'b111, 7'b1111111, 1'b0, 4'b1010); // BSEL (LUI)

        // R-type instructions (alu_op = 01, is_r_type = 1)
        check_ctrl(2'b01, 3'b000, 7'b0000000, 1'b1, 4'b0000); // ADD
        check_ctrl(2'b01, 3'b000, 7'b0100000, 1'b1, 4'b0001); // SUB
        check_ctrl(2'b01, 3'b001, 7'b0000000, 1'b1, 4'b0010); // SLL
        check_ctrl(2'b01, 3'b010, 7'b0000000, 1'b1, 4'b0011); // SLT
        check_ctrl(2'b01, 3'b011, 7'b0000000, 1'b1, 4'b0100); // SLTU
        check_ctrl(2'b01, 3'b100, 7'b0000000, 1'b1, 4'b0101); // XOR
        check_ctrl(2'b01, 3'b101, 7'b0000000, 1'b1, 4'b0110); // SRL
        check_ctrl(2'b01, 3'b101, 7'b0100000, 1'b1, 4'b0111); // SRA
        check_ctrl(2'b01, 3'b110, 7'b0000000, 1'b1, 4'b1000); // OR
        check_ctrl(2'b01, 3'b111, 7'b0000000, 1'b1, 4'b1001); // AND

        // I-type ALU instructions (alu_op = 01, is_r_type = 0)
        check_ctrl(2'b01, 3'b000, 7'b0000000, 1'b0, 4'b0000); // ADDI (positive imm)
        check_ctrl(2'b01, 3'b000, 7'b1111111, 1'b0, 4'b0000); // ADDI (negative imm, must stay ADD)
        check_ctrl(2'b01, 3'b001, 7'b0000000, 1'b0, 4'b0010); // SLLI
        check_ctrl(2'b01, 3'b010, 7'b1111111, 1'b0, 4'b0011); // SLTI
        check_ctrl(2'b01, 3'b011, 7'b1111111, 1'b0, 4'b0100); // SLTIU
        check_ctrl(2'b01, 3'b100, 7'b1111111, 1'b0, 4'b0101); // XORI
        check_ctrl(2'b01, 3'b101, 7'b0000000, 1'b0, 4'b0110); // SRLI
        check_ctrl(2'b01, 3'b101, 7'b0100000, 1'b0, 4'b0111); // SRAI
        check_ctrl(2'b01, 3'b110, 7'b1111111, 1'b0, 4'b1000); // ORI
        check_ctrl(2'b01, 3'b111, 7'b1111111, 1'b0, 4'b1001); // ANDI

        if (errors == 0)
            $display("ALL tb_alu_control TESTS PASSED!");
        else
            $display("tb_alu_control FAILED with %0d error(s).", errors);

        $finish;
    end

endmodule
