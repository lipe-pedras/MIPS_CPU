// =============================================================================
// ADDRDecoding.v - Decodificador de enderecos da memoria de DADOS (MEM).
//
// Le o barramento D (endereco efetivo de PALAVRA = R[rs] + SignExtImm).
// A memoria de dados ocupa 1 kWord a partir de
//   DATA_BASE = GROUP*CteMemDados = 0x1500, faixa [0x1500, 0x1900).
//
// Gera:
//   - CS              : chip-select interno x externo (1 = faixa do grupo);
//   - internalAddress : (D - DATA_BASE) -> deslocamento interno (palavra);
//   - iAddress        : indice efetivo da BRAM interna (10 bits);
//   - iWE             : write-enable da DataMemory INTERNA (SW e CS);
//   - WE              : write-enable EXTERNO (SW e ~CS);
//   - ADDR            : endereco repassado ao barramento EXTERNO de dados.
//
// 'we' e o sinal memWrite vindo do barramento CTRL (1 = SW).
// Modulo puramente combinacional.
// =============================================================================
module ADDRDecoding #(
    parameter DATA_BASE = 32'h0000_1500,
    parameter NWORDS    = 1024
) (
    input  [31:0] D,
    input         we,                 // memWrite (SW)
    output        CS,
    output [31:0] internalAddress,
    output [9:0]  iAddress,
    output        iWE,
    output        WE,
    output [31:0] ADDR
);
    wire in_range = (D >= DATA_BASE) && (D < DATA_BASE + NWORDS); // palavra
    assign CS              = in_range;
    assign internalAddress = D - DATA_BASE;
    assign iAddress        = internalAddress[9:0];
    assign iWE             = we &  CS;   // escrita interna
    assign WE              = we & ~CS;   // escrita externa
    assign ADDR            = D;          // endereco externo
endmodule
