// =============================================================================
// FPGA: Cyclone IV GX EP4CGX150DF31I7AD (maior nro de pinos da familia; escolhido
//   porque o top expoe 10 ports com varios barramentos de 32 bits e nao cabia no
//   EP4CGX22). Clock de referencia unico da placa: CLK = 50 MHz.
//
// a) LATENCIA DO SISTEMA: 5 ciclos de CLK_SYS (preenchimento do pipeline
//    IF|ID|EX|MEM|WB; a 1a instrucao conclui o WB no 5o ciclo).
//
// b) THROUGHPUT: 1 instrucao por ciclo de CLK_SYS (apos o preenchimento).
//
// c) Fmax do TimeQuest (medidas isoladas, Slow 85C) no dispositivo EP4CGX150DF31I7AD;
//      - Multiplicador: Fmax = 291.63; Restricted Fmax = 250.00 MHz
//        adota-se 250 MHz (a Restricted manda: limite fisico do clock do
//        dispositivo, abaixo da Fmax pura do caminho critico).
//      - Sistema (nucleo RISC sem o MUL): Fmax: 89.22 MHz; Restricted Fmax: 89.22 MHz.
//
// d) MAXIMA FREQUENCIA DE OPERACAO DO SISTEMA:
//      Fmax_teorico = Fmax_CLK_MUL / 34 = 5,88 MHz (menor do que Fmax do sistema)
//    O MUL sequencial tem latencia 2N+2 = 34 CLK_MUL e deve entregar o produto
//    dentro de 1 estagio EX (1 CLK_SYS) -> razao da PLL 34:1. 
//
//		Para adicionar um tempo de slack e garantir o funcionamento do sistema, 
//		foi utilizada uma frequencia de 200 MHz, multiplicando a frequencia de
//		entrada da PLL por 4.
//
//    
// e) Nao ha risco de metaestabilidade. CLK_SYS e CLK_MUL vem da mesma PLL, razao
//    inteira 34:1 e fase 0, ou seja, clocks mesocronos, nao dominios assincronos. 
//    So haveria risco se os clocks fossem realmente assincronos
//    (PLLs/osciladores independentes).
//
// f) Nao e eficiente. O MUL SEQUENCIAL (latencia 2N+2 = 34) 
//    obriga o estagio EX a caber 34 CLK_MUL em 1 CLK_SYS, forcando CLK_SYS
//    ~34x menor que CLK_MUL: o nucleo aguentaria 89.22 MHz mas o sistema opera a
//    ~5.88 MHz, logo o MUL e o gargalo.
//
// g) MODIFICACOES PARA AUMENTAR A FREQUENCIA:
//      - MUL COMBINACIONAL (ou DSP/embedded multiplier): 0 ciclos extras, cabe no
//        EX -> elimina o /34. Latencia = 5 ciclos; throughput = 1 instr/ciclo.
//      - MUL PIPELINED em k estagios: exige estender o pipeline em k-1 estagios.
//        Latencia = 5 + (k-1) ciclos; throughput = 1 instr/ciclo. Tambem elimina
//        o /34 -> Fmax_total ~ Fmax_sistema.
//      - Encurtar a FSM do MUL sequencial (omitir estados) -> latencia 2N = 32 ->
//        Fmax_total = Fmax_MUL/32.
// -----------------------------------------------------------------------------
//
// Convencao de reset: assincrono ativo-alto em todos os submodulos.
// =============================================================================
module risc (
    input         CLK,               // clock de referencia da PLL (50 MHz)
    input         RST,               // reset assincrono ativo-alto
    input  [31:0] Prog_BUS_READ,     // barramento de instrucao externo
    input  [31:0] Data_BUS_READ,     // barramento de dados externo (leitura)
    output [31:0] Data_BUS_WRITE,    // barramento de dados externo (escrita)
    output [31:0] ADDR,              // endereco de dados (MEM)
    output [31:0] ADDR_Prog,         // endereco de programa (IF)
    output        CS_P,              // chip-select programa (interno x externo)
    output        CS,                // chip-select dados (interno x externo)
    output        WE                 // write-enable de dados externo
);
    // ---- clocks da PLL ----
    (*keep=1*) wire CLK_SYS;
    (*keep=1*) wire CLK_MUL;
    wire            pll_locked;

    PLL pll (
        .inclk0 (CLK),
        .areset (RST),
        .c0     (CLK_SYS),
        .c1     (CLK_MUL),
        .locked (pll_locked)
    );

    // =========================================================================
    // Sinais nominais
    // =========================================================================
    // CS_P e ADDR_Prog agora sao portas de saida (fig.1b)
    (*keep=1*) wire [31:0] INST;
    (*keep=1*) wire [31:0] IMM;
    (*keep=1*) wire [14:0] CTRL;
    (*keep=1*) wire [31:0] A;
    (*keep=1*) wire [31:0] B;
    (*keep=1*) wire [31:0] D;
    (*keep=1*) wire [31:0] M;
    (*keep=1*) wire        branchFlag;
    (*keep=1*) wire [31:0] branchOffset;
    (*keep=1*) wire        zeroFlag;
    (*keep=1*) wire        jmpFlag;
    (*keep=1*) wire [31:0] jmpAddress;
    (*keep=1*) wire        iWE;
    // WE e CS agora sao portas de saida (fig.1b)
    (*keep=1*) wire [9:0]  iAddress;
    (*keep=1*) wire [31:0] internalAddress;
    (*keep=1*) wire        CS_WB;
    (*keep=1*) wire [31:0] din;
    (*keep=1*) wire [31:0] dout;
    (*keep=1*) wire [31:0] writeBack;

    // =========================================================================
    // IF - Instruction Fetch
    // =========================================================================
    wire [9:0]  iADDR_Prog;
    wire [31:0] instInternal;
    wire [31:0] instSel;
    wire [31:0] pc4 = ADDR_Prog + 32'd4;

    pc pcounter (
        .clk          (CLK_SYS),
        .rst          (RST),
        .jmpFlag      (jmpFlag),
        .jmpAddress   (jmpAddress),
        .branchFlag   (branchFlag),    
        .zeroFlag     (zeroFlag),
        .branchOffset (branchOffset),
        .pc           (ADDR_Prog)
    );

    ADDRDecoding_Prog addrdec_prog (
        .ADDR_Prog (ADDR_Prog),
        .CS_P      (CS_P),
        .iADDR     (iADDR_Prog)
    );

    InstMem instmem (
        .clock  (CLK_SYS),
        .address (iADDR_Prog),
		  .data(32'h0),
		  .wren(0),
        .q (instInternal)
    );

    // selecao instrucao interna x externa
    mux #(.WIDTH(32)) instSelMux (
        .sel (CS_P),
        .in0 (Prog_BUS_READ),
        .in1 (instInternal),
        .out (instSel)
    );

    // flush: injeta NOP (bolha) em desvio tomado (JMP / BNE)
    wire flush;
    mux #(.WIDTH(32)) flushMux (
        .sel (flush),
        .in0 (instSel),
        .in1 (32'h0000_0000),
        .out (INST)
    );

    wire [31:0] IF_ID_PC4_q, ID_EX_PC4_q;
    register #(.WIDTH(32)) IF_ID_PC4 (.clk(CLK_SYS), .rst(RST), .d(pc4),         .q(IF_ID_PC4_q));
    register #(.WIDTH(32)) ID_EX_PC4 (.clk(CLK_SYS), .rst(RST), .d(IF_ID_PC4_q), .q(ID_EX_PC4_q));

    // =========================================================================
    // ID - Instruction Decode
    // =========================================================================
    wire [4:0]  rdAddress1, rdAddress2;
    wire [14:0] CTRL_id;
    wire [31:0] SignExtImm;
    wire [31:0] rsVal, rtVal;

    control ctrl (
        .INST       (INST),
        .rdAddress1 (rdAddress1),
        .rdAddress2 (rdAddress2),
        .CTRL       (CTRL_id),
        .jmpFlag    (jmpFlag),
        .jmpAddress (jmpAddress)
    );

    // campos do CTRL no estagio WB (escrita do banco)
    wire [14:0] CTRL_wb;
    wire [4:0]  wb_writeReg = CTRL_wb[4:0];
    wire        wb_regWrite = CTRL_wb[5];

    registerfile regfile (
        .clk        (CLK_SYS),
        .reset      (RST),
        .wr         (wb_regWrite),
        .dataIn     (writeBack),
        .wrAddress  (wb_writeReg),
        .rdAddress1 (rdAddress1),
        .rdAddress2 (rdAddress2),
        .dataOut1   (rsVal),
        .dataOut2   (rtVal)
    );

    extend ext (.INST(INST), .SignExtImm(SignExtImm));

    // -------- Bypass "write-first" (read-during-write) --------------------
    // registerfile.v escreve em posedge, simultaneo aos registradoes 
	 // A e B: o valor escrito no WB so apareceria na leitura assincrona 
    // do ID no ciclo seguinte (exigindo 3 NOPs). Para casar com os 
    // 2 NOPs do prog_avaliacao, encaminhamos combinacionalmente o 
    // writeBack quando o registrador lido no ID e exatamente o que o WB esta 
    // escrevendo neste ciclo (mesmo endereco, escrita ativa, != r0).
    wire bypass1 = wb_regWrite && (wb_writeReg != 5'd0) && (wb_writeReg == rdAddress1);
    wire bypass2 = wb_regWrite && (wb_writeReg != 5'd0) && (wb_writeReg == rdAddress2);
    wire [31:0] rsVal_bp = bypass1 ? writeBack : rsVal;
    wire [31:0] rtVal_bp = bypass2 ? writeBack : rtVal;

    register #(.WIDTH(32)) ID_EX_IMM  (.clk(CLK_SYS), .rst(RST), .d(SignExtImm), .q(IMM));
    register #(.WIDTH(15)) ID_EX_CTRL (.clk(CLK_SYS), .rst(RST), .d(CTRL_id),    .q(CTRL));
    register #(.WIDTH(32)) ID_EX_A    (.clk(CLK_SYS), .rst(RST), .d(rsVal_bp),   .q(A));
    register #(.WIDTH(32)) ID_EX_B    (.clk(CLK_SYS), .rst(RST), .d(rtVal_bp),   .q(B));

    // =========================================================================
    // EX - Execute
    // =========================================================================
    // campos do CTRL no estagio EX
    wire       ex_memWrite   = CTRL[6];
    wire       ex_aluSrc     = CTRL[9];
    wire [2:0] ex_aluControl = CTRL[12:10];
    wire       ex_isMul      = CTRL[13];
    assign     branchFlag    = CTRL[14];

    wire [31:0] aluB, aluResult, Produto;
    wire        mulIdle, mulDone;

    // IMM_MUX: 2o operando da ALU = IMM (aluSrc=1) ou B (aluSrc=0)
    mux #(.WIDTH(32)) IMM_MUX (
        .sel (ex_aluSrc),
        .in0 (B),
        .in1 (IMM),
        .out (aluB)
    );

    alu #(.WIDTH(32)) alu_ex (
        .A          (A),
        .B          (aluB),
        .aluControl (ex_aluControl),
        .result     (aluResult),
        .zeroFlag   (zeroFlag)
    );

    Multiplicador MUL (
        .Multiplicando (A[15:0]),
        .Multiplicador (B[15:0]),
        .St            (ex_isMul),
        .Clk           (CLK_MUL),
        .rst           (RST),
        .Produto       (Produto),
        .Idle          (mulIdle),
        .Done          (mulDone)
		 );

    // ALU_MUL_MUX: resultado do EX = MUL (isMul=1) ou ALU (isMul=0)
    wire [31:0] D_ex;
    mux #(.WIDTH(32)) ALU_MUL_MUX (
        .sel (ex_isMul),
        .in0 (aluResult),
        .in1 (Produto),
        .out (D_ex)
    );

    // alvo do BNE = (PC_da_BNE + 4) + offset  (ja inclui o +4)
    assign branchOffset = ID_EX_PC4_q + IMM;

    // registradores EX/MEM
    wire [14:0] CTRL_mem;
    wire [31:0] IMM_mem;
    register #(.WIDTH(15)) EX_MEM_CTRL (.clk(CLK_SYS), .rst(RST), .d(CTRL),  .q(CTRL_mem));
    register #(.WIDTH(32)) EX_MEM_IMM  (.clk(CLK_SYS), .rst(RST), .d(IMM),   .q(IMM_mem));
    register #(.WIDTH(32)) EX_MEM_D    (.clk(CLK_SYS), .rst(RST), .d(D_ex),  .q(D));
    register #(.WIDTH(32)) EX_MEM_B    (.clk(CLK_SYS), .rst(RST), .d(B),     .q(din)); // store data

    // =========================================================================
    // MEM - Memory
    // =========================================================================
    wire mem_memWrite = CTRL_mem[6];

    ADDRDecoding addrdec (
        .D               (D),
        .we              (mem_memWrite),
        .CS              (CS),
        .internalAddress (internalAddress),
        .iAddress        (iAddress),
        .iWE             (iWE),
        .WE              (WE),
        .ADDR            (ADDR)
    );

    datamemory datamem (
        .clock  (CLK_SYS),
        .address (iAddress),
        .data  (din),
        .wren   (iWE),
        .q (dout)
    );

    assign Data_BUS_WRITE = din;   // escrita externa

    // CS_WB alinha o chip-select com a leitura sincrona (dout valido no WB)
    register #(.WIDTH(1)) CS_WB_reg (.clk(CLK_SYS), .rst(RST), .d(CS), .q(CS_WB));

    // registradores MEM/WB
    wire [31:0] D_wb;
    register #(.WIDTH(15)) MEM_WB_CTRL (.clk(CLK_SYS), .rst(RST), .d(CTRL_mem), .q(CTRL_wb));
    register #(.WIDTH(32)) MEM_WB_D    (.clk(CLK_SYS), .rst(RST), .d(D),        .q(D_wb));

    // =========================================================================
    // WB - Write Back
    // =========================================================================
    wire wb_memToReg = CTRL_wb[8];

    // selecao dado de memoria interno x externo
    mux #(.WIDTH(32)) dataSelMux (
        .sel (CS_WB),
        .in0 (Data_BUS_READ),
        .in1 (dout),
        .out (M)
    );

    // writeBack: dado de memoria (LW) x resultado ALU/MUL
    mux #(.WIDTH(32)) writeBackMux (
        .sel (wb_memToReg),
        .in0 (D_wb),
        .in1 (M),
        .out (writeBack)
    );

    // =========================================================================
    // Hazards de controle - logica de FLUSH (bolhas no IF)
    //   JMP  (resolvido no ID) -> 1 flush  = jmpFlag atrasado 1 ciclo
    //   BNE  (resolvido no EX) -> 2 flushes = branchTaken atual + atrasado 1
    // =========================================================================
    wire branchTaken = branchFlag & ~zeroFlag;
    wire jmpFlag_d, branchTaken_d;
    register #(.WIDTH(1)) jmpFlush_reg    (.clk(CLK_SYS), .rst(RST), .d(jmpFlag),     .q(jmpFlag_d));
    register #(.WIDTH(1)) branchFlush_reg (.clk(CLK_SYS), .rst(RST), .d(branchTaken), .q(branchTaken_d));

    assign flush = jmpFlag_d | branchTaken | branchTaken_d;

endmodule
