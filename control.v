
module control #(
    parameter PROG_BASE = 32'h0000_0900   // GROUP * CteMemProg
) (
    input      [31:0] INST,
    output     [4:0]  rdAddress1,   // rs
    output     [4:0]  rdAddress2,   // rt
    output reg [14:0] CTRL,
    output reg        jmpFlag,
    output reg [31:0] jmpAddress
);
    // ---- campos da instrucao ----
    wire [5:0] opcode = INST[31:26];
    wire [4:0] rs     = INST[25:21];
    wire [4:0] rt     = INST[20:16];
    wire [4:0] rd     = INST[15:11];
    wire [5:0] funct  = INST[5:0];

    assign rdAddress1 = rs;
    assign rdAddress2 = rt;

    // ---- opcodes (GROUP = 3) ----
    localparam OP_RTYPE = 6'd13;
    localparam OP_JMP   = 6'd2;
    localparam OP_LW    = 6'd35;
    localparam OP_SW    = 6'd36;
    localparam OP_BNE   = 6'd37;
    localparam OP_ADDI  = 6'd38;
    localparam OP_ORI   = 6'd39;

    // ---- funct (tipo R) ----
    localparam F_ADD = 6'd32;
    localparam F_SUB = 6'd34;
    localparam F_MUL = 6'd50;
    localparam F_AND = 6'd36;
    localparam F_OR  = 6'd37;

    // ---- codigos da ALU ----
    localparam ALU_ADD = 3'b000;
    localparam ALU_SUB = 3'b001;
    localparam ALU_AND = 3'b010;
    localparam ALU_OR  = 3'b011;

    // campos do CTRL montados localmente
    reg [4:0] writeReg;
    reg       regWrite, memWrite, memRead, memToReg, aluSrc, isMul, branchFlag;
    reg [2:0] aluControl;

    always @(*) begin
        // defaults neutros (NOP)
        writeReg   = 5'd0; 			//
        regWrite   = 1'b0;				//1
        memWrite   = 1'b0;				//0
        memRead    = 1'b0;				//1
        memToReg   = 1'b0;				//1
        aluSrc     = 1'b0;				//1
        aluControl = ALU_ADD;
        isMul      = 1'b0;
        branchFlag = 1'b0;
        jmpFlag    = 1'b0;
        jmpAddress = 32'd0;

        case (opcode)
            OP_LW: begin
                regWrite = 1'b1; writeReg = rt; memRead = 1'b1;
                memToReg = 1'b1; aluSrc = 1'b1; aluControl = ALU_ADD;
            end
            OP_SW: begin
                memWrite = 1'b1; aluSrc = 1'b1; aluControl = ALU_ADD;
            end
            OP_BNE: begin
                branchFlag = 1'b1; aluSrc = 1'b0; aluControl = ALU_SUB;
            end
            OP_ADDI: begin
                regWrite = 1'b1; writeReg = rt; aluSrc = 1'b1; aluControl = ALU_ADD;
            end
            OP_ORI: begin
                regWrite = 1'b1; writeReg = rt; aluSrc = 1'b1; aluControl = ALU_OR;
            end
            OP_RTYPE: begin
                regWrite = 1'b1; writeReg = rd; aluSrc = 1'b0;
                case (funct)
                    F_ADD: aluControl = ALU_ADD;
                    F_SUB: aluControl = ALU_SUB;
                    F_AND: aluControl = ALU_AND;
                    F_OR:  aluControl = ALU_OR;
                    F_MUL: isMul      = 1'b1;   // resultado vem do MUL
                    default: ;                  // demais funct: ADD
                endcase
            end
            OP_JMP: begin
                jmpFlag    = 1'b1;
                jmpAddress = PROG_BASE + {6'b0, INST[25:0]}; // alvo absoluto (byte)
            end
            default: ; // NOP / opcode desconhecido -> CTRL neutro
        endcase

        CTRL = {branchFlag, isMul, aluControl, aluSrc,
                memToReg, memRead, memWrite, regWrite, writeReg};
    end
endmodule
