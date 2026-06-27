// =============================================================================
// InstMem.v - Memoria de instrucoes (IF).
//
// Modelo comportamental SINTETIZAVEL de BRAM Altera: leitura SINCRONA
// (o registrador de estagio IF/ID fica embutido na BRAM). 1 kWord de 32 bits.
// Inicializada por $readmemh a partir de INIT_FILE (Code.hex), com o programa
// ja codificado (Big Endian, opcodes do grupo).
//
// NOTA: o IP real (M9K / altsyncram) deve ser gerado no IP Catalog do Quartus;
//       este modelo o substitui para simulacao RTL e Gate Level.
// =============================================================================
module InstMem #(
    parameter NWORDS    = 1024,
    parameter ADDRW     = 10,
    parameter INIT_FILE = "Code.hex"
) (
    input               clk,
    input  [ADDRW-1:0]  addr,
    output reg [31:0]   INST
);
    (* ram_init_file = INIT_FILE *)
    reg [31:0] mem [0:NWORDS-1];

    initial begin
        INST = 32'h0000_0000;   // saida inicia em NOP (evita X no boot do pipeline)
        $readmemh(INIT_FILE, mem);
    end

    // Leitura sincrona (BRAM Altera): INST registrado 1 ciclo.
    always @(posedge clk) begin
        INST <= mem[addr];
    end
endmodule
