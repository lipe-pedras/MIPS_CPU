`timescale 1ns/1ps
// TestBench da ALU: cobre ADD/SUB/AND/OR e o zeroFlag.
module alu_TB;
    reg  [31:0] A, B;
    reg  [2:0]  aluControl;
    wire [31:0] result;
    wire        zeroFlag;

    alu #(.WIDTH(32)) DUT (.A(A), .B(B), .aluControl(aluControl),
                           .result(result), .zeroFlag(zeroFlag));

    

    initial begin
        A = 32'd10; B = 32'd5;
        aluControl = 3'b000; #1;  // ADD
        aluControl = 3'b001; #1;  // SUB
        aluControl = 3'b010; #1;  // AND
        aluControl = 3'b011; #1;  // OR
        // igualdade -> zeroFlag
        A = 32'h1234; B = 32'h1234;
        aluControl = 3'b001; #1; 
        // negativo (sub que estoura)
        A = 32'd3; B = 32'd7;
        aluControl = 3'b001; #1; // 3-7 = -4
        
		  $stop;
    end
endmodule
