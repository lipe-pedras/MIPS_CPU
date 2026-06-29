`timescale 1ns/1ps
// TestBench do banco de registradores: escrita sincrona, leitura assincrona,
// r0 fixo em 0, reset assincrono.
module registerfile_TB;
    reg         clk, reset, wr;
    reg  [31:0] dataIn;
    reg  [4:0]  wrAddress, rdAddress1, rdAddress2;
    wire [31:0] dataOut1, dataOut2;

    registerfile DUT (.clk(clk), .reset(reset), .wr(wr), .dataIn(dataIn),
        .wrAddress(wrAddress), .rdAddress1(rdAddress1), .rdAddress2(rdAddress2),
        .dataOut1(dataOut1), .dataOut2(dataOut2));

    always #5 clk = ~clk;


    initial begin
        clk=0; reset=1; wr=0; dataIn=0; wrAddress=0; rdAddress1=0; rdAddress2=0;
        #12; reset=0;
        // escreve 0xAB em r5
        wrAddress=5; dataIn=32'hAB; wr=1; @(negedge clk); wr=0;
        rdAddress1=5; #1; 
        // escreve 0xCD em r7
        wrAddress=7; dataIn=32'hCD; wr=1; @(negedge clk); wr=0;
        rdAddress2=7; #1; 
        // r0 sempre 0 (tentar escrever nao altera)
        wrAddress=0; dataIn=32'hFFFF; wr=1; @(negedge clk); wr=0;
        rdAddress1=0; #1
        // reset assincrono limpa
        rdAddress1=5; reset=1; #1;
        
		  $stop;
    end
endmodule
