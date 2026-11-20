`timescale 1ns/1ps
module tb_control_unit;
    reg [6:0] opcode;
    wire reg_write, mem_read, mem_write, alu_src, alu_a_sel, branch, jump, jalr;
    wire [2:0] imm_sel;
    wire [1:0] alu_op, wb_sel;

    control_unit dut(
        .opcode(opcode), .reg_write(reg_write), .mem_read(mem_read), .mem_write(mem_write),
        .alu_src(alu_src), .alu_a_sel(alu_a_sel), .branch(branch), .jump(jump), .jalr(jalr),
        .imm_sel(imm_sel), .alu_op(alu_op), .wb_sel(wb_sel)
    );

    task check_control;
        input exp_reg_write, exp_mem_read, exp_mem_write, exp_alu_src;
        input exp_alu_a_sel, exp_branch, exp_jump, exp_jalr;
        input [2:0] exp_imm_sel;
        input [1:0] exp_alu_op, exp_wb_sel;
        input [127:0] label;
        begin
            #1;
            if ({reg_write,mem_read,mem_write,alu_src,alu_a_sel,branch,jump,jalr,imm_sel,alu_op,wb_sel} !==
                {exp_reg_write,exp_mem_read,exp_mem_write,exp_alu_src,exp_alu_a_sel,exp_branch,exp_jump,exp_jalr,exp_imm_sel,exp_alu_op,exp_wb_sel})
                $fatal(1,"Control decode failed: %0s",label);
            else $display("PASS control: %0s",label);
        end
    endtask

    initial begin
        opcode=7'b0110011; check_control(1,0,0,0,0,0,0,0,3'b000,2'b01,2'b00,"R-type");
        opcode=7'b0010011; check_control(1,0,0,1,0,0,0,0,3'b000,2'b01,2'b00,"I arithmetic");
        opcode=7'b0000011; check_control(1,1,0,1,0,0,0,0,3'b000,2'b00,2'b01,"load");
        opcode=7'b0100011; check_control(0,0,1,1,0,0,0,0,3'b001,2'b00,2'b00,"store");
        opcode=7'b1100011; check_control(0,0,0,0,0,1,0,0,3'b010,2'b10,2'b00,"branch");
        opcode=7'b0110111; check_control(1,0,0,1,0,0,0,0,3'b011,2'b11,2'b00,"LUI");
        opcode=7'b0010111; check_control(1,0,0,1,1,0,0,0,3'b011,2'b00,2'b00,"AUIPC");
        opcode=7'b1101111; check_control(1,0,0,0,0,0,1,0,3'b100,2'b00,2'b10,"JAL");
        opcode=7'b1100111; check_control(1,0,0,1,0,0,1,1,3'b000,2'b00,2'b10,"JALR");
        opcode=7'b1111111; check_control(0,0,0,0,0,0,0,0,3'b000,2'b00,2'b00,"unknown opcode");
        $display("tb_control_unit: all tests passed");
        $finish;
    end
endmodule
