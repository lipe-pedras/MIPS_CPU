// =============================================================================
// PLL.v - Modelo comportamental do ALTPLL (gera CLK_SYS e CLK_MUL).
//
//   ATENCAO: este e um MODELO comportamental sintetizavel para simulacao
//   (RTL e Gate Level). O IP real deve ser gerado no IP Catalog do Quartus
//   (megafunction ALTPLL) e este arquivo substituido pela megafuncao.
//   Mantenha o clock de entrada do testbench IGUAL ao definido no IP.
//
// Estrategia do modelo:
//   - inclk0 e o clock de referencia (frequencia do CLK_MUL).
//   - c1 = CLK_MUL = inclk0  (passagem direta; o IP real multiplicaria a freq.).
//   - c0 = CLK_SYS = inclk0 / DIV  (divisor inteiro).
//
//   Um periodo de CLK_SYS comporta DIV periodos de CLK_MUL. Como a latencia do
//   multiplicador e 2N+2 = 34 (CLK_MUL), usamos DIV = 40 para dar margem ao
//   handshake atraves dos sincronizadores de 2 FF (St e Done). Throughput do
//   sistema permanece 1 instrucao por CLK_SYS.
//
// Reset assincrono ativo-alto (areset).
// =============================================================================
module PLL #(
    parameter DIV = 40                 // CLK_SYS = CLK_MUL / DIV  (>= 34)
) (
    input      inclk0,                 // clock de referencia (= CLK_MUL)
    input      areset,
    output     c1,                     // CLK_MUL
    output reg c0,                     // CLK_SYS
    output     locked
);
    assign c1     = inclk0;            // CLK_MUL (passagem direta no modelo)
    assign locked = ~areset;          // "trava" assim que sai do reset

    reg [15:0] cnt;
    always @(posedge inclk0 or posedge areset) begin
        if (areset) begin
            cnt <= 16'd0;
            c0  <= 1'b0;
        end else if (cnt == (DIV/2 - 1)) begin
            cnt <= 16'd0;
            c0  <= ~c0;                // meio periodo de CLK_SYS = DIV/2 de CLK_MUL
        end else begin
            cnt <= cnt + 16'd1;
        end
    end
endmodule
