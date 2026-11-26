`timescale 1ns/1ps
module tb_riscv_single_cycle;
    reg clk, reset;
    wire [31:0] pc_out, instruction_out;

    riscv_single_cycle #(.IMEM_WORDS(64), .DMEM_BYTES(256)) dut(
        .clk(clk), .reset(reset), .pc_out(pc_out), .instruction_out(instruction_out)
    );

    initial clk=0;
    always #5 clk=~clk;

    integer cycle;

    function [31:0] enc_i;
        input [11:0] imm;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin enc_i = {imm, rs1, funct3, rd, opcode}; end
    endfunction

    function [31:0] enc_r;
        input [6:0] funct7;
        input [4:0] rs2, rs1;
        input [2:0] funct3;
        input [4:0] rd;
        begin enc_r = {funct7, rs2, rs1, funct3, rd, 7'b0110011}; end
    endfunction

    function [31:0] enc_s;
        input [11:0] imm;
        input [4:0] rs2, rs1;
        input [2:0] funct3;
        begin enc_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], 7'b0100011}; end
    endfunction

    function [31:0] enc_b;
        input [12:0] imm;
        input [4:0] rs2, rs1;
        input [2:0] funct3;
        begin enc_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], 7'b1100011}; end
    endfunction

    function [31:0] enc_u;
        input [19:0] imm;
        input [4:0] rd;
        input [6:0] opcode;
        begin enc_u = {imm, rd, opcode}; end
    endfunction

    task check_reg;
        input [4:0] index;
        input [31:0] expected;
        begin
            if (dut.rf.regs[index] !== expected)
                $fatal(1, "x%0d expected %h, got %h", index, expected, dut.rf.regs[index]);
        end
    endtask

    initial begin
        #1; // Allow instruction_mem initialisation to finish before loading this test program.
        // Program:
        // 0:  addi x1,x0,5
        // 4:  addi x2,x0,7
        // 8:  add  x3,x1,x2          -> x3=12
        // 12: sw   x3,0(x0)
        // 16: lw   x4,0(x0)          -> x4=12
        // 20: beq  x3,x4,+8          -> skip PC 24
        // 24: addi x5,x0,99          (must be skipped)
        // 28: addi x5,x0,42
        // 32: jal  x6,+8             -> skip PC 36, x6=36
        // 36: addi x7,x0,99          (must be skipped)
        // 40: addi x7,x0,11
        // 44: addi x9,x0,52
        // 48: jalr x8,0(x9)          -> x8=52, PC=52
        // 52: addi x10,x0,77
        // 56: nop                     (continued below)
        dut.imem.mem[0]  = 32'h00500093;
        dut.imem.mem[1]  = 32'h00700113;
        dut.imem.mem[2]  = 32'h002081B3;
        dut.imem.mem[3]  = 32'h00302023;
        dut.imem.mem[4]  = 32'h00002203;
        dut.imem.mem[5]  = 32'h00418463;
        dut.imem.mem[6]  = 32'h06300293;
        dut.imem.mem[7]  = 32'h02A00293;
        dut.imem.mem[8]  = 32'h0080036F;
        dut.imem.mem[9]  = 32'h06300393;
        dut.imem.mem[10] = 32'h00B00393;
        dut.imem.mem[11] = 32'h03400493;
        dut.imem.mem[12] = 32'h00048467;
        dut.imem.mem[13] = 32'h04D00513;
        dut.imem.mem[14] = 32'h00000013;

        // Additional ALU, branch, upper-immediate, and memory coverage.
        dut.imem.mem[15] = enc_i(12'hFFF, 0, 3'b000, 11, 7'b0010011); // addi x11,x0,-1
        dut.imem.mem[16] = enc_i(12'h001, 0, 3'b000, 12, 7'b0010011); // addi x12,x0,1
        dut.imem.mem[17] = enc_r(7'b0000000, 12, 11, 3'b010, 13); // slt -> 1
        dut.imem.mem[18] = enc_r(7'b0000000, 12, 11, 3'b011, 14); // sltu -> 0
        dut.imem.mem[19] = enc_r(7'b0000000, 12, 12, 3'b001, 15); // sll -> 2
        dut.imem.mem[20] = enc_r(7'b0000000, 12, 11, 3'b101, 16); // srl -> 7fffffff
        dut.imem.mem[21] = enc_r(7'b0100000, 12, 11, 3'b101, 17); // sra -> ffffffff
        dut.imem.mem[22] = enc_r(7'b0000000, 12, 11, 3'b100, 18); // xor -> fffffffe
        dut.imem.mem[23] = enc_r(7'b0000000, 12, 11, 3'b110, 19); // or -> ffffffff
        dut.imem.mem[24] = enc_r(7'b0000000, 12, 11, 3'b111, 20); // and -> 1
        dut.imem.mem[25] = enc_r(7'b0100000, 11, 12, 3'b000, 21); // sub -> 2
        dut.imem.mem[26] = enc_i(12'h000, 11, 3'b010, 22, 7'b0010011); // slti -> 1
        dut.imem.mem[27] = enc_i(12'h001, 11, 3'b011, 23, 7'b0010011); // sltiu -> 0
        dut.imem.mem[28] = enc_i(12'h01F, 12, 3'b001, 24, 7'b0010011); // slli -> 80000000
        dut.imem.mem[29] = enc_i(12'h01F, 11, 3'b101, 25, 7'b0010011); // srli -> 1
        dut.imem.mem[30] = enc_i(12'h401, 11, 3'b101, 26, 7'b0010011); // srai -> ffffffff
        dut.imem.mem[31] = enc_b(13'd8, 12, 11, 3'b001); // bne taken
        dut.imem.mem[32] = enc_i(12'd99, 0, 3'b000, 27, 7'b0010011); // skipped
        dut.imem.mem[33] = enc_i(12'd42, 0, 3'b000, 27, 7'b0010011);
        dut.imem.mem[34] = enc_b(13'd8, 12, 11, 3'b100); // blt taken
        dut.imem.mem[35] = enc_i(12'd99, 0, 3'b000, 28, 7'b0010011); // skipped
        dut.imem.mem[36] = enc_b(13'd8, 12, 11, 3'b110); // bltu not taken
        dut.imem.mem[37] = enc_i(12'd77, 0, 3'b000, 29, 7'b0010011);
        dut.imem.mem[38] = enc_b(13'd8, 12, 11, 3'b101); // bge not taken
        dut.imem.mem[39] = enc_i(12'd88, 0, 3'b000, 30, 7'b0010011);
        dut.imem.mem[40] = enc_b(13'd8, 12, 11, 3'b111); // bgeu taken
        dut.imem.mem[41] = enc_i(12'd99, 0, 3'b000, 30, 7'b0010011); // skipped
        dut.imem.mem[42] = enc_u(20'h80000, 31, 7'b0110111); // lui -> 80000000
        dut.imem.mem[43] = enc_u(20'h00000, 5, 7'b0010111); // auipc -> current PC
        dut.imem.mem[44] = enc_s(12'd8, 11, 0, 3'b000); // sb
        dut.imem.mem[45] = enc_s(12'd10, 11, 0, 3'b001); // sh
        dut.imem.mem[46] = enc_i(12'd8, 0, 3'b000, 6, 7'b0000011); // lb -> -1
        dut.imem.mem[47] = enc_i(12'd8, 0, 3'b100, 7, 7'b0000011); // lbu -> 255
        dut.imem.mem[48] = enc_i(12'd10, 0, 3'b001, 8, 7'b0000011); // lh -> -1
        dut.imem.mem[49] = enc_i(12'd10, 0, 3'b101, 9, 7'b0000011); // lhu -> 65535
        dut.imem.mem[50] = enc_s(12'd13, 3, 0, 3'b010); // misaligned sw
        dut.imem.mem[51] = enc_i(12'd13, 0, 3'b010, 10, 7'b0000011); // misaligned lw -> 12
        dut.imem.mem[52] = enc_i(12'hFFE, 0, 3'b000, 28, 7'b0010011); // x28 = -2
        dut.imem.mem[53] = enc_s(12'd0, 3, 28, 3'b010); // out-of-range sw must be ignored
        dut.imem.mem[54] = enc_i(12'd0, 28, 3'b010, 6, 7'b0000011); // out-of-range lw -> 0
        dut.imem.mem[55] = enc_i(12'h0F0, 11, 3'b100, 1, 7'b0010011); // xori -> ffffff0f
        dut.imem.mem[56] = enc_i(12'h155, 0, 3'b110, 2, 7'b0010011); // ori -> 155
        dut.imem.mem[57] = enc_i(12'h055, 2, 3'b111, 3, 7'b0010011); // andi -> 55
        dut.imem.mem[58] = enc_i(12'h7FF, 0, 3'b000, 4, 7'b0010011); // largest positive I immediate
        dut.imem.mem[59] = enc_i(12'h800, 0, 3'b000, 5, 7'b0010011); // smallest negative I immediate
        dut.imem.mem[60] = 32'h0000006F; // jal x0,0

        reset=1;
        repeat (2) @(posedge clk);
        @(negedge clk); reset=0;

        for (cycle=0; cycle<65; cycle=cycle+1) begin
            @(posedge clk);
            #1;
            $display("cycle=%0d pc=%h instruction=%h",cycle,pc_out,instruction_out);
            if (cycle == 11) begin
                check_reg(1, 32'd5);
                check_reg(2, 32'd7);
                check_reg(3, 32'd12);
                check_reg(4, 32'd12);
                check_reg(5, 32'd42);  // Original JAL path before AUIPC reuses x5.
                check_reg(6, 32'd36);  // Original JAL link before load tests reuse x6.
                check_reg(7, 32'd11);
                check_reg(8, 32'd52);  // Original JALR link before LH reuses x8.
                check_reg(10, 32'd77);
            end
            if (cycle == 38)
                check_reg(5, 32'd172); // AUIPC result before later immediate-edge test.
        end

        if (dut.dmem.mem[0] !== 8'h0C) begin
            $display("FAIL: Memory byte 0 expected 0C, got %h", dut.dmem.mem[0]);
            $finish;
        end

        check_reg(13, 32'd1);        // signed SLT
        check_reg(14, 32'd0);        // unsigned SLTU
        check_reg(15, 32'd2);        // SLL
        check_reg(16, 32'h7FFFFFFF); // SRL
        check_reg(17, 32'hFFFFFFFF); // SRA
        check_reg(18, 32'hFFFFFFFE); // XOR
        check_reg(19, 32'hFFFFFFFF); // OR
        check_reg(20, 32'd1);        // AND
        check_reg(21, 32'd2);        // SUB
        check_reg(22, 32'd1);        // SLTI
        check_reg(23, 32'd0);        // SLTIU
        check_reg(24, 32'h80000000); // SLLI by maximum shift amount
        check_reg(25, 32'd1);        // SRLI by maximum shift amount
        check_reg(26, 32'hFFFFFFFF); // SRAI
        check_reg(27, 32'd42);       // BNE skipped wrong-path write
        check_reg(29, 32'd77);       // BLTU and BGE fall-through paths
        check_reg(30, 32'd88);       // BGEU taken
        check_reg(31, 32'h80000000); // LUI
        check_reg(28, 32'hFFFFFFFE); // out-of-range address, also probes wrapped bounds arithmetic
        check_reg(6, 32'd0);         // out-of-range load
        check_reg(7, 32'd255);       // LBU
        check_reg(8, 32'hFFFFFFFF); // LH sign extension
        check_reg(9, 32'h0000FFFF); // LHU zero extension
        check_reg(10, 32'd12);       // unaligned LW
        check_reg(1, 32'hFFFFFF0F);  // XORI
        check_reg(2, 32'h00000155);  // ORI
        check_reg(3, 32'h00000055);  // ANDI
        check_reg(4, 32'h000007FF);  // largest positive I immediate
        check_reg(5, 32'hFFFFF800);  // smallest negative I immediate
        if ({dut.dmem.mem[16],dut.dmem.mem[15],dut.dmem.mem[14],dut.dmem.mem[13]} !== 32'd12)
            $fatal(1, "Unaligned SW/LW bytes incorrect: %h %h %h %h",
                   dut.dmem.mem[16], dut.dmem.mem[15], dut.dmem.mem[14], dut.dmem.mem[13]);

        $display("tb_riscv_single_cycle: all integration checks passed");
        $finish;
    end
endmodule
