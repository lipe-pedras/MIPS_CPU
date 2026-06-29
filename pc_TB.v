`timescale 1ns/1ps
// TestBench do PC: reset->0x900, +4, JMP e BNE (tomado/nao tomado), prioridade.
module pc_TB;
    reg         clk, rst;
    reg         jmpFlag, branchFlag, zeroFlag;
    reg  [31:0] jmpAddress, branchOffset;
    wire [31:0] pc;

    pc DUT (.clk(clk), .rst(rst), .jmpFlag(jmpFlag), .jmpAddress(jmpAddress),
            .branchFlag(branchFlag), .zeroFlag(zeroFlag),
            .branchOffset(branchOffset), .pc(pc));

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1;
        jmpFlag = 0; branchFlag = 0; zeroFlag = 0;
        jmpAddress = 32'h00002000; branchOffset = 32'h00003000;
        #12; 
		  // reset
        rst = 0;
        @(negedge clk); 
        @(negedge clk); 
        // JMP
        jmpFlag = 1;
        @(negedge clk); 
        jmpFlag = 0;
        @(negedge clk); 
        // BNE nao tomado (zeroFlag=1 -> iguais)
        branchFlag = 1; zeroFlag = 1;
        @(negedge clk); 
        // BNE tomado (zeroFlag=0)
        zeroFlag = 0;
        @(negedge clk); 
        // prioridade: BNE (EX) sobre JMP (ID)
        branchFlag = 1; zeroFlag = 0; jmpFlag = 1;
        @(negedge clk); 
		  
		  $stop;
    end
endmodule
