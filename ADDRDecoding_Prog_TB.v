`timescale 1ns/1ps
module ADDRDecoding_Prog_TB;
    reg  [31:0] ADDR_Prog;
    wire        CS_P;
    wire [9:0]  iADDR;

    ADDRDecoding_Prog DUT (.ADDR_Prog(ADDR_Prog), .CS_P(CS_P), .iADDR(iADDR));


    initial begin
        ADDR_Prog = 32'h0900; #1; 
        ADDR_Prog = 32'h0904; #1; 
        ADDR_Prog = 32'h0908; #1; 
        ADDR_Prog = 32'h18FC; #1; 
        ADDR_Prog = 32'h08FC; #1; 
        ADDR_Prog = 32'h1900; #1;
		  
		  $stop;
    end
endmodule
