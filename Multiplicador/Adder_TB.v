`timescale 1ns/1ps
// TestBench do somador 16+16 -> 17 bits.
module Adder_TB;
    reg  [15:0] OperandoA, OperandoB;
    wire [16:0] Soma;
    integer     errors = 0;

    Adder DUT (.OperandoA(OperandoA), .OperandoB(OperandoB), .Soma(Soma));

    task check; input [16:0] exp; begin
        if (Soma !== exp) begin
            $display("FAIL %0d+%0d=%0d (exp %0d)", OperandoA, OperandoB, Soma, exp);
            errors = errors + 1;
        end
    end endtask

    initial begin
        OperandoA=16'd13;    OperandoB=16'd11;    #1; check(17'd24);
        OperandoA=16'hFFFF;  OperandoB=16'h0001;  #1; check(17'h10000); // carry
        OperandoA=16'hFFFF;  OperandoB=16'hFFFF;  #1; check(17'h1FFFE);
        OperandoA=16'd0;     OperandoB=16'd0;     #1; check(17'd0);
        if (errors == 0) $display("Adder_TB: PASS");
        else             $display("Adder_TB: %0d ERRORS", errors);
        $finish;
    end
endmodule
