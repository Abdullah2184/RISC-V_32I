module barrel_shifter (
    input  wire [31:0] in,
    input  wire [4:0] shamt,
    input  wire left,
    input  wire arithmetic,
    output wire [31:0] out
);

    wire [31:0] oriented_input;
    wire [31:0] stage [0:5];

    wire fill_bit;

    assign stage[0] = oriented_input;

    // Sign extension for arithmetic right shift.
    // Left shifts and logical right shifts fill with zero.
    assign fill_bit = (~left) & arithmetic & in[31];

    genvar i, s;

    // Reverse input when performing a left shift.
    generate
        for (i = 0; i < 32; i = i + 1) begin : input_orientation

            mux2 MUX (
                .a(in[i]),
                .b(in[31-i]),
                .sel(left),
                .y(oriented_input[i])
            );

        end
    endgenerate

    // Five stages of shifting.
    generate
        for (s = 0; s < 5; s = s + 1) begin : shift_stages

            localparam integer SHIFT = (1 << s);

            for (i = 0; i < 32; i = i + 1) begin : shift_bits

                if ((i + SHIFT) < 32) begin : valid_source

                    mux2 MUX (
                        .a(stage[s][i]),
                        .b(stage[s][i + SHIFT]),
                        .sel(shamt[s]),
                        .y(stage[s+1][i])
                    );

                end
                else begin : fill_source

                    mux2 MUX (
                        .a(stage[s][i]),
                        .b(fill_bit),
                        .sel(shamt[s]),
                        .y(stage[s+1][i])
                    );

                end

            end
        end
    endgenerate

    // Reverse output again when performing a left shift.
    generate
        for (i = 0; i < 32; i = i + 1) begin : output_orientation

            mux2 MUX (
                .a(stage[5][i]),
                .b(stage[5][31-i]),
                .sel(left),
                .y(out[i])
            );

        end
    endgenerate

endmodule