`timescale 1ns/1ps
module tb_branch_unit;
    reg [31:0] rs1_data, rs2_data; // A, B
    reg br_un;                     // BrUn: 1 = unsigned, 0 = signed
    wire br_eq, br_lt;             // BrEq, BrLT

    branch_unit dut(
        .rs1_data(rs1_data), .rs2_data(rs2_data), .br_un(br_un),
        .br_eq(br_eq), .br_lt(br_lt)
    );

    task check;
        input exp_eq;
        input exp_lt;
        input [255:0] label;
        begin
            #1;
            if ((br_eq !== exp_eq) || (br_lt !== exp_lt))
                $fatal(1, "Branch Comp %0s failed: got (BrEq=%b, BrLT=%b) expected (BrEq=%b, BrLT=%b)",
                       label, br_eq, br_lt, exp_eq, exp_lt);
            else
                $display("PASS Branch Comp: %0s", label);
        end
    endtask

    initial begin
        // Table 6.5: Verification of Branch Comparator
        rs1_data = 32'h00000005; rs2_data = 32'h00000005; br_un = 1'b0; check(1'b1, 1'b0, "Equal (5 == 5)");
        rs1_data = 32'hFFFFFFFF; rs2_data = 32'h00000001; br_un = 1'b0; check(1'b0, 1'b1, "Signed: -1 < 1");
        rs1_data = 32'hFFFFFFFF; rs2_data = 32'h00000001; br_un = 1'b1; check(1'b0, 1'b0, "Unsigned: 4294967295 > 1");
        rs1_data = 32'h00000002; rs2_data = 32'h00000009; br_un = 1'b0; check(1'b0, 1'b1, "2 < 9");

        $display("tb_branch_unit: all tests passed");
        $finish;
    end
endmodule
