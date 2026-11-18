module mux2 (
    input  wire a,
    input  wire b,
    input  wire sel,
    output wire y
);

    wire not_sel;
    wire and1;
    wire and2;

    not (not_sel, sel);

    and (and1, a, not_sel);
    and (and2, b, sel);

    or (y, and1, and2);

endmodule