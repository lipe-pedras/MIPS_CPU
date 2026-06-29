`timescale 1ns/1ps
module mux_TB;
    reg         sel;
    reg  [31:0] in0, in1;
    wire [31:0] out;

    mux #(.WIDTH(32)) DUT (.sel(sel), .in0(in0), .in1(in1), .out(out));

    initial begin
        in0 = 32'hAAAAAAAA; in1 = 32'h55555555;
        
        sel = 0; #1; 
        sel = 1; #1; 
		  
        $stop;
    end
endmodule
