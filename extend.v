
module extend (
    input  [31:0] INST,
    output [31:0] SignExtImm
);
    assign SignExtImm = {{16{INST[15]}}, INST[15:0]};
endmodule
