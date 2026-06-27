// =============================================================================
// Multiplicador.v - Multiplicador sequencial 16x16 -> 32 bits (Lab 3/4 adaptado).
//
// Algoritmo soma-e-desloca, latencia 2N+2 = 34 clocks (de CLK_MUL).
// Opera no DOMINIO DE CLOCK PROPRIO (Clk = CLK_MUL), distinto de CLK_SYS.
// O handshake (St/Done) e sincronizado entre dominios no topo (risc.v) com
// sincronizadores de 2 flip-flops (ver secao 6 do roteiro).
//
// Portas (conforme roteiro): Multiplicando, Multiplicador, St, Clk (+rst);
//                            Produto, Idle, Done.
// =============================================================================
module Multiplicador (
    input  [15:0] Multiplicando,
    input  [15:0] Multiplicador,
    input         St, Clk, rst,
    output [31:0] Produto,
    output        Idle, Done
);
    wire        Load, Sh, Ad, K, M;
    wire [16:0] Soma;
    wire [32:0] Saidas;

    assign M       = Saidas[0];        // bit corrente do multiplicador (LSB)
    assign Produto = Saidas[31:0];     // produto de 32 bits apos Done

    Adder adder (
        .OperandoA (Saidas[31:16]),    // produto parcial (16 bits altos)
        .OperandoB (Multiplicando),
        .Soma      (Soma)              // 17 bits
    );

    ACC acc (
        .Load     (Load),
        .rst      (rst),
        .Sh       (Sh),
        .Ad       (Ad),
        .Clk      (Clk),
        .Entradas ({Soma, Multiplicador}), // [32:16]=Soma (Ad), [15:0]=Mult (Load)
        .Saidas   (Saidas)
    );

    CONTROL control (
        .Clk  (Clk),
        .rst  (rst),
        .K    (K),
        .St   (St),
        .M    (M),
        .Idle (Idle),
        .Done (Done),
        .Load (Load),
        .Sh   (Sh),
        .Ad   (Ad)
    );

    Counter counter (
        .Load (Load),
        .rst  (rst),
        .Clk  (Clk),
        .K    (K)
    );
endmodule
