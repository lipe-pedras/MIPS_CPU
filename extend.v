// =============================================================================
// extend.v - Extensao de sinal do imediato (estagio ID).
//
// Le os 16 bits menos significativos da instrucao (INST[15:0]) e estende
// com sinal para 32 bits (SignExtImm). Trata positivo e negativo via
// replicacao do bit 15 (bit de sinal).
//
// Modulo puramente combinacional.
// =============================================================================
module extend (
    input  [31:0] INST,
    output [31:0] SignExtImm
);
    assign SignExtImm = {{16{INST[15]}}, INST[15:0]};
endmodule
