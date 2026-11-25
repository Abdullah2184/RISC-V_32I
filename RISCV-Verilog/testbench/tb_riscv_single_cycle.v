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
        // 56: jal  x0,0              (loop)
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
        dut.imem.mem[14] = 32'h0000006F;

        reset=1;
        repeat (2) @(posedge clk);
        @(negedge clk); reset=0;

        for (cycle=0; cycle<18; cycle=cycle+1) begin
            @(posedge clk);
            #1;
            $display("cycle=%0d pc=%h instruction=%h",cycle,pc_out,instruction_out);
        end

        if (dut.rf.regs[1]  !== 32'd5) begin
            $display("FAIL: x1 expected 5, got %h", dut.rf.regs[1]);
            $finish;
        end
        if (dut.rf.regs[2]  !== 32'd7) begin
            $display("FAIL: x2 expected 7, got %h", dut.rf.regs[2]);
            $finish;
        end
        if (dut.rf.regs[3]  !== 32'd12) begin
            $display("FAIL: x3 expected 12, got %h", dut.rf.regs[3]);
            $finish;
        end
        if (dut.rf.regs[4]  !== 32'd12) begin
            $display("FAIL: x4 expected 12, got %h", dut.rf.regs[4]);
            $finish;
        end
        if (dut.rf.regs[5]  !== 32'd42) begin
            $display("FAIL: x5 expected 42, got %h", dut.rf.regs[5]);
            $finish;
        end
        if (dut.rf.regs[6]  !== 32'd36) begin
            $display("FAIL: x6 expected 36, got %h", dut.rf.regs[6]);
            $finish;
        end
        if (dut.rf.regs[7]  !== 32'd11) begin
            $display("FAIL: x7 expected 11, got %h", dut.rf.regs[7]);
            $finish;
        end
        if (dut.rf.regs[8]  !== 32'd52) begin
            $display("FAIL: x8 expected 52, got %h", dut.rf.regs[8]);
            $finish;
        end
        if (dut.rf.regs[10] !== 32'd77) begin
            $display("FAIL: x10 expected 77, got %h", dut.rf.regs[10]);
            $finish;
        end
        if (dut.dmem.mem[0] !== 8'h0C) begin
            $display("FAIL: Memory byte 0 expected 0C, got %h", dut.dmem.mem[0]);
            $finish;
        end

        $display("tb_riscv_single_cycle: all integration checks passed");
        $finish;
    end
endmodule
