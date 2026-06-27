// =============================================================================
// Counter.v - Contador de iteracoes (adaptado p/ 16 bits).
//
// Conta 2N = 32 pulsos (2 por iteracao x 16 iteracoes). Reinicia em Load.
// Incrementa livremente a cada clock. Gera K=1 quando counter == 2N-2 = 30,
// de modo que a CONTROL veja K=1 um clock depois, na 16a visita ao estado S2.
// =============================================================================
module Counter (
    input            Load, Clk, rst,
    output reg       K
);
    reg [5:0] counter;   // 0..32 (6 bits)

    always @(posedge Clk or posedge rst) begin
        if (rst) begin
            counter <= 6'd0;
            K       <= 1'b0;
        end else if (Load) begin
            counter <= 6'd0;
            K       <= 1'b0;
        end else begin
            counter <= counter + 6'd1;
            K       <= (counter == 6'd30);   // 2N-2
        end
    end
endmodule
