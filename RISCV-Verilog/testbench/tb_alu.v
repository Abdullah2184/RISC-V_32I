`timescale 1ns/1ps

module tb_alu;

    reg [31:0] A;
    reg [31:0] B;
    reg [3:0] ALUControl;

    wire [31:0] Result;
    wire Zero;

    alu DUT (
        .A(A),
        .B(B),
        .ALUControl(ALUControl),
        .Result(Result),
        .Zero(Zero)
    );

    initial begin

        // ADD: 10 + 5 = 15
        A = 32'd10;
        B = 32'd5;
        ALUControl = 4'b0000;
        #10;
        $display("ADD: %d", Result);


        // SUB: 10 - 5 = 5
        A = 32'd10;
        B = 32'd5;
        ALUControl = 4'b0001;
        #10;
        $display("SUB: %d", Result);


        // AND
        A = 32'h0000000F;
        B = 32'h00000003;
        ALUControl = 4'b0010;
        #10;
        $display("AND: %h", Result);


        // OR
        A = 32'h0000000F;
        B = 32'h00000003;
        ALUControl = 4'b0011;
        #10;
        $display("OR: %h", Result);


        // XOR
        A = 32'h0000000F;
        B = 32'h00000003;
        ALUControl = 4'b0100;
        #10;
        $display("XOR: %h", Result);


        // SLT: -5 < 3 (signed)
        A = 32'hFFFFFFFB;
        B = 32'd3;
        ALUControl = 4'b0101;
        #10;
        $display("SLT: %d", Result);


        // SLTU: 5 < 7 (unsigned)
        A = 32'd5;
        B = 32'd7;
        ALUControl = 4'b0110;
        #10;
        $display("SLTU: %d", Result);


        // SLL: 1 << 2 = 4
        A = 32'd1;
        B = 32'd2;
        ALUControl = 4'b0111;
        #10;
        $display("SLL: %d", Result);


        // SRL: 16 >> 2 = 4
        A = 32'd16;
        B = 32'd2;
        ALUControl = 4'b1000;
        #10;
        $display("SRL: %d", Result);


        // SRA: -16 >>> 2 = -4
        A = 32'hFFFFFFF0;
        B = 32'd2;
        ALUControl = 4'b1001;
        #10;
        $display("SRA: %d", $signed(Result));


        $finish;

    end

endmodule