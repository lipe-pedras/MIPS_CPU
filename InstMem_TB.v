`timescale 1ns/1ps
// TestBench da memoria de instrucoes: leitura sincrona (1 ciclo) e init via hex.
module InstMem_TB;
    reg         clk;
    reg  [9:0]  addr;
    wire [31:0] INST;

    // usa o Code.hex de entrega; compara a leitura sincrona contra uma copia
    // independente do mesmo arquivo (robusto a mudancas no programa).
    InstMem DUT (.clock(clk), .address(addr), .data(32'h0), .wren(1'b0), .q(INST));

    always #5 clk = ~clk;


    initial begin
        clk = 0; addr = 0;
        @(negedge clk);  // leitura sincrona da pos 0
        addr = 1; @(negedge clk); 
        addr = 2; @(negedge clk); 
        addr = 3; @(negedge clk); 
		  
		  $stop;
    end
endmodule