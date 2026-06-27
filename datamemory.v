// =============================================================================
// datamemory.v - Memoria de dados (MEM).
//
// Modelo comportamental SINTETIZAVEL de BRAM Altera: leitura e escrita
// SINCRONAS. 1 kWord de 32 bits. Inicializada por $readmemh (Data.hex).
//
//   - escrita: na borda de subida, se we -> mem[addr] <= din;
//   - leitura: na borda de subida, dout <= mem[addr] (1 ciclo de latencia,
//     dado disponivel no estagio WB). Comportamento "read-old-data".
//
// NOTA: substituir pelo IP altsyncram (M9K) no Quartus para a placa real.
// =============================================================================
module datamemory #(
    parameter NWORDS    = 1024,
    parameter ADDRW     = 10,
    parameter INIT_FILE = "Data.hex"
) (
    input               clk,
    input  [ADDRW-1:0]  addr,
    input  [31:0]       din,
    input               we,
    output reg [31:0]   dout
);
    (* ram_init_file = INIT_FILE *)
    reg [31:0] mem [0:NWORDS-1];

    initial begin
        $readmemh(INIT_FILE, mem);
    end

    always @(posedge clk) begin
        if (we) mem[addr] <= din;
        dout <= mem[addr];     // leitura sincrona (dado "antigo" em escrita)
    end
endmodule
