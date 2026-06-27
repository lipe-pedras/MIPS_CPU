// =============================================================================
// Adder.v - Somador combinacional do multiplicador (adaptado p/ 16 bits).
// Soma o produto parcial (Saidas[31:16]) com o Multiplicando, gerando 17 bits
// (16 + carry).
// =============================================================================
module Adder (
    input  [15:0] OperandoA,
    input  [15:0] OperandoB,
    output [16:0] Soma
);
    assign Soma = OperandoA + OperandoB;
endmodule
