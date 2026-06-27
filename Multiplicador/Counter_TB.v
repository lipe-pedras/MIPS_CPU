`timescale 1ns/1ps
// TestBench do contador: K em counter==30, reinicio em Load, reset.
module Counter_TB;
    reg     Load, Clk, rst;
    wire    K;
    integer errors = 0;
    integer kcount;

    Counter DUT (.Load(Load), .Clk(Clk), .rst(rst), .K(K));

    always #5 Clk = ~Clk;

    initial begin
        Clk=0; rst=1; Load=0;
        #12 rst=0;
        // pulso de Load reinicia o contador
        Load=1; @(negedge Clk); Load=0;
        // conta livremente; K deve subir 1x quando counter passar por 30 (apos 31 clocks)
        kcount = 0;
        repeat (33) begin
            @(negedge Clk);
            if (K) kcount = kcount + 1;
        end
        if (kcount !== 1) begin
            $display("FAIL K pulsou %0d vezes (esperado 1)", kcount);
            errors = errors + 1;
        end
        if (errors == 0) $display("Counter_TB: PASS");
        else             $display("Counter_TB: %0d ERRORS", errors);
        $finish;
    end
endmodule
