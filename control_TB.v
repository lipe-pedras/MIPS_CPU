`timescale 1ns/1ps
// TestBench da unidade de controle: verifica a decodificacao de cada instrucao.
module control_TB;
    reg  [31:0] INST;
    wire [4:0]  rdAddress1, rdAddress2;
    wire [14:0] CTRL;
    wire        jmpFlag;
    wire [31:0] jmpAddress;
    integer     errors = 0;

    control DUT (.INST(INST), .rdAddress1(rdAddress1), .rdAddress2(rdAddress2),
                 .CTRL(CTRL), .jmpFlag(jmpFlag), .jmpAddress(jmpAddress));

    // campos do CTRL
    wire [4:0] writeReg   = CTRL[4:0];
    wire       regWrite   = CTRL[5];
    wire       memWrite   = CTRL[6];
    wire       memRead    = CTRL[7];
    wire       memToReg   = CTRL[8];
    wire       aluSrc     = CTRL[9];
    wire [2:0] aluControl = CTRL[12:10];
    wire       isMul      = CTRL[13];
    wire       branchFlag = CTRL[14];

    task fail; input [127:0] msg; begin
        $display("FAIL [%0s] INST=%h CTRL=%h", msg, INST, CTRL);
        errors = errors + 1;
    end endtask

    initial begin
        // LW r1, x(r2): op=35 rs=2 rt=1
        INST = (35<<26)|(2<<21)|(1<<16)|16'h0004; #1;
        if (!(rdAddress1==2 && rdAddress2==1 && regWrite && memRead && memToReg
              && aluSrc && writeReg==1 && aluControl==3'b000)) fail("LW");

        // SW r1, x(r2): op=36 rs=2 rt=1
        INST = (36<<26)|(2<<21)|(1<<16)|16'h0008; #1;
        if (!(memWrite && !regWrite && aluSrc && aluControl==3'b000)) fail("SW");

        // BNE r1,r2,off: op=37
        INST = (37<<26)|(1<<21)|(2<<16)|16'hFFF0; #1;
        if (!(branchFlag && !regWrite && !aluSrc && aluControl==3'b001)) fail("BNE");

        // ADDI r1, x(r2): op=38
        INST = (38<<26)|(2<<21)|(1<<16)|16'd5; #1;
        if (!(regWrite && writeReg==1 && aluSrc && aluControl==3'b000)) fail("ADDI");

        // ORI r1, x(r2): op=39
        INST = (39<<26)|(2<<21)|(1<<16)|16'h00FF; #1;
        if (!(regWrite && writeReg==1 && aluSrc && aluControl==3'b011)) fail("ORI");

        // ADD r3,r1,r2: op=13 funct=32
        INST = (13<<26)|(1<<21)|(2<<16)|(3<<11)|(10<<6)|32; #1;
        if (!(regWrite && writeReg==3 && !aluSrc && aluControl==3'b000 && !isMul)) fail("ADD");

        // SUB r3,r1,r2: funct=34
        INST = (13<<26)|(1<<21)|(2<<16)|(3<<11)|(10<<6)|34; #1;
        if (!(regWrite && aluControl==3'b001)) fail("SUB");

        // AND funct=36
        INST = (13<<26)|(1<<21)|(2<<16)|(3<<11)|(10<<6)|36; #1;
        if (!(regWrite && aluControl==3'b010)) fail("AND");

        // OR funct=37
        INST = (13<<26)|(1<<21)|(2<<16)|(3<<11)|(10<<6)|37; #1;
        if (!(regWrite && aluControl==3'b011)) fail("OR");

        // MUL funct=50
        INST = (13<<26)|(1<<21)|(2<<16)|(3<<11)|(10<<6)|50; #1;
        if (!(regWrite && writeReg==3 && isMul)) fail("MUL");

        // JMP op=2 addr=0x40
        INST = (2<<26)|26'h40; #1;
        if (!(jmpFlag && jmpAddress==(32'h900+32'h40))) fail("JMP");

        // NOP = 0 -> tudo neutro
        INST = 32'h0; #1;
        if (!(CTRL==15'h0 && !jmpFlag)) fail("NOP");

        if (errors == 0) $display("control_TB: PASS");
        else             $display("control_TB: %0d ERRORS", errors);
        $finish;
    end
endmodule
