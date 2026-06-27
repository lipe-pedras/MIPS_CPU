`timescale 1ns/1ps
// TestBench do registrador generico: verifica reset assincrono e captura sincrona.
module register_TB;
    reg         clk, rst;
    reg  [31:0] d;
    wire [31:0] q;
    integer     errors = 0;

    register #(.WIDTH(32)) DUT (.clk(clk), .rst(rst), .d(d), .q(q));

    always #5 clk = ~clk;

    task check;
        input [31:0] exp;
        begin
            if (q !== exp) begin
                $display("FAIL t=%0t q=%h exp=%h", $time, q, exp);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk = 0; rst = 1; d = 32'hDEADBEEF;
        #12;                 // reset assincrono -> q deve estar zerado
        check(32'h0);
        rst = 0;
        @(negedge clk);      // apos uma borda de subida, captura d
        check(32'hDEADBEEF);
        d = 32'h12345678;
        @(negedge clk);
        check(32'h12345678);
        rst = 1; #1;         // reset assincrono limpa imediatamente
        check(32'h0);
        if (errors == 0) $display("register_TB: PASS");
        else             $display("register_TB: %0d ERRORS", errors);
        $finish;
    end
endmodule
