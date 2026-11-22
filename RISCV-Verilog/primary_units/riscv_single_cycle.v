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

    wire        pc_sel;
    wire [2:0]  imm_sel;
    wire        reg_wen;
    wire        br_un;
    wire        asel;
    wire        bsel;
    wire [3:0]  alu_sel;
    wire        mem_rw;
    wire [1:0]  wb_sel;

    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] immediate;
    wire [31:0] alu_a;
    wire [31:0] alu_b;
    wire [31:0] alu_result;
    wire [31:0] data_read;
    wire [31:0] writeback_data;

    wire        br_eq = (rs1_data == rs2_data);
    wire        br_lt = br_un ? (rs1_data < rs2_data)
                              : ($signed(rs1_data) < $signed(rs2_data));

    wire [31:0] pc_plus4      = pc + 32'd4;
    wire [31:0] alu_pc_target = (opcode == 7'b1100111) ? (alu_result & 32'hFFFFFFFE)
                                                       : alu_result;
    wire [31:0] next_pc       = pc_sel ? alu_pc_target : pc_plus4;

    instruction_mem #(
        .DEPTH_WORDS(IMEM_WORDS),
        .INIT_FILE(IMEM_INIT_FILE)
    ) imem (
        .address(pc),
        .instruction(instruction)
    );

    control_unit control (
        .instruction(instruction),
        .br_eq(br_eq),
        .br_lt(br_lt),
        .pc_sel(pc_sel),
        .imm_sel(imm_sel),
        .reg_wen(reg_wen),
        .br_un(br_un),
        .asel(asel),
        .bsel(bsel),
        .alu_sel(alu_sel),
        .mem_rw(mem_rw),
        .wb_sel(wb_sel)
    );

    reg_file rf (
        .clk(clk),
        .reset(reset),
        .write_enable(reg_wen && !reset),
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

    assign alu_a = asel ? pc : rs1_data;
    assign alu_b = bsel ? immediate : rs2_data;

    alu alu_unit (
        .A(alu_a),
        .B(alu_b),
        .ALUControl(alu_sel),
        .Result(alu_result),
        .Zero()
    );

    data_mem #(
        .DEPTH_BYTES(DMEM_BYTES)
    ) dmem (
        .clk(clk),
        .mem_rw(mem_rw && !reset),
        .address(alu_result),
        .write_data(rs2_data),
        .funct3(funct3),
        .read_data(data_read)
    );

    // Write-back selection (control_unit wb_sel: 00 = mem, 01 = alu, 10 = pc+4).
    assign writeback_data = (wb_sel == 2'b00) ? data_read :
                            (wb_sel == 2'b10) ? pc_plus4  : alu_result;

    always @(posedge clk) begin
        if (reset)
            pc <= 32'd0;
        else
            pc <= next_pc;
    end
endmodule
