// =============================================================================
// pc.v - Program Counter (estagio IF).
//
// - Reset assincrono ativo-alto: PC -> RESET_ADDR (0x0900 = GROUP*CteMemProg).
// - Incremento sequencial de +4 (PC enderecca BYTE; cada instrucao = 4 bytes).
// - Desvios:
//     * BNE (resolvido no EX): tomado quando branchFlag & ~zeroFlag.
//       PC <- branchOffset (= PC_da_BNE + 4 + offset, calculado no EX).
//     * JMP (resolvido no ID): jmpFlag=1 -> PC <- jmpAddress.
//   Prioridade: BNE (instrucao mais antiga, no EX) > JMP (no ID) > PC+4.
//
// A saida pc e o barramento ADDR_Prog que enderecca a InstMem.
// =============================================================================
module pc #(
    parameter WIDTH      = 32,
    parameter RESET_ADDR = 32'h0000_0900
) (
    input                  clk,
    input                  rst,
    input                  jmpFlag,
    input      [WIDTH-1:0] jmpAddress,
    input                  branchFlag,
    input                  zeroFlag,
    input      [WIDTH-1:0] branchOffset,
    output reg [WIDTH-1:0] pc
);
    wire branchTaken = branchFlag & ~zeroFlag;
    wire [WIDTH-1:0] next = branchTaken ? branchOffset :
                            jmpFlag     ? jmpAddress   :
                                          pc + 32'd4;

    always @(posedge clk or posedge rst) begin
        if (rst) pc <= RESET_ADDR;
        else     pc <= next;
    end
endmodule
