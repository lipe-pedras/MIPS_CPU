
module pc #(
    parameter WIDTH      = 32,
    parameter RESET_ADDR = 32'h0000_0900
) (
    input                  clk,
    input                  rst,
    input                  jmpFlag,
    input      [WIDTH-1:0] jmpAddress,
    input                  branchFlag,
    input                  zeroFlag,
    input      [WIDTH-1:0] branchOffset,
    output reg [WIDTH-1:0] pc
);
    wire branchTaken = branchFlag & ~zeroFlag;
    wire [WIDTH-1:0] next = branchTaken ? branchOffset :
                            jmpFlag     ? jmpAddress   :
                                          pc + 32'd4;

    always @(posedge clk or posedge rst) begin
        if (rst) pc <= RESET_ADDR;
        else     pc <= next;
    end
endmodule
