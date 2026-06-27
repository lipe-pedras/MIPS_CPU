`timescale 1ns/1ps
// TestBench da memoria de instrucoes: leitura sincrona (1 ciclo) e init via hex.
module InstMem_TB;
    reg         clk;
    reg  [9:0]  addr;
    wire [31:0] INST;
    integer     errors = 0;

    // usa o Code.hex de entrega; compara a leitura sincrona contra uma copia
    // independente do mesmo arquivo (robusto a mudancas no programa).
    InstMem #(.INIT_FILE("Code.hex")) DUT (.clk(clk), .addr(addr), .INST(INST));

    reg [31:0] expected [0:1023];
    initial $readmemh("Code.hex", expected);

    always #5 clk = ~clk;

    task check; input [31:0] exp; begin
        if (INST !== exp) begin
            $display("FAIL addr=%0d INST=%h exp=%h", addr, INST, exp);
            errors = errors + 1;
        end
    end endtask

    initial begin
        clk = 0; addr = 0;
        @(negedge clk); check(expected[0]); // leitura sincrona da pos 0
        addr = 1; @(negedge clk); check(expected[1]);
        addr = 2; @(negedge clk); check(expected[2]);
        addr = 3; @(negedge clk); check(expected[3]);
        if (errors == 0) $display("InstMem_TB: PASS");
        else             $display("InstMem_TB: %0d ERRORS", errors);
        $finish;
    end
endmodule
