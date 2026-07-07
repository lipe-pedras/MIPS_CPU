`timescale 1ns/1ps
module extend_TB;
    reg  [31:0] INST;
    wire [31:0] SignExtImm;

    extend DUT (.INST(INST), .SignExtImm(SignExtImm));

    initial begin
        INST = 32'h0000_0001; #1;
        INST = 32'h0000_7FFF; #1;
        INST = 32'h0000_FFFF; #1;
        INST = 32'h0000_8000; #1;
        INST = 32'hAAAA_1234; #1;
        
		  $stop;
    end
endmodule
