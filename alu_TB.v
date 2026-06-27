`timescale 1ns/1ps
// TestBench da ALU: cobre ADD/SUB/AND/OR e o zeroFlag.
module alu_TB;
    reg  [31:0] A, B;
    reg  [2:0]  aluControl;
    wire [31:0] result;
    wire        zeroFlag;
    integer     errors = 0;

    alu #(.WIDTH(32)) DUT (.A(A), .B(B), .aluControl(aluControl),
                           .result(result), .zeroFlag(zeroFlag));

    task check; input [31:0] exp; input expz; begin
        if (result !== exp || zeroFlag !== expz) begin
            $display("FAIL ctrl=%b A=%h B=%h -> res=%h(exp %h) z=%b(exp %b)",
                     aluControl, A, B, result, exp, zeroFlag, expz);
            errors = errors + 1;
        end
    end endtask

    initial begin
        A = 32'd10; B = 32'd5;
        aluControl = 3'b000; #1; check(32'd15, 1'b0);   // ADD
        aluControl = 3'b001; #1; check(32'd5,  1'b0);   // SUB
        aluControl = 3'b010; #1; check(32'd10 & 32'd5, 1'b0); // AND
        aluControl = 3'b011; #1; check(32'd10 | 32'd5, 1'b0); // OR
        // igualdade -> zeroFlag
        A = 32'h1234; B = 32'h1234;
        aluControl = 3'b001; #1; check(32'h0, 1'b1);
        // negativo (sub que estoura)
        A = 32'd3; B = 32'd7;
        aluControl = 3'b001; #1; check(32'hFFFFFFFC, 1'b0); // 3-7 = -4
        if (errors == 0) $display("alu_TB: PASS");
        else             $display("alu_TB: %0d ERRORS", errors);
        $finish;
    end
endmodule
