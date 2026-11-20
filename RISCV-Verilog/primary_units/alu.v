`timescale 1ns/1ps

module alu (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [3:0]  ALUControl,

    output wire [31:0] Result,
    output wire        Zero
);

    // ==========================================
    // ALU CONTROL DECODING (PDF Table 3.8)
    // ==========================================
    // 0000 = ADD
    // 0001 = SUB
    // 0010 = SLL
    // 0011 = SLT
    // 0100 = SLTU
    // 0101 = XOR
    // 0110 = SRL
    // 0111 = SRA
    // 1000 = OR
    // 1001 = AND
    // 1010 = BSEL (pass-through B for LUI)

    wire sel_add;
    wire sel_sub;
    wire sel_sll;
    wire sel_slt;
    wire sel_sltu;
    wire sel_xor;
    wire sel_srl;
    wire sel_sra;
    wire sel_or;
    wire sel_and;
    wire sel_bsel;

    assign sel_add  = (ALUControl == 4'b0000);
    assign sel_sub  = (ALUControl == 4'b0001);
    assign sel_sll  = (ALUControl == 4'b0010);
    assign sel_slt  = (ALUControl == 4'b0011);
    assign sel_sltu = (ALUControl == 4'b0100);
    assign sel_xor  = (ALUControl == 4'b0101);
    assign sel_srl  = (ALUControl == 4'b0110);
    assign sel_sra  = (ALUControl == 4'b0111);
    assign sel_or   = (ALUControl == 4'b1000);
    assign sel_and  = (ALUControl == 4'b1001);
    assign sel_bsel = (ALUControl == 4'b1010);


    // ==========================================
    // SHARED ADDER: ADD, SUB, SLT, SLTU
    // ==========================================

    wire subtract_enable;

    wire [31:0] adder_b;
    wire [31:0] adder_sum;

    wire adder_cout;

    // Subtraction is required for SUB, SLT and SLTU.
    or (subtract_enable, sel_sub, sel_slt, sel_sltu);

    // Invert B when performing subtraction.
    xor B_INVERT (
        adder_b,
        B,
        {32{subtract_enable}}
    );

    // The same 32-bit adder handles all four operations.
    adder_32bit ALU_ADDER (
        .a(A),
        .b(adder_b),
        .cin(subtract_enable),
        .sum(adder_sum),
        .cout(adder_cout)
    );


    // ==========================================
    // SIGNED LESS THAN (SLT)
    // ==========================================

    wire sign_difference;
    wire result_sign_difference;
    wire signed_overflow;
    wire slt_signed;

    xor (sign_difference, A[31], B[31]);

    xor (result_sign_difference, A[31], adder_sum[31]);

    and (signed_overflow, sign_difference, result_sign_difference);

    // Signed comparison accounts for subtraction overflow.
    xor (slt_signed, adder_sum[31], signed_overflow);


    // ==========================================
    // UNSIGNED LESS THAN (SLTU)
    // ==========================================

    wire slt_unsigned;

    // No carry-out means a borrow occurred.
    not (slt_unsigned, adder_cout);


    wire [31:0] slt_result;
    wire [31:0] sltu_result;

    assign slt_result  = {31'b0, slt_signed};
    assign sltu_result = {31'b0, slt_unsigned};


    // ==========================================
    // LOGICAL OPERATIONS
    // ==========================================

    wire [31:0] and_result;
    wire [31:0] or_result;
    wire [31:0] xor_result;

    and AND_GATE (and_result, A, B);
    or  OR_GATE  (or_result, A, B);
    xor XOR_GATE (xor_result, A, B);


    // ==========================================
    // SHIFT OPERATIONS
    // ==========================================

    wire [31:0] shift_result;

    barrel_shifter SHIFT_UNIT (
        .in(A),
        .shamt(B[4:0]),
        .left(sel_sll),
        .arithmetic(sel_sra),
        .out(shift_result)
    );


    // ==========================================
    // OUTPUT SELECTION
    // ==========================================

    wire [31:0] r_arithmetic;
    wire [31:0] r_slt;
    wire [31:0] r_sltu;

    wire [31:0] r_and;
    wire [31:0] r_or;
    wire [31:0] r_xor;

    wire [31:0] r_sll;
    wire [31:0] r_srl;
    wire [31:0] r_sra;
    wire [31:0] r_bsel;

    wire [31:0] result_group1;
    wire [31:0] result_group2;

    // ADD and SUB use the shared adder output.
    and G1 (
        r_arithmetic,
        adder_sum,
        {32{sel_add | sel_sub}}
    );

    and G2  (r_slt,  slt_result,   {32{sel_slt}});
    and G3  (r_sltu, sltu_result,  {32{sel_sltu}});

    and G4  (r_and,  and_result,   {32{sel_and}});
    and G5  (r_or,   or_result,    {32{sel_or}});
    and G6  (r_xor,  xor_result,   {32{sel_xor}});

    and G7  (r_sll,  shift_result, {32{sel_sll}});
    and G8  (r_srl,  shift_result, {32{sel_srl}});
    and G9  (r_sra,  shift_result, {32{sel_sra}});
    and G10 (r_bsel, B,            {32{sel_bsel}});

    or RESULT1 (
        result_group1,
        r_arithmetic,
        r_slt,
        r_sltu,
        r_and,
        r_or
    );

    or RESULT2 (
        result_group2,
        r_xor,
        r_sll,
        r_srl,
        r_sra,
        r_bsel
    );

    or RESULT_FINAL (
        Result,
        result_group1,
        result_group2
    );


    // ==========================================
    // ZERO FLAG
    // ==========================================

    assign Zero = ~|Result;

endmodule