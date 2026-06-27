// =============================================================================
// register.v - Registrador de estagio generico, parametrizavel em largura.
//
// Usado para todos os registradores de pipeline (ID_EX_*, EX_MEM_*, MEM_WB_*).
// Reset assincrono ativo em nivel ALTO (convencao unica do projeto):
//   always @(posedge clk or posedge rst) ... if (rst) ...
// =============================================================================
module register #(
    parameter WIDTH = 32
) (
    input                  clk,
    input                  rst,
    input      [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk or posedge rst) begin
        if (rst) q <= {WIDTH{1'b0}};
        else     q <= d;
    end
endmodule
