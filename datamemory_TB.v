`timescale 1ns/1ps
// TestBench da memoria de dados: init via hex, escrita e leitura sincronas.
module datamemory_TB;
    reg         clk, we;
    reg  [9:0]  addr;
    reg  [31:0] din;
    wire [31:0] dout;

    // usa o Data.hex de entrega (placeholder 0..9 nas 10 primeiras palavras)
    datamemory DUT
        (.clock(clk), .address(addr), .data(din), .wren(we), .q(dout));

    always #5 clk = ~clk;


    initial begin
        clk = 0; we = 0; addr = 0; din = 0;
        // leitura dos valores iniciais do Data.hex (0..9)
        addr = 0; @(negedge clk); 
        addr = 1; @(negedge clk); 
        // escreve 0x12345678 na pos 5
        addr = 5; din = 32'h12345678; we = 1; @(negedge clk); we = 0;
        // le de volta
        addr = 5; @(negedge clk); 
        // posicao 2 intacta (valor inicial = 2)
        addr = 2; @(negedge clk); 
        
		  $stop;
    end
endmodule