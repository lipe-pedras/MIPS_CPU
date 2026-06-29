`timescale 1ns/1ps
// TestBench do registrador generico: verifica reset assincrono e captura sincrona.
module register_TB;
    reg         clk, rst;
    reg  [31:0] d;
    wire [31:0] q;

    register #(.WIDTH(32)) DUT (.clk(clk), .rst(rst), .d(d), .q(q));

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; d = 32'hDEADBEEF;
        #12;                 // reset assincrono -> q deve estar zerado
		  
        rst = 0;
        @(negedge clk);      // apos uma borda de subida, captura d
        d = 32'h12345678;
        @(negedge clk);
		  
        rst = 1; #1;         // reset assincrono limpa imediatamente
        
		  $stop;
    end
endmodule
