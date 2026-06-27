`timescale 1ns/1ps
// TestBench do mux 2:1 generico.
module mux_TB;
    reg         sel;
    reg  [31:0] in0, in1;
    wire [31:0] out;
    integer     errors = 0;

    mux #(.WIDTH(32)) DUT (.sel(sel), .in0(in0), .in1(in1), .out(out));

    task check; input [31:0] exp; begin
        if (out !== exp) begin
            $display("FAIL sel=%b out=%h exp=%h", sel, out, exp);
            errors = errors + 1;
        end
    end endtask

    initial begin
        in0 = 32'hAAAAAAAA; in1 = 32'h55555555;
        sel = 0; #1; check(in0);
        sel = 1; #1; check(in1);
        in0 = 32'h0; in1 = 32'hFFFFFFFF;
        sel = 0; #1; check(32'h0);
        sel = 1; #1; check(32'hFFFFFFFF);
        if (errors == 0) $display("mux_TB: PASS");
        else             $display("mux_TB: %0d ERRORS", errors);
        $finish;
    end
endmodule
