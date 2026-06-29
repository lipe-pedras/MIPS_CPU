`timescale 1ns/1ps
// TestBench da unidade de controle: verifica a decodificacao de cada instrucao.
module control_TB;
    reg  [31:0] INST;
    wire [4:0]  rdAddress1, rdAddress2;
    wire [14:0] CTRL;
    wire        jmpFlag;
    wire [31:0] jmpAddress;

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

   

    initial begin
		  // LW r1, x(r2): op=35 rs=2 rt=1
        INST = (35<<26)|(2<<21)|(1<<16)|16'h0004; #1;
        

        // SW r1, x(r2): op=36 rs=2 rt=1
        INST = (36<<26)|(2<<21)|(1<<16)|16'h0008; #1;
        

        // BNE r1,r2,off: op=37
        INST = (37<<26)|(1<<21)|(2<<16)|16'hFFF0; #1;

        // ADDI r1, x(r2): op=38
        INST = (38<<26)|(2<<21)|(1<<16)|16'd5; #1;

        // ORI r1, x(r2): op=39
        INST = (39<<26)|(2<<21)|(1<<16)|16'h00FF; #1;

        // ADD r3,r1,r2: op=13 funct=32
        INST = (13<<26)|(1<<21)|(2<<16)|(3<<11)|(10<<6)|32; #1;

        // SUB r3,r1,r2: funct=34
        INST = (13<<26)|(1<<21)|(2<<16)|(3<<11)|(10<<6)|34; #1;

        // AND funct=36
        INST = (13<<26)|(1<<21)|(2<<16)|(3<<11)|(10<<6)|36; #1;

        // OR funct=37
        INST = (13<<26)|(1<<21)|(2<<16)|(3<<11)|(10<<6)|37; #1;

        // MUL funct=50
        INST = (13<<26)|(1<<21)|(2<<16)|(3<<11)|(10<<6)|50; #1;

        // JMP op=2 addr=0x40
        INST = (2<<26)|26'h40; #1;

        // NOP = 0 -> tudo neutro
        INST = 32'h0; #1;

        $stop;
    end
endmodule
