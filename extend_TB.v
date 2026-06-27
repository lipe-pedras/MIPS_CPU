`timescale 1ns/1ps
// TestBench do extensor de sinal.
module extend_TB;
    reg  [31:0] INST;
    wire [31:0] SignExtImm;
    integer     errors = 0;

    extend DUT (.INST(INST), .SignExtImm(SignExtImm));

    task check; input [31:0] exp; begin
        if (SignExtImm !== exp) begin
            $display("FAIL INST=%h -> %h (exp %h)", INST, SignExtImm, exp);
            errors = errors + 1;
        end
    end endtask

    initial begin
        INST = 32'h0000_0001; #1; check(32'h0000_0001); // +1
        INST = 32'h0000_7FFF; #1; check(32'h0000_7FFF); // maior positivo
        INST = 32'h0000_FFFF; #1; check(32'hFFFF_FFFF); // -1
        INST = 32'h0000_8000; #1; check(32'hFFFF_8000); // menor negativo
        INST = 32'hAAAA_1234; #1; check(32'h0000_1234); // ignora bits altos
        if (errors == 0) $display("extend_TB: PASS");
        else             $display("extend_TB: %0d ERRORS", errors);
        $finish;
    end
endmodule
