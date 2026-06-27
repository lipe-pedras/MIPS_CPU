`timescale 1ns/1ps
// TestBench do acumulador 33 bits: Load, Ad, Sh, reset.
module ACC_TB;
    reg         Load, Sh, Ad, Clk, rst;
    reg  [32:0] Entradas;
    wire [32:0] Saidas;
    integer     errors = 0;

    ACC DUT (.Load(Load), .Sh(Sh), .Ad(Ad), .Clk(Clk), .rst(rst),
             .Entradas(Entradas), .Saidas(Saidas));

    always #5 Clk = ~Clk;

    task check; input [32:0] exp; begin
        if (Saidas !== exp) begin
            $display("FAIL Saidas=%h exp=%h", Saidas, exp);
            errors = errors + 1;
        end
    end endtask

    initial begin
        Clk=0; rst=1; Load=0; Sh=0; Ad=0; Entradas=0;
        #12 rst=0;
        // Load: carrega Entradas[15:0] nos bits baixos
        Entradas = {17'b0, 16'hABCD}; Load=1; @(negedge Clk); Load=0;
        check(33'h0000_ABCD);
        // Ad: Entradas[32:16] vai para Saidas[32:16]
        Entradas = {17'h0_0011, 16'h0000}; Ad=1; @(negedge Clk); Ad=0;
        check({17'h00011, 16'hABCD});
        // Sh: deslocamento a direita
        Sh=1; @(negedge Clk); Sh=0;
        check({17'h00011, 16'hABCD} >> 1);
        // reset assincrono
        rst=1; #1; check(33'h0);
        if (errors == 0) $display("ACC_TB: PASS");
        else             $display("ACC_TB: %0d ERRORS", errors);
        $finish;
    end
endmodule
