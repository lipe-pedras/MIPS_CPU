// =============================================================================
// ADDRDecoding_Prog.v - Decodificador de enderecos da memoria de PROGRAMA (IF).
// O PC enderecca BYTE; a memoria de programa ocupa 1 kWord a partir de
//   PROG_BASE = GROUP*CteMemProg = [0x0900, 0x1900). Combinacional.
// =============================================================================
module ADDRDecoding_Prog #(
    parameter PROG_BASE = 32'h0000_0900,
    parameter NWORDS    = 1024
) (
    input  [31:0] ADDR_Prog,
    output        CS_P,
    output [9:0]  iADDR
);

    wire [31:0] aux = (ADDR_Prog - PROG_BASE);
    wire in_range = (ADDR_Prog >= PROG_BASE) &&
                    (ADDR_Prog <  PROG_BASE + NWORDS);
    assign iADDR  = aux[9:0];      // enderecamento direto (sintese/Gate)
    assign CS_P   = in_range;
endmodule
