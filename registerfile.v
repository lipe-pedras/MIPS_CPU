// =============================================================================
// registerfile.v - Banco de registradores fornecido no laboratorio.
//
// Escrita SINCRONA, leitura ASSINCRONA (combinacional), reset assincrono
// ativo-alto, r0 hard-wired em 0 (nao e armazenado).
// Interface NAO deve ser alterada.
// =============================================================================
// Synchronous Write and Asynchronous Read
module registerfile #(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 5            // 5 bits to address 32 registers
) (
  input                    clk,
  input                    reset,
  input                    wr,
  input  [DATA_WIDTH-1:0]  dataIn,
  input  [ADDR_WIDTH-1:0]  wrAddress,   // Address for writing
  input  [ADDR_WIDTH-1:0]  rdAddress1,  // Address for the first read
  input  [ADDR_WIDTH-1:0]  rdAddress2,  // Address for the second read
  output reg [DATA_WIDTH-1:0] dataOut1,  // Data output for the first read
  output reg [DATA_WIDTH-1:0] dataOut2   // Data output for the second read
);
  localparam NUM_REGISTERS = 2**ADDR_WIDTH;
  integer i;
  reg [DATA_WIDTH-1:0] registers [1:NUM_REGISTERS-1]; // Registers 1..NUM-1

  // Register write logic (synchronous, async reset, r0 not stored)
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      for (i = 1; i < NUM_REGISTERS; i = i + 1)
        registers[i] <= {DATA_WIDTH{1'b0}};
    end else if (wr && wrAddress != 0) begin
      registers[wrAddress] <= dataIn;
    end
  end

  // Asynchronous read 1 (r0 always 0)
  always @(*) begin
    if (rdAddress1 == 0) dataOut1 <= {DATA_WIDTH{1'b0}};
    else                 dataOut1 <= registers[rdAddress1];
  end

  // Asynchronous read 2 (r0 always 0)
  always @(*) begin
    if (rdAddress2 == 0) dataOut2 <= {DATA_WIDTH{1'b0}};
    else                 dataOut2 <= registers[rdAddress2];
  end
endmodule
