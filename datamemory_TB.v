`timescale 1ns/1ps
// TestBench da memoria de dados: init via hex, escrita e leitura sincronas.
module datamemory_TB;
    reg         clk, we;
    reg  [9:0]  addr;
    reg  [31:0] din;
    wire [31:0] dout;
    integer     errors = 0;

    // usa o Data.hex de entrega (placeholder 0..9 nas 10 primeiras palavras)
    datamemory #(.INIT_FILE("Data.hex")) DUT
        (.clk(clk), .addr(addr), .din(din), .we(we), .dout(dout));

    always #5 clk = ~clk;

    task check; input [31:0] exp; begin
        if (dout !== exp) begin
            $display("FAIL addr=%0d dout=%h exp=%h", addr, dout, exp);
            errors = errors + 1;
        end
    end endtask

    initial begin
        clk = 0; we = 0; addr = 0; din = 0;
        // leitura dos valores iniciais do Data.hex (0..9)
        addr = 0; @(negedge clk); check(32'd0);
        addr = 1; @(negedge clk); check(32'd1);
        // escreve 0x12345678 na pos 5
        addr = 5; din = 32'h12345678; we = 1; @(negedge clk); we = 0;
        // le de volta
        addr = 5; @(negedge clk); check(32'h12345678);
        // posicao 2 intacta (valor inicial = 2)
        addr = 2; @(negedge clk); check(32'd2);
        if (errors == 0) $display("datamemory_TB: PASS");
        else             $display("datamemory_TB: %0d ERRORS", errors);
        $finish;
    end
endmodule
