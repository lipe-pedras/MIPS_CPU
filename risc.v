// =============================================================================
// risc.v - TOP estrutural do processador RISC pipeline de 5 estagios.
//
// Liga todos os modulos conforme a fig. 1b do roteiro (memorias e banco de
// registradores sincronos). Estagios: IF | ID | EX | MEM | WB.
//
// -----------------------------------------------------------------------------
// AVALIACAO (respostas pedidas no roteiro):
//
// a) LATENCIA DO SISTEMA: o preenchimento (fill) do pipeline e de 5 ciclos de
//    CLK_SYS (IF, ID, EX, MEM, WB). A 1a instrucao conclui o WB no 5o ciclo.
//
// b) THROUGHPUT: apos o preenchimento, 1 instrucao por ciclo de CLK_SYS
//    (uma instrucao conclui o WB a cada borda de CLK_SYS).
//
// c) Fmax (TimeQuest, FPGA Cyclone IV GX - EP4CGX22CF19C7):
//    Resultados de sintese (Quartus 18.1) - pior caso Slow 1200mV 85C:
//      - Fmax do MULTIPLICADOR (dominio CLK/CLK_MUL): 257.93 MHz
//          (Restricted Fmax = 250.0 MHz, limitada pela taxa de toggle de I/O,
//           pois no modelo CLK entra por pino; com o ALTPLL real esse limite
//           de I/O some). Modelo Slow 0C: 279.02 MHz.
//      - Fmax do SISTEMA sem o MUL (dominio CLK_SYS): 40.97 MHz
//          (Modelo Slow 0C: 44.22 MHz).
//    Recursos: 2353 LEs (11%), 1375 regs, 65536 bits de RAM (2x1kWordx32),
//              0 multiplicadores embarcados (MUL sequencial usa LEs).
//    Metodologia: o TimeQuest reporta a maxima frequencia a partir do caminho
//    critico flip-flop -> flip-flop (Setup/Tsu), analisado por dominio de clock
//    (CLK_SYS e CLK/CLK_MUL sao clocks independentes -> analise separada).
//
// d) MAXIMA FREQUENCIA DE OPERACAO DO SISTEMA TOTAL:
//      Fmax_total = Fmax_MUL / 34   (limitada por Fmax_sistema_sem_MUL)
//    Raciocinio: o MUL tem latencia 2N+2 = 34 (N=16) ciclos de CLK_MUL e deve
//    entregar o produto DENTRO de um unico estagio EX (1 periodo de CLK_SYS).
//    Logo um periodo de CLK_SYS precisa conter 34 periodos de CLK_MUL =>
//    CLK_SYS = CLK_MUL/34. Numericamente (pior caso 85C):
//      Fmax_total = 257.93 MHz / 34 = 7.59 MHz.
//    Como 7.59 MHz < 40.97 MHz (Fmax_sistema_sem_MUL), o sistema total fica
//    LIMITADO pelo multiplicador a ~7.59 MHz. (Item f confirma essa ineficiencia.)
//
// e) METAESTABILIDADE: CLK_SYS e CLK_MUL sao dominios distintos. Os sinais de
//    handshake do MUL cruzam dominios e usam sincronizadores de 2 FF:
//      - St  : CLK_SYS -> CLK_MUL (FFs em CLK_MUL) + deteccao de borda (pulso);
//      - Done: CLK_MUL -> CLK_SYS (FFs em CLK_SYS).
//    O 1o FF pode entrar em metaestabilidade ao amostrar um sinal assincrono,
//    mas tem ~1 periodo para estabilizar antes do 2o FF amostrar, reduzindo
//    exponencialmente a probabilidade de propagacao (MTBF alto). Mitiga, mas
//    NAO elimina: ha risco residual nao-nulo (a estabilizacao nao e garantida
//    em tempo finito).
//
// f) EFICIENCIA DO MULTIPLICADOR: o multiplicador SEQUENCIAL (soma-e-desloca,
//    latencia 2N+2) NAO casa bem com o RISC: como o EX precisa acomodar 34
//    ciclos de CLK_MUL em 1 ciclo de CLK_SYS, forca CLK_SYS ~34x menor que
//    CLK_MUL, derrubando a frequencia do sistema (Fmax_total = Fmax_MUL/34).
//
// g) MODIFICACOES PARA AUMENTAR A FREQUENCIA:
//      - Multiplicador COMBINACIONAL (ou via DSP/embedded multiplier do Cyclone):
//        latencia do MUL = 0 ciclos extras (cabe no EX); throughput continua
//        1 instr/CLK_SYS, mas CLK_SYS deixa de ser limitado por /34.
//      - Multiplicador PIPELINED (ex.: arvore de Wallace pipelinada em k estagios):
//        latencia = k ciclos; throughput interno 1 mult/ciclo. Exigiria estender
//        o pipeline do RISC (ou stalls) -> latencia do sistema = 5 + (k-1).
//      Em ambos os casos elimina-se a divisao por 34 e Fmax_total ~ Fmax_sistema.
//      - Reduzir a latencia do MUL sequencial atual encurtando a FSM: omitindo
//        o estado S3 (e o sinal Done) -> latencia 2N+1 = 33; omitindo tambem o
//        estado S0 (e o sinal St) -> latencia 2N = 32. Isso melhora
//        Fmax_total = Fmax_MUL/32 (em vez de /34). POReM, St/Idle/Done sao
//        portas EXIGIDAS pela secao 4 e usadas pelos sincronizadores de 2 FF
//        (secao 6/item e); por isso a implementacao entregue mantem 2N+2 = 34.
// -----------------------------------------------------------------------------
//
// Convencao de reset: assincrono ativo-alto em todos os submodulos.
// =============================================================================
module risc (
    input         CLK,               // clock de referencia (entra na PLL = CLK_MUL)
    input         rst,               // reset assincrono ativo-alto
    input  [31:0] Prog_BUS_READ,     // barramento externo de instrucoes
    input  [31:0] Data_BUS_READ,     // barramento externo de leitura de dados
    output [31:0] Data_BUS_WRITE,    // barramento externo de escrita de dados
    output [31:0] ADDR               // endereco externo de dados
);
    // ---- clocks da PLL ----
    (*keep=1*) wire CLK_SYS;
    (*keep=1*) wire CLK_MUL;
    wire            pll_locked;

    PLL pll (
        .inclk0 (CLK),
        .areset (rst),
        .c0     (CLK_SYS),
        .c1     (CLK_MUL),
        .locked (pll_locked)
    );

    // =========================================================================
    // Sinais nominais (fig. 1b) - (*keep=1*) para preservar nomes em Gate Level
    // =========================================================================
    (*keep=1*) wire        CS_P;
    (*keep=1*) wire [31:0] ADDR_Prog;
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
    (*keep=1*) wire        WE;
    (*keep=1*) wire [9:0]  iAddress;
    (*keep=1*) wire [31:0] internalAddress;
    (*keep=1*) wire        CS;
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
        .rst          (rst),
        .jmpFlag      (jmpFlag),
        .jmpAddress   (jmpAddress),
        .branchFlag   (branchFlag),     // branchFlag do EX (CTRL[14])
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

    // PC+4 pipelinado para o calculo do alvo do BNE no EX
    wire [31:0] IF_ID_PC4_q, ID_EX_PC4_q;
    register #(.WIDTH(32)) IF_ID_PC4 (.clk(CLK_SYS), .rst(rst), .d(pc4),         .q(IF_ID_PC4_q));
    register #(.WIDTH(32)) ID_EX_PC4 (.clk(CLK_SYS), .rst(rst), .d(IF_ID_PC4_q), .q(ID_EX_PC4_q));

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

    // RegisterFile escrito na PRIMEIRA METADE do ciclo (convencao classica do
    // pipeline de 5 estagios sem forwarding): como registerfile.v escreve em
    // 'posedge clk', conectamos clk = ~CLK_SYS para que a escrita do WB ocorra
    // na borda de descida (meio do ciclo). Assim a leitura assincrona do ID, no
    // MESMO ciclo do WB do produtor, ja enxerga o valor novo -> a distancia de
    // hazard cai de 3 para 2 NOPs (compativel com prog_avaliacao). Nao altera a
    // interface do banco; apenas a fase do clock de escrita.
    registerfile regfile (
        .clk        (~CLK_SYS),
        .reset      (rst),
        .wr         (wb_regWrite),
        .dataIn     (writeBack),
        .wrAddress  (wb_writeReg),
        .rdAddress1 (rdAddress1),
        .rdAddress2 (rdAddress2),
        .dataOut1   (rsVal),
        .dataOut2   (rtVal)
    );

    extend ext (.INST(INST), .SignExtImm(SignExtImm));

    register #(.WIDTH(32)) ID_EX_IMM  (.clk(CLK_SYS), .rst(rst), .d(SignExtImm), .q(IMM));
    register #(.WIDTH(15)) ID_EX_CTRL (.clk(CLK_SYS), .rst(rst), .d(CTRL_id),    .q(CTRL));
    register #(.WIDTH(32)) ID_EX_A    (.clk(CLK_SYS), .rst(rst), .d(rsVal),      .q(A));
    register #(.WIDTH(32)) ID_EX_B    (.clk(CLK_SYS), .rst(rst), .d(rtVal),      .q(B));

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

    // -------- Multiplicador (dominio CLK_MUL) + sincronizadores de 2 FF --------
    wire mulSt;
    wire st_s1, st_s2, st_d;         // sincronizador St (CLK_SYS -> CLK_MUL) + borda
    register #(.WIDTH(1)) st_sync1 (.clk(CLK_MUL), .rst(rst), .d(ex_isMul), .q(st_s1));
    register #(.WIDTH(1)) st_sync2 (.clk(CLK_MUL), .rst(rst), .d(st_s1),    .q(st_s2));
    register #(.WIDTH(1)) st_edge  (.clk(CLK_MUL), .rst(rst), .d(st_s2),    .q(st_d));
    assign mulSt = st_s2 & ~st_d;    // pulso de 1 CLK_MUL na borda de subida

    Multiplicador MUL (
        .Multiplicando (A[15:0]),
        .Multiplicador (B[15:0]),
        .St            (mulSt),
        .Clk           (CLK_MUL),
        .rst           (rst),
        .Produto       (Produto),
        .Idle          (mulIdle),
        .Done          (mulDone)
    );

    wire done_s1, done_sys;          // sincronizador Done (CLK_MUL -> CLK_SYS)
    register #(.WIDTH(1)) done_sync1 (.clk(CLK_SYS), .rst(rst), .d(mulDone),  .q(done_s1));
    register #(.WIDTH(1)) done_sync2 (.clk(CLK_SYS), .rst(rst), .d(done_s1),  .q(done_sys));

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
    register #(.WIDTH(15)) EX_MEM_CTRL (.clk(CLK_SYS), .rst(rst), .d(CTRL),  .q(CTRL_mem));
    register #(.WIDTH(32)) EX_MEM_IMM  (.clk(CLK_SYS), .rst(rst), .d(IMM),   .q(IMM_mem));
    register #(.WIDTH(32)) EX_MEM_D    (.clk(CLK_SYS), .rst(rst), .d(D_ex),  .q(D));
    register #(.WIDTH(32)) EX_MEM_B    (.clk(CLK_SYS), .rst(rst), .d(B),     .q(din)); // store data

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
    register #(.WIDTH(1)) CS_WB_reg (.clk(CLK_SYS), .rst(rst), .d(CS), .q(CS_WB));

    // registradores MEM/WB
    wire [31:0] D_wb;
    register #(.WIDTH(15)) MEM_WB_CTRL (.clk(CLK_SYS), .rst(rst), .d(CTRL_mem), .q(CTRL_wb));
    register #(.WIDTH(32)) MEM_WB_D    (.clk(CLK_SYS), .rst(rst), .d(D),        .q(D_wb));

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
    register #(.WIDTH(1)) jmpFlush_reg    (.clk(CLK_SYS), .rst(rst), .d(jmpFlag),     .q(jmpFlag_d));
    register #(.WIDTH(1)) branchFlush_reg (.clk(CLK_SYS), .rst(rst), .d(branchTaken), .q(branchTaken_d));

    assign flush = jmpFlag_d | branchTaken | branchTaken_d;

endmodule
