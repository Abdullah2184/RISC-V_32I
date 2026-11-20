`timescale 1ns/1ps

// Basic single-cycle RV32I processor.
// One instruction is completed per clock cycle (combinational execute path).
module riscv_single_cycle #(
    parameter IMEM_WORDS     = 256,
    parameter DMEM_BYTES     = 4096,
    parameter IMEM_INIT_FILE = ""
) (
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] pc_out,
    output wire [31:0] instruction_out
);
    reg [31:0] pc;
    assign pc_out = pc;

    wire [31:0] instruction;
    assign instruction_out = instruction;

    wire [6:0] opcode = instruction[6:0];
    wire [4:0] rd     = instruction[11:7];
    wire [2:0] funct3 = instruction[14:12];
    wire [4:0] rs1    = instruction[19:15];
    wire [4:0] rs2    = instruction[24:20];
    wire [6:0] funct7 = instruction[31:25];

    wire        reg_write;
    wire        mem_read;
    wire        mem_write_control;
    wire        alu_src;
    wire        alu_a_sel;
    wire        branch;
    wire        jump;
    wire        jalr;
    wire [2:0]  imm_sel;
    wire [1:0]  alu_op;
    wire [1:0]  wb_sel;

    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] immediate;
    wire [31:0] alu_a;
    wire [31:0] alu_b;
    wire [31:0] alu_result;
    wire [3:0]  alu_ctrl;
    wire [31:0] data_read;
    wire [31:0] writeback_data;
    wire        branch_taken;

    wire [31:0] pc_plus4 = pc + 32'd4;
    wire [31:0] branch_target = pc + immediate;
    wire [31:0] jalr_target = (rs1_data + immediate) & 32'hFFFFFFFE;
    wire [31:0] next_pc;

    instruction_mem #(
        .DEPTH_WORDS(IMEM_WORDS),
        .INIT_FILE(IMEM_INIT_FILE)
    ) imem (
        .address(pc),
        .instruction(instruction)
    );

    control_unit control (
        .opcode(opcode),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write_control),
        .alu_src(alu_src),
        .alu_a_sel(alu_a_sel),
        .branch(branch),
        .jump(jump),
        .jalr(jalr),
        .imm_sel(imm_sel),
        .alu_op(alu_op),
        .wb_sel(wb_sel)
    );

    reg_file rf (
        .clk(clk),
        .reset(reset),
        .write_enable(reg_write && !reset),
        .read_addr1(rs1),
        .read_addr2(rs2),
        .write_addr(rd),
        .write_data(writeback_data),
        .read_data1(rs1_data),
        .read_data2(rs2_data)
    );

    imm_generator imm_gen (
        .instruction(instruction),
        .imm_sel(imm_sel),
        .immediate(immediate)
    );

    assign alu_a = alu_a_sel ? pc : rs1_data;
    assign alu_b = alu_src ? immediate : rs2_data;

    alu_control alu_ctrl_unit (
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7(funct7),
        .is_r_type(opcode == 7'b0110011),
        .alu_ctrl(alu_ctrl)
    );

    alu alu_unit (
        .a(alu_a),
        .b(alu_b),
        .alu_ctrl(alu_ctrl),
        .result(alu_result)
    );

    data_mem #(
        .DEPTH_BYTES(DMEM_BYTES)
    ) dmem (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write_control && !reset),
        .address(alu_result),
        .write_data(rs2_data),
        .funct3(funct3),
        .read_data(data_read)
    );

    branch_unit branch_check (
        .funct3(funct3),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .branch_taken(branch_taken)
    );

    // Write-back selection.
    assign writeback_data = (wb_sel == 2'b01) ? data_read :
                            (wb_sel == 2'b10) ? pc_plus4 : alu_result;

    // PC selection priority: JALR, JAL, taken conditional branch, PC+4.
    assign next_pc = jalr ? jalr_target :
                     jump ? branch_target :
                     (branch && branch_taken) ? branch_target : pc_plus4;

    always @(posedge clk) begin
        if (reset)
            pc <= 32'd0;
        else
            pc <= next_pc;
    end
endmodule
