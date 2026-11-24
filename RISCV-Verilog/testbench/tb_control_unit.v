`timescale 1ns/1ps
module tb_control_unit;
    reg [31:0] instruction;
    reg br_eq, br_lt;
    wire pc_sel, reg_wen, br_un, asel, bsel, mem_rw;
    wire [2:0] imm_sel;
    wire [3:0] alu_sel;
    wire [1:0] wb_sel;

    control_unit dut(
        .instruction(instruction), .br_eq(br_eq), .br_lt(br_lt),
        .pc_sel(pc_sel), .imm_sel(imm_sel), .reg_wen(reg_wen),
        .br_un(br_un), .asel(asel), .bsel(bsel), .alu_sel(alu_sel),
        .mem_rw(mem_rw), .wb_sel(wb_sel)
    );

    task check;
        input [31:0] inst;
        input t_br_eq, t_br_lt;
        input [14:0] expected;
        input [127:0] label;
        begin
            instruction = inst;
            br_eq = t_br_eq;
            br_lt = t_br_lt;
            #1;
            if ({pc_sel,imm_sel,reg_wen,br_un,asel,bsel,alu_sel,mem_rw,wb_sel} !== expected)
                $fatal(1, "Control decode failed: %0s got %b expected %b", label,
                       {pc_sel,imm_sel,reg_wen,br_un,asel,bsel,alu_sel,mem_rw,wb_sel}, expected);
        end
    endtask

    initial begin
        check(32'h002081B3, 0, 0, {1'b0,3'b000,1'b1,1'b0,1'b0,1'b0,4'b0000,1'b0,2'b01}, "R-type ADD");
        check(32'h00002283, 0, 0, {1'b0,3'b000,1'b1,1'b0,1'b0,1'b1,4'b0000,1'b0,2'b00}, "LW");
        check(32'h00302023, 0, 0, {1'b0,3'b001,1'b0,1'b0,1'b0,1'b1,4'b0000,1'b1,2'b00}, "SW");
        check(32'h00208463, 1, 0, {1'b1,3'b010,1'b0,1'b0,1'b1,1'b1,4'b0000,1'b0,2'b00}, "BEQ taken");
        check(32'h00209463, 1, 0, {1'b0,3'b010,1'b0,1'b0,1'b1,1'b1,4'b0000,1'b0,2'b00}, "BNE not taken");
        check(32'h0080036F, 0, 0, {1'b1,3'b100,1'b1,1'b0,1'b1,1'b1,4'b0000,1'b0,2'b10}, "JAL");
        check(32'h12345037, 0, 0, {1'b0,3'b011,1'b1,1'b0,1'b0,1'b1,4'b1010,1'b0,2'b01}, "LUI");
        check(32'hFFFFFFFF, 0, 0, {1'b0,3'b000,1'b0,1'b0,1'b0,1'b0,4'b0000,1'b0,2'b00}, "unknown opcode");
        $display("tb_control_unit: all tests passed");
        $finish;
    end
endmodule
