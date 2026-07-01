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
    // Mesma divergencia de modelo de RAM do lado de instrucao: o Data.hex tem
    // o valor i no endereco de BYTE 4i. O modelo RTL (altsyncram) empacota ->
    // valor i na palavra i; o modelo de GATE (cycloneiv_ram_block) indexa por
    // palavra -> valor i na palavra 4i. Por isso o Gate precisa de <<2.
    // (Compile a sim RTL com +define+RTL_SIM.)
`ifdef RTL_SIM
    assign internalAddress = (D - DATA_BASE);        // RTL: palavras consecutivas
`else
    assign internalAddress = (D - DATA_BASE) << 2;   // Gate: valor i na palavra 4i
`endif
    assign iAddress        = internalAddress[9:0];
    assign iWE             = we &  CS;   // escrita interna
    assign WE              = we & ~CS;   // escrita externa
    assign ADDR            = D;          // endereco externo
endmodule
