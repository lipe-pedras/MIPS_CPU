`timescale 1ns/1ps

module risc_TB;
    // =====================================================================
    // Portas do DUT (fig.1b) - 10 ports, nomes/case exatos do roteiro
    // =====================================================================
    reg         CLK, RST;
    reg  [31:0] Prog_BUS_READ, Data_BUS_READ;
    wire [31:0] Data_BUS_WRITE, ADDR, ADDR_Prog;
    wire        CS_P, CS, WE;

    risc DUT (
        .CLK            (CLK),
        .RST            (RST),
        .Prog_BUS_READ  (Prog_BUS_READ),
        .Data_BUS_READ  (Data_BUS_READ),
        .Data_BUS_WRITE (Data_BUS_WRITE),
        .ADDR           (ADDR),
        .ADDR_Prog      (ADDR_Prog),
        .CS_P           (CS_P),
        .CS             (CS),
        .WE             (WE)
    );

    // Clock de referencia da PLL = 50 MHz (periodo 20 ns) -> igual ao IP ALTPLL
    always #10 CLK = ~CLK;

    // =====================================================================
    // Sinais INTERNOS da fig.1b (nao sao portas) -> monitorados via
    // $init_signal_spy. Mirrors locais com (*keep=1*).
    // Obs.: CS_P, CS, WE, ADDR_Prog e ADDR sao PORTAS -> ligados direto,
    // NAO precisam de signal_spy.
    // =====================================================================
    (*keep=1*) reg         CLK_SYS;
    (*keep=1*) reg         CLK_MUL;
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
    (*keep=1*) reg  [9:0]  iAddress;
    (*keep=1*) reg  [31:0] internalAddress;
    (*keep=1*) reg         CS_WB;
    (*keep=1*) reg  [31:0] din;
    (*keep=1*) reg  [31:0] dout;
    (*keep=1*) reg  [31:0] writeBack;

    // =====================================================================
    // Amarracao dos sinais internos. $init_signal_spy precisa que o net
    // exista com esse nome no DUT: por isso as declaracoes internas em
    // risc.v tem (*keep=1*). Se um net for otimizado no gate-level, o spy
    // apenas emite warning (nao aborta) e aquele mirror fica em X.
    // =====================================================================
    initial begin
        $init_signal_spy("/risc_TB/DUT/CLK_SYS",         "/risc_TB/CLK_SYS", 1);
        $init_signal_spy("/risc_TB/DUT/CLK_MUL",         "/risc_TB/CLK_MUL", 1);
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
        $init_signal_spy("/risc_TB/DUT/iAddress",        "/risc_TB/iAddress", 1);
        $init_signal_spy("/risc_TB/DUT/internalAddress", "/risc_TB/internalAddress", 1);
        $init_signal_spy("/risc_TB/DUT/CS_WB",           "/risc_TB/CS_WB", 1);
        $init_signal_spy("/risc_TB/DUT/din",             "/risc_TB/din", 1);
        $init_signal_spy("/risc_TB/DUT/dout",            "/risc_TB/dout", 1);
        $init_signal_spy("/risc_TB/DUT/writeBack",       "/risc_TB/writeBack", 1);
    end

    // =====================================================================
    // Verificacao funcional (debug do fim -> inicio: linha writeBack no WB)
    // =====================================================================
    integer errors = 0;
    reg saw_wb496 = 0, saw_wb126480 = 0, saw_store126480 = 0;
    reg [31:0] prev_wb = 0;

    // sobreamostra no clock de referencia (CLK_SYS via spy poderia gerar
    // corrida de delta-cycle como borda de 'always')
    always @(posedge CLK) begin
        if (writeBack !== prev_wb && writeBack !== 32'h0) begin
            $display("t=%0t  writeBack=%h  ADDR=%h Data_BUS_WRITE=%h",
                     $time, writeBack, ADDR, Data_BUS_WRITE);
            prev_wb <= writeBack;
        end
        if (writeBack == 32'd496)    saw_wb496    <= 1'b1;   // r10 (soma 0+1+...+31 = 496)
        if (writeBack == 32'd126480) saw_wb126480 <= 1'b1;   // r20 (496*255=126480, MUL)
        // SW r20 -> ultima palavra de dados (0x18FF): via portas do top
        if ((ADDR == 32'h0000_18FF) && (Data_BUS_WRITE == 32'd126480))
            saw_store126480 <= 1'b1;
    end

    initial begin
        CLK = 0; RST = 1; Prog_BUS_READ = 0; Data_BUS_READ = 0;

        #3000 RST = 0;     // libera reset apos alguns ciclos de referencia
        #1000000;          // ~5880 ciclos de CLK_SYS (5.88 MHz) p/ rodar o prog

        $display("=== verificacao final (sinais nominais da fig.1b) ===");
        if (saw_wb496)       $display("OK   writeBack = 496    (r10 = soma de Mem[0..31])");
        else begin $display("FAIL writeBack nunca chegou a 496"); errors = errors + 1; end
        if (saw_wb126480)    $display("OK   writeBack = 126480 (r20 = 496*255, MUL no pipeline)");
        else begin $display("FAIL writeBack nunca chegou a 126480"); errors = errors + 1; end
        if (saw_store126480) $display("OK   SW: din=126480 -> Mem[0x18FF] (iWE/iAddress/din)");
        else begin $display("FAIL SW de 126480 nao ocorreu"); errors = errors + 1; end
        if (errors == 0) $display("risc_TB: PASS");
        else             $display("risc_TB: %0d ERRORS", errors);
        $finish;
    end
endmodule
