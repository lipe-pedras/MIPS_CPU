`timescale 1ns/1ps
// =============================================================================
// risc_TB.v - TestBench do TOP. Roda o programa gravado na InstMem (Code.hex)
// sobre a DataMemory (Data.hex) e monitora os sinais nominais da fig. 1b.
//
// IMPORTANTE (compatibilidade Gate Level): na sintese a hierarquia interna e
// achatada/renomeada, entao o TB NAO acessa sinais por caminho hierarquico
// (DUT.<...>). Em vez disso, todos os sinais nominais da fig. 1b sao marcados
// com (*keep=1*) em risc.v e aqui espelhados por $init_signal_spy. Toda a
// monitoracao e verificacao usam SOMENTE esses sinais espelhados -> o mesmo
// TB roda em RTL e em Gate Level.
//
// O clock CLK (entrada da PLL) e identico ao definido no IP: CLK = CLK_MUL.
// CLK_SYS = CLK_MUL / 34 (ver PLL.v).
// =============================================================================
module risc_TB;
    reg         CLK, rst;
    reg  [31:0] Prog_BUS_READ, Data_BUS_READ;
    wire [31:0] Data_BUS_WRITE, ADDR;

    risc DUT (
        .CLK            (CLK),
        .rst            (rst),
        .Prog_BUS_READ  (Prog_BUS_READ),
        .Data_BUS_READ  (Data_BUS_READ),
        .Data_BUS_WRITE (Data_BUS_WRITE),
        .ADDR           (ADDR)
    );

    // ---- clock de referencia: DEVE ser igual a entrada definida no IP ALTPLL ----
    // O ALTPLL foi configurado com inclk0_input_frequency = 4270 ps (= 4.27 ns,
    // 234.19 MHz). Logo CLK (= inclk0 = CLK_MUL) tem periodo de 4.27 ns -> #2.135.
    // (CLK_SYS = c0 = CLK/34 = 6.888 MHz, 145 ns.)  Se o periodo do TB nao casar
    // com o do IP, a PLL nao trava ("input over VCO range") e o nucleo congela.
    // FREQUENCIA REDUZIDA para o caminho do produto do MUL fechar em Slow 85C.
    always #2.135 CLK = ~CLK;

    // =====================================================================
    // Sinais nominais da fig. 1b espelhados via $init_signal_spy (destinos
    // precisam ser 'reg'). Estes sao os UNICOS sinais usados na verificacao.
    // =====================================================================
    (*keep=1*) reg         CLK_SYS;
    (*keep=1*) reg         CLK_MUL;
    (*keep=1*) reg         CS_P;
    (*keep=1*) reg  [31:0] ADDR_Prog;
    (*keep=1*) reg  [31:0] INST;
    (*keep=1*) reg  [31:0] IMM;
    (*keep=1*) reg  [14:0] CTRL;
    (*keep=1*) reg  [31:0] A;
    (*keep=1*) reg  [31:0] B;
    (*keep=1*) reg  [31:0] D;
    (*keep=1*) reg  [31:0] M;
    (*keep=1*) reg         branchFlag;
    (*keep=1*) reg  [31:0] branchOffset;
    (*keep=1*) reg         zeroFlag;
    (*keep=1*) reg         jmpFlag;
    (*keep=1*) reg  [31:0] jmpAddress;
    (*keep=1*) reg         iWE;
    (*keep=1*) reg         WE;
    (*keep=1*) reg  [9:0]  iAddress;
    (*keep=1*) reg  [31:0] internalAddress;
    (*keep=1*) reg         CS;
    (*keep=1*) reg         CS_WB;
    (*keep=1*) reg  [31:0] din;
    (*keep=1*) reg  [31:0] dout;
    (*keep=1*) reg  [31:0] writeBack;

    initial begin
        $init_signal_spy("/risc_TB/DUT/CLK_SYS",         "/risc_TB/CLK_SYS", 1);
        $init_signal_spy("/risc_TB/DUT/CLK_MUL",         "/risc_TB/CLK_MUL", 1);
        $init_signal_spy("/risc_TB/DUT/CS_P",            "/risc_TB/CS_P", 1);
        $init_signal_spy("/risc_TB/DUT/ADDR_Prog",       "/risc_TB/ADDR_Prog", 1);
        $init_signal_spy("/risc_TB/DUT/INST",            "/risc_TB/INST", 1);
        $init_signal_spy("/risc_TB/DUT/IMM",             "/risc_TB/IMM", 1);
        $init_signal_spy("/risc_TB/DUT/CTRL",            "/risc_TB/CTRL", 1);
        $init_signal_spy("/risc_TB/DUT/A",               "/risc_TB/A", 1);
        $init_signal_spy("/risc_TB/DUT/B",               "/risc_TB/B", 1);
        $init_signal_spy("/risc_TB/DUT/D",               "/risc_TB/D", 1);
        $init_signal_spy("/risc_TB/DUT/M",               "/risc_TB/M", 1);
        $init_signal_spy("/risc_TB/DUT/branchFlag",      "/risc_TB/branchFlag", 1);
        $init_signal_spy("/risc_TB/DUT/branchOffset",    "/risc_TB/branchOffset", 1);
        $init_signal_spy("/risc_TB/DUT/zeroFlag",        "/risc_TB/zeroFlag", 1);
        $init_signal_spy("/risc_TB/DUT/jmpFlag",         "/risc_TB/jmpFlag", 1);
        $init_signal_spy("/risc_TB/DUT/jmpAddress",      "/risc_TB/jmpAddress", 1);
        $init_signal_spy("/risc_TB/DUT/iWE",             "/risc_TB/iWE", 1);
        $init_signal_spy("/risc_TB/DUT/WE",              "/risc_TB/WE", 1);
        $init_signal_spy("/risc_TB/DUT/iAddress",        "/risc_TB/iAddress", 1);
        $init_signal_spy("/risc_TB/DUT/internalAddress", "/risc_TB/internalAddress", 1);
        $init_signal_spy("/risc_TB/DUT/CS",              "/risc_TB/CS", 1);
        $init_signal_spy("/risc_TB/DUT/CS_WB",           "/risc_TB/CS_WB", 1);
        $init_signal_spy("/risc_TB/DUT/din",             "/risc_TB/din", 1);
        $init_signal_spy("/risc_TB/DUT/dout",            "/risc_TB/dout", 1);
        $init_signal_spy("/risc_TB/DUT/writeBack",       "/risc_TB/writeBack", 1);
    end

    // =====================================================================
    // Monitoracao + verificacao (apenas sinais nominais espelhados).
    // O programa termina em 'jmp Main' (laco infinito); por isso os
    // resultados do 2o laco (com bolhas) sao LATCHED no instante em que
    // ocorrem, e nao amostrados no fim da simulacao.
    //
    //   r10 = soma de Mem[0..31] = 0+1+...+9 = 45      -> writeBack == 45
    //   r20 = 45 * 255 = 11475 (MUL no pipeline)        -> writeBack == 11475
    //   SW r20 -> Mem[0x18FF] (ultima palavra, idx 1023): iWE & iAddress & din
    // =====================================================================
    // Em Gate Level, sinais de 1 bit e o clock dividido CLK_SYS costumam ser
    // otimizados/renomeados pela sintese (o roteiro avisa que (*keep*) pode
    // perder sinais). Por isso a verificacao amostra no CLK do testbench
    // (sempre presente) e usa:
    //   - writeBack  (barramento que sobrevive a sintese, via $init_signal_spy);
    //   - Data_BUS_WRITE / ADDR (PORTAS do top -> nunca otimizadas) p/ o SW.
    integer errors = 0;
    reg saw_wb45 = 0, saw_wb11475 = 0, saw_store11475 = 0;
    reg [31:0] prev_wb = 0;

    always @(posedge CLK) begin
        if (writeBack !== prev_wb && writeBack !== 32'h0) begin
            $display("t=%0t  writeBack=%h  ADDR=%h Data_BUS_WRITE=%h",
                     $time, writeBack, ADDR, Data_BUS_WRITE);
            prev_wb <= writeBack;
        end
        if (writeBack == 32'd45)    saw_wb45    <= 1'b1;   // r10 (soma correta)
        if (writeBack == 32'd11475) saw_wb11475 <= 1'b1;   // r20 (soma*255, MUL)
        // SW r20 -> ultima palavra de dados (0x18FF): via portas do top
        if ((ADDR == 32'h0000_18FF) && (Data_BUS_WRITE == 32'd11475))
            saw_store11475 <= 1'b1;
    end

    initial begin
        CLK = 0; rst = 1; Prog_BUS_READ = 0; Data_BUS_READ = 0;
        // O ALTPLL real leva alguns us para TRAVAR (locked). O nucleo deve
        // permanecer em reset ate la, senao roda em um clock instavel e corrompe
        // o pipeline. Mantemos rst alto ate bem depois do lock da PLL.
        #3000 rst = 0;
        #500000;                // tempo p/ os 2 lacos (vetor de 32) + MUL + SW
                                // (CLK_SYS=272ns @125MHz/34 -> ~1.7x do periodo antigo)
        $display("=== verificacao final (sinais nominais da fig.1b) ===");
        if (saw_wb45)       $display("OK   writeBack = 45     (r10 = soma de Mem[0..31])");
        else begin $display("FAIL writeBack nunca chegou a 45"); errors = errors + 1; end
        if (saw_wb11475)    $display("OK   writeBack = 11475  (r20 = 45*255, MUL no pipeline)");
        else begin $display("FAIL writeBack nunca chegou a 11475"); errors = errors + 1; end
        if (saw_store11475) $display("OK   SW: din=11475 -> Mem[0x18FF] (iWE/iAddress/din)");
        else begin $display("FAIL SW de 11475 nao ocorreu"); errors = errors + 1; end
        if (errors == 0) $display("risc_TB: PASS");
        else             $display("risc_TB: %0d ERRORS", errors);
        $finish;
    end
endmodule
