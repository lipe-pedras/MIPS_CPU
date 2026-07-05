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
    assign iWE             = we &  CS;   // escrita interna
    assign WE              = we & ~CS;   // escrita externa
    assign ADDR            = D;          // endereco externo
endmodule
