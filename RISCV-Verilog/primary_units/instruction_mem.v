`timescale 1ns/1ps

module instruction_mem #(
    parameter DEPTH_WORDS = 256,
    parameter INIT_FILE   = ""
) (
    input  wire [31:0] address, // Address requested
    output reg  [31:0] instruction // Instruction at that address
);
    reg [31:0] mem [0:DEPTH_WORDS-1];
    integer i;

    initial begin
        // An uninitialised location behaves as an ADDI x0,x0,0 (NOP).
        for (i = 0; i < DEPTH_WORDS; i = i + 1)
            mem[i] = 32'h00000013;
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, mem);
    end

    always @(*) begin
        if ((address[31:2]) < DEPTH_WORDS)
            instruction = mem[address[31:2]];
        else
            instruction = 32'h00000013;
    end
endmodule
