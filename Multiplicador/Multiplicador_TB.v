`timescale 1ns/1ps
// TestBench do multiplicador 16x16->32. Dispara St, espera Done e confere.
module Multiplicador_TB;
    reg  [15:0] Multiplicando, Multiplicador_in;
    reg         St, Clk, rst;
    wire [31:0] Produto;
    wire        Idle, Done;
    integer     errors = 0;

    Multiplicador DUT (
        .Multiplicando (Multiplicando),
        .Multiplicador (Multiplicador_in),
        .St            (St),
        .Clk           (Clk),
        .rst           (rst),
        .Produto       (Produto),
        .Idle          (Idle),
        .Done          (Done)
    );

    always #5 Clk = ~Clk;

    // executa uma multiplicacao e confere o resultado
    task run_mul;
        input [15:0] a, b;
        integer cycles;
        begin
            @(negedge Clk); Multiplicando = a; Multiplicador_in = b; St = 1;
            @(negedge Clk); St = 0;
            cycles = 0;
            while (!Done && cycles < 100) begin @(negedge Clk); cycles = cycles + 1; end
            if (Produto !== (a * b)) begin
                $display("FAIL %0d * %0d = %0d (exp %0d) [%0d ciclos]",
                         a, b, Produto, a*b, cycles);
                errors = errors + 1;
            end else
                $display("OK  %0d * %0d = %0d  (Done em %0d ciclos)", a, b, Produto, cycles);
        end
    endtask

    initial begin
        Clk = 0; St = 0; rst = 1; Multiplicando = 0; Multiplicador_in = 0;
        #20 rst = 0;
        run_mul(16'd13,    16'd11);     // 143
        run_mul(16'd255,   16'd255);    // 65025 (0x00FF*0x00FF)
        run_mul(16'd1234,  16'd5678);   // 7006652
        run_mul(16'hFFFF,  16'hFFFF);   // 0xFFFE0001
        run_mul(16'd0,     16'd12345);  // 0
        run_mul(16'd1,     16'd40000);  // 40000
        if (errors == 0) $display("Multiplicador_TB: PASS");
        else             $display("Multiplicador_TB: %0d ERRORS", errors);
        $finish;
    end
endmodule
