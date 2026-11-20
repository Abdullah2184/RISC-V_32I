`timescale 1ns/1ps
module tb_branch_unit;
    reg [2:0] funct3;
    reg [31:0] rs1_data, rs2_data;
    wire branch_taken;

    branch_unit dut(
        .funct3(funct3), .rs1_data(rs1_data), .rs2_data(rs2_data), .branch_taken(branch_taken)
    );

    task check;
        input expected;
        input [127:0] label;
        begin
            #1;
            if (branch_taken !== expected)
                $fatal(1,"Branch %0s failed: got %b expected %b",label,branch_taken,expected);
            else $display("PASS branch: %0s",label);
        end
    endtask

    initial begin
        rs1_data=32'd5; rs2_data=32'd5;
        funct3=3'b000; check(1,"BEQ true");
        funct3=3'b001; check(0,"BNE false");
        rs1_data=32'hFFFFFFFF; rs2_data=32'd1;
        funct3=3'b100; check(1,"BLT signed");
        funct3=3'b101; check(0,"BGE signed");
        funct3=3'b110; check(0,"BLTU unsigned");
        funct3=3'b111; check(1,"BGEU unsigned");
        $display("tb_branch_unit: all tests passed");
        $finish;
    end
endmodule
