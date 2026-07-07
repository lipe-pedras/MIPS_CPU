// =============================================================================
// ADDRDecoding.v - Decodificador de enderecos da memoria de DADOS (MEM).
// Le D (endereco efetivo = R[rs] + SignExtImm) e separa interno x externo na
// faixa de dados do grupo: DATA_BASE = GROUP*CteMemDados = [0x1500, 0x1900).
// Combinacional. ('we' = memWrite vindo do CTRL: 1 = SW.)
// =============================================================================
module ADDRDecoding #(
    parameter DATA_BASE = 32'h0000_1500,
    parameter NWORDS    = 1024
) (
    input  [31:0] D,
    input         we,                 // memWrite (SW)
    output        CS,
    output [31:0] internalAddress,
    output        iWE,
    output        WE,
    output [31:0] ADDR
);
    // Obs.: o indice de 10 bits da BRAM (iAddress) e derivado de internalAddress
    // NO TOPO (risc.v), e nao aqui. Assim internalAddress ganha fanout real e
    // sobrevive com nome proprio no netlist gate-level (senao o Quartus o poda
    // por ser fanout-free e o $init_signal_spy nao o encontra).
    wire in_range = (D >= DATA_BASE) && (D < DATA_BASE + NWORDS); // palavra
    assign CS              = in_range;
    assign internalAddress = (D - DATA_BASE);        // indice de palavra (BRAM word-addressed)
    assign iWE             = we &  CS;   // escrita interna
    assign WE              = we;         // escrita
    assign ADDR            = D;          // endereco externo
endmodule
