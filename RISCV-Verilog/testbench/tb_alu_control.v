`timescale 1ns/1ps
module tb_alu_control;
    reg [1:0] alu_op;
    reg [2:0] funct3;
    reg [6:0] funct7;
    reg is_r_type;
    wire [3:0] alu_ctrl;

    alu_control dut(.alu_op(alu_op), .funct3(funct3), .funct7(funct7), .is_r_type(is_r_type), .alu_ctrl(alu_ctrl));

    task check;
        input [3:0] expected;
        input [127:0] label;
        begin
            #1;
            if (alu_ctrl !== expected)
                $fatal(1, "ALU control %0s failed: got %b expected %b", label, alu_ctrl, expected);
            else $display("PASS ALU control: %0s", label);
        end
    endtask

    initial begin
        alu_op=2'b00; funct3=0; funct7=0; is_r_type=0; check(4'b0000,"load/store/add default");
        alu_op=2'b10; check(4'b0001,"branch subtract");
        alu_op=2'b11; check(4'b1010,"LUI pass B");
        alu_op=2'b01; funct3=3'b000; funct7=7'b0100000; is_r_type=1; check(4'b0001,"SUB");
        is_r_type=0; check(4'b0000,"ADDI with immediate bits resembling SUB");
        is_r_type=1;
        funct7=0; check(4'b0000,"ADD");
        funct3=3'b001; check(4'b0101,"SLL");
        funct3=3'b010; check(4'b1000,"SLT");
        funct3=3'b011; check(4'b1001,"SLTU");
        funct3=3'b100; check(4'b0100,"XOR");
        funct3=3'b101; check(4'b0110,"SRL");
        funct7=7'b0100000; check(4'b0111,"SRA");
        funct3=3'b110; check(4'b0011,"OR");
        funct3=3'b111; check(4'b0010,"AND");
        $display("tb_alu_control: all tests passed");
        $finish;
    end
`timescale 1ns/1ps
module tb_alu_control;
    reg [1:0] alu_op;
    reg [2:0] funct3;
    reg [6:0] funct7;
    reg is_r_type;
    wire [3:0] alu_ctrl;

    alu_control dut(.alu_op(alu_op), .funct3(funct3), .funct7(funct7), .is_r_type(is_r_type), .alu_ctrl(alu_ctrl));

    task check;
        input [3:0] expected;
        input [127:0] label;
        begin
            #1;
            if (alu_ctrl !== expected)
                $fatal(1, "ALU control %0s failed: got %b expected %b", label, alu_ctrl, expected);
            else $display("PASS ALU control: %0s", label);
        end
    endtask

    initial begin
        alu_op=2'b00; funct3=0; funct7=0; is_r_type=0; check(4'b0000,"load/store/add default");
        alu_op=2'b10; check(4'b0001,"branch subtract");
        alu_op=2'b11; check(4'b1010,"LUI pass B");
        alu_op=2'b01; funct3=3'b000; funct7=7'b0100000; is_r_type=1; check(4'b0001,"SUB");
        is_r_type=0; check(4'b0000,"ADDI with immediate bits resembling SUB");
        is_r_type=1;
        funct7=0; check(4'b0000,"ADD");
        funct3=3'b001; check(4'b0010,"SLL");
        funct3=3'b010; check(4'b0011,"SLT");
        funct3=3'b011; check(4'b0100,"SLTU");
        funct3=3'b100; check(4'b0101,"XOR");
        funct3=3'b101; check(4'b0110,"SRL");
        funct7=7'b0100000; check(4'b0111,"SRA");
        funct3=3'b110; check(4'b1000,"OR");
        funct3=3'b111; check(4'b1001,"AND");
        $display("tb_alu_control: all tests passed");
        $finish;
    end
endmodule
