// =============================================================================
// alu.v - Unidade Logico-Aritmetica do estagio EX.
//
// Operacoes (selecionadas por aluControl, vindo do barramento CTRL):
//   000 ADD  : result = A + B           (LW/SW: A+offset ; ADD)
//   001 SUB  : result = A - B           (SUB ; comparacao do BNE)
//   010 AND  : result = A & B           (AND)
//   011 OR   : result = A | B           (OR ; ORI)
//   outros   : ADD por padrao
//
// zeroFlag = 1 quando (A - B) == 0, ou seja, A == B.
//   Usado pelo PC/IF para a decisao do BNE: ramo tomado = branchFlag & ~zeroFlag.
//
// Modulo puramente combinacional.
// =============================================================================
module alu #(
    parameter WIDTH = 32
) (
    input      [WIDTH-1:0] A,
    input      [WIDTH-1:0] B,
    input      [2:0]       aluControl,
    output reg [WIDTH-1:0] result,
    output                 zeroFlag
);
    localparam ALU_ADD = 3'b000;
    localparam ALU_SUB = 3'b001;
    localparam ALU_AND = 3'b010;
    localparam ALU_OR  = 3'b011;

    always @(*) begin
        case (aluControl)
            ALU_ADD: result = A + B;
            ALU_SUB: result = A - B;
            ALU_AND: result = A & B;
            ALU_OR:  result = A | B;
            default: result = A + B;
        endcase
    end

    // zeroFlag indica igualdade entre A e B (A - B == 0).
    assign zeroFlag = (A == B);
endmodule
