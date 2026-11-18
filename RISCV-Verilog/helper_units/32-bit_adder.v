module adder_32bit (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire cin,
    output wire [31:0] sum,
    output wire cout
);

    wire carry1;
    wire carry2;
    wire carry3;

    // Bits 0-7
    adder_8bit ADD0 (
        .a(a[7:0]),
        .b(b[7:0]),
        .cin(cin),
        .sum(sum[7:0]),
        .cout(carry1)
    );

    // Bits 8-15
    adder_8bit ADD1 (
        .a(a[15:8]),
        .b(b[15:8]),
        .cin(carry1),
        .sum(sum[15:8]),
        .cout(carry2)
    );

    // Bits 16-23
    adder_8bit ADD2 (
        .a(a[23:16]),
        .b(b[23:16]),
        .cin(carry2),
        .sum(sum[23:16]),
        .cout(carry3)
    );

    // Bits 24-31
    adder_8bit ADD3 (
        .a(a[31:24]),
        .b(b[31:24]),
        .cin(carry3),
        .sum(sum[31:24]),
        .cout(cout)
    );

endmodule