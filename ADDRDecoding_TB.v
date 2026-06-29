`timescale 1ns/1ps
// TestBench do decodificador de enderecos de dados.
module ADDRDecoding_TB;
    reg  [31:0] D;
    reg         we;
    wire        CS, iWE, WE;
    wire [31:0] internalAddress, ADDR;
    wire [9:0]  iAddress;

    ADDRDecoding DUT (.D(D), .we(we), .CS(CS), .internalAddress(internalAddress),
                      .iAddress(iAddress), .iWE(iWE), .WE(WE), .ADDR(ADDR));


    initial begin
        // dentro da faixa de dados, leitura
        D = 32'h1500; we = 0; #1; 
        D = 32'h1501; we = 0; #1; 
        D = 32'h18FF; we = 0; #1; 
        // dentro da faixa, escrita -> iWE
        D = 32'h1502; we = 1; #1; 
        // fora da faixa, escrita -> WE externo
        D = 32'h2000; we = 1; #1;
        // fora da faixa, leitura
        D = 32'h0100; we = 0; #1; 
        
		  $stop;
    end
endmodule
