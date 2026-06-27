`timescale 1ns/1ps
// TestBench do modelo de PLL: confere razao CLK_SYS = CLK_MUL/DIV.
module PLL_TB;
    reg  inclk0, areset;
    wire c0, c1, locked;
    integer sys_edges = 0, mul_edges = 0;

    PLL #(.DIV(40)) DUT (.inclk0(inclk0), .areset(areset),
                         .c0(c0), .c1(c1), .locked(locked));

    always #5 inclk0 = ~inclk0;   // CLK_MUL = 100 MHz (10 ns)

    always @(posedge c1) mul_edges = mul_edges + 1;
    always @(posedge c0) sys_edges = sys_edges + 1;

    initial begin
        inclk0 = 0; areset = 1;
        #23 areset = 0;
        #8000;                    // ~800 pulsos de CLK_MUL
        // CLK_SYS deve ter ~ mul_edges/40 bordas
        $display("mul_edges=%0d sys_edges=%0d (razao ~%0d)",
                 mul_edges, sys_edges, mul_edges/(sys_edges==0?1:sys_edges));
        if (locked && sys_edges > 0 && (mul_edges/sys_edges >= 38) && (mul_edges/sys_edges <= 42))
            $display("PLL_TB: PASS");
        else
            $display("PLL_TB: FAIL");
        $finish;
    end
endmodule
