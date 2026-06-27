`timescale 1ns/1ps
// TestBench do PC: reset->0x900, +4, JMP e BNE (tomado/nao tomado), prioridade.
module pc_TB;
    reg         clk, rst;
    reg         jmpFlag, branchFlag, zeroFlag;
    reg  [31:0] jmpAddress, branchOffset;
    wire [31:0] pc;
    integer     errors = 0;

    pc DUT (.clk(clk), .rst(rst), .jmpFlag(jmpFlag), .jmpAddress(jmpAddress),
            .branchFlag(branchFlag), .zeroFlag(zeroFlag),
            .branchOffset(branchOffset), .pc(pc));

    always #5 clk = ~clk;

    task check; input [31:0] exp; begin
        if (pc !== exp) begin
            $display("FAIL t=%0t pc=%h exp=%h", $time, pc, exp);
            errors = errors + 1;
        end
    end endtask

    initial begin
        clk = 0; rst = 1;
        jmpFlag = 0; branchFlag = 0; zeroFlag = 0;
        jmpAddress = 32'h0000_2000; branchOffset = 32'h0000_3000;
        #12; check(32'h0000_0900);            // reset
        rst = 0;
        @(negedge clk); check(32'h0000_0904); // +4
        @(negedge clk); check(32'h0000_0908); // +4
        // JMP
        jmpFlag = 1;
        @(negedge clk); check(32'h0000_2000);
        jmpFlag = 0;
        @(negedge clk); check(32'h0000_2004); // +4 apos jmp
        // BNE nao tomado (zeroFlag=1 -> iguais)
        branchFlag = 1; zeroFlag = 1;
        @(negedge clk); check(32'h0000_2008); // +4
        // BNE tomado (zeroFlag=0)
        zeroFlag = 0;
        @(negedge clk); check(32'h0000_3000);
        // prioridade: BNE (EX) sobre JMP (ID)
        branchFlag = 1; zeroFlag = 0; jmpFlag = 1;
        @(negedge clk); check(32'h0000_3000);
        if (errors == 0) $display("pc_TB: PASS");
        else             $display("pc_TB: %0d ERRORS", errors);
        $finish;
    end
endmodule
