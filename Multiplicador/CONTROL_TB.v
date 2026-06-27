`timescale 1ns/1ps
// TestBench da FSM de controle: Idle, Load no St, sequencia Add/Shift, Done em K.
module CONTROL_TB;
    reg     Clk, K, St, M, rst;
    wire    Idle, Done, Load, Sh, Ad;
    integer errors = 0;

    CONTROL DUT (.Clk(Clk), .K(K), .St(St), .M(M), .rst(rst),
                 .Idle(Idle), .Done(Done), .Load(Load), .Sh(Sh), .Ad(Ad));

    always #5 Clk = ~Clk;

    initial begin
        Clk=0; rst=1; K=0; St=0; M=1;
        #12 rst=0;
        // estado inicial: Idle
        #1 if (!Idle) begin $display("FAIL: nao iniciou em Idle"); errors=errors+1; end
        // St -> Load no mesmo estado s0
        St=1; #1 if (!Load) begin $display("FAIL: Load nao subiu com St"); errors=errors+1; end
        @(negedge Clk); St=0;     // -> s1
        #1 if (M && !Ad) begin $display("FAIL: Ad deveria seguir M em s1"); errors=errors+1; end
        @(negedge Clk);           // s1 -> s2
        #1 if (!Sh) begin $display("FAIL: Sh deveria estar ativo em s2"); errors=errors+1; end
        // forca K=1 para ir a s3 (s2 -> s3 em uma borda)
        K=1; @(negedge Clk);
        #1 if (!Done) begin $display("FAIL: Done deveria subir em s3"); errors=errors+1; end
        if (errors == 0) $display("CONTROL_TB: PASS");
        else             $display("CONTROL_TB: %0d ERRORS", errors);
        $finish;
    end
endmodule
