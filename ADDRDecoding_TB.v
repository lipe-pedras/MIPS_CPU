`timescale 1ns/1ps
// TestBench do decodificador de enderecos de dados.
module ADDRDecoding_TB;
    reg  [31:0] D;
    reg         we;
    wire        CS, iWE, WE;
    wire [31:0] internalAddress, ADDR;
    wire [9:0]  iAddress;
    integer     errors = 0;

    ADDRDecoding DUT (.D(D), .we(we), .CS(CS), .internalAddress(internalAddress),
                      .iAddress(iAddress), .iWE(iWE), .WE(WE), .ADDR(ADDR));

    task check; input expcs; input [9:0] expi; input expiwe; input expwe; begin
        if (CS!==expcs || iWE!==expiwe || WE!==expwe || (expcs && iAddress!==expi)) begin
            $display("FAIL D=%h we=%b CS=%b iAddr=%0d iWE=%b WE=%b",
                     D, we, CS, iAddress, iWE, WE);
            errors = errors + 1;
        end
    end endtask

    initial begin
        // dentro da faixa de dados, leitura
        D = 32'h1500; we = 0; #1; check(1'b1, 10'd0, 1'b0, 1'b0);
        D = 32'h1501; we = 0; #1; check(1'b1, 10'd1, 1'b0, 1'b0);
        D = 32'h18FF; we = 0; #1; check(1'b1, 10'd1023, 1'b0, 1'b0);
        // dentro da faixa, escrita -> iWE
        D = 32'h1502; we = 1; #1; check(1'b1, 10'd2, 1'b1, 1'b0);
        // fora da faixa, escrita -> WE externo
        D = 32'h2000; we = 1; #1; check(1'b0, 10'd0, 1'b0, 1'b1);
        // fora da faixa, leitura
        D = 32'h0100; we = 0; #1; check(1'b0, 10'd0, 1'b0, 1'b0);
        if (errors == 0) $display("ADDRDecoding_TB: PASS");
        else             $display("ADDRDecoding_TB: %0d ERRORS", errors);
        $finish;
    end
endmodule
