// =============================================================================
// mux.v - Multiplexador 2:1 generico, parametrizavel em largura.
//
// sel = 0 -> out = in0
// sel = 1 -> out = in1
//
// Reaproveitado em varias instancias do topo:
//   - selecao instrucao interna/externa e injecao de NOP (flush) no IF
//   - ALU_MUL_MUX (ALU x MUL) no EX
//   - IMM_MUX (IMM x B) no EX
//   - selecao dado memoria interna/externa no MEM
//   - writeBack (D x M) no WB
// Modulo puramente combinacional (sem reset).
// =============================================================================
module mux #(
    parameter WIDTH = 32
) (
    input              sel,
    input  [WIDTH-1:0] in0,
    input  [WIDTH-1:0] in1,
    output [WIDTH-1:0] out
);
    assign out = sel ? in1 : in0;
endmodule
