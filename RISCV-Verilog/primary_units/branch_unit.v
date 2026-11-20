`timescale 1ns/1ps

module branch_unit (
    input  wire [31:0] rs1_data, // A = Reg[rs1]
    input  wire [31:0] rs2_data, // B = Reg[rs2]
    input  wire        br_un,    // BrUn: 1 = unsigned, 0 = signed
    output wire        br_eq,    // BrEq: A == B
    output wire        br_lt     // BrLT: A < B (signed or unsigned per BrUn)
);
    assign br_eq = (rs1_data == rs2_data);
    assign br_lt = br_un ? (rs1_data < rs2_data)
                         : ($signed(rs1_data) < $signed(rs2_data));
endmodule