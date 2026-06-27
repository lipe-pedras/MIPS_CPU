// =============================================================================
// ACC.v - Acumulador de deslocamento-e-soma (adaptado p/ 16 bits).
//
// Saidas tem 2N+1 = 33 bits.
//   Load: Entradas[15:0] -> Saidas[15:0], zera Saidas[32:16] (carrega o
//         Multiplicador nos bits baixos);
//   Ad:   Entradas[32:16] (Soma, 17 bits) -> Saidas[32:16], mantem [15:0];
//   Sh:   deslocamento logico a direita de 1 (MSB = 0).
//
// Bits [15:0] guardam os bits restantes do Multiplicador (LSB = M).
// Bits [31:0] guardam o Produto apos Done.
// =============================================================================
module ACC (
    input             Load, Sh, Ad, Clk, rst,
    input      [32:0] Entradas,
    output reg [32:0] Saidas
);
    always @(posedge Clk or posedge rst) begin
        if (rst)
            Saidas <= 33'b0;
        else if (Load)
            Saidas <= {17'b0, Entradas[15:0]};
        else if (Ad)
            Saidas <= {Entradas[32:16], Saidas[15:0]};
        else if (Sh)
            Saidas <= {1'b0, Saidas[32:1]};
    end
endmodule
