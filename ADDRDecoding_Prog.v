// =============================================================================
// ADDRDecoding_Prog.v - Decodificador de enderecos da memoria de PROGRAMA (IF).
//
// O PC enderecca BYTE e a memoria de programa ocupa 1 kWord a partir de
//   PROG_BASE = GROUP*CteMemProg = 0x0900, faixa [0x0900, 0x1900).
//
// Gera:
//   - CS_P  : chip-select interno x externo (1 = dentro da faixa do grupo);
//   - iADDR : indice de PALAVRA interno da InstMem (10 bits, 0..1023),
//             convertido de byte para palavra: (ADDR_Prog - PROG_BASE) >> 2.
//
// Modulo puramente combinacional.
// =============================================================================
module ADDRDecoding_Prog #(
    parameter PROG_BASE = 32'h0000_0900,
    parameter NWORDS    = 1024
) (
    input  [31:0] ADDR_Prog,
    output        CS_P,
    output [9:0]  iADDR
);
    // O modelo de RAM da SIMULACAO RTL (altera_mf altsyncram) e o modelo de
    // GATE LEVEL (cycloneiv_ram_block) carregam o MESMO Intel HEX de formas
    // diferentes:
    //   - RTL  : empacota em palavras CONSECUTIVAS  -> indice = (PC-base) >> 2
    //   - GATE : indexa por palavra = offset de byte -> indice = (PC-base)
    // Por isso usamos um switch SO de simulacao: compile a sim RTL com
    // +define+RTL_SIM; a sintese/Gate Level usa o ramo padrao (sem >>2).
    wire [31:0] aux = (ADDR_Prog - PROG_BASE);
`ifdef RTL_SIM
    wire in_range = (ADDR_Prog >= PROG_BASE) &&
                    (ADDR_Prog <  PROG_BASE + (NWORDS << 2));
    assign iADDR  = aux[11:2];     // byte -> palavra (modelo RTL)
`else
    wire in_range = (ADDR_Prog >= PROG_BASE) &&
                    (ADDR_Prog <  PROG_BASE + NWORDS);
    assign iADDR  = aux[9:0];      // enderecamento direto (sintese/Gate)
`endif
    assign CS_P   = in_range;
endmodule
