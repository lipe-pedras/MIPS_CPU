`timescale 1ns/1ps
// TestBench do decodificador de enderecos de programa.
module ADDRDecoding_Prog_TB;
    reg  [31:0] ADDR_Prog;
    wire        CS_P;
    wire [9:0]  iADDR;
    integer     errors = 0;

    ADDRDecoding_Prog DUT (.ADDR_Prog(ADDR_Prog), .CS_P(CS_P), .iADDR(iADDR));

    task check; input expcs; input [9:0] expi; begin
        if (CS_P !== expcs || (expcs && iADDR !== expi)) begin
            $display("FAIL ADDR=%h CS_P=%b(exp %b) iADDR=%0d(exp %0d)",
                     ADDR_Prog, CS_P, expcs, iADDR, expi);
            errors = errors + 1;
        end
    end endtask

    initial begin
        ADDR_Prog = 32'h0900; #1; check(1'b1, 10'd0);    // base -> word 0
        ADDR_Prog = 32'h0904; #1; check(1'b1, 10'd1);    // +4 -> word 1
        ADDR_Prog = 32'h0908; #1; check(1'b1, 10'd2);
        ADDR_Prog = 32'h18FC; #1; check(1'b1, 10'd1023); // ultima palavra
        ADDR_Prog = 32'h08FC; #1; check(1'b0, 10'd0);    // abaixo da faixa
        ADDR_Prog = 32'h1900; #1; check(1'b0, 10'd0);    // acima da faixa
        if (errors == 0) $display("ADDRDecoding_Prog_TB: PASS");
        else             $display("ADDRDecoding_Prog_TB: %0d ERRORS", errors);
        $finish;
    end
endmodule
