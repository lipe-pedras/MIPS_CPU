module alu #(
    parameter WIDTH = 32
) (
    input      [WIDTH-1:0] A,
    input      [WIDTH-1:0] B,
    input      [2:0]       aluControl,
    output reg [WIDTH-1:0] result,
    output                 zeroFlag
);
    localparam ALU_ADD = 3'b000;
    localparam ALU_SUB = 3'b001;
    localparam ALU_AND = 3'b010;
    localparam ALU_OR  = 3'b011;

    always @(*) begin
        case (aluControl)
            ALU_ADD: result = A + B;
            ALU_SUB: result = A - B;
            ALU_AND: result = A & B;
            ALU_OR:  result = A | B;
            default: result = A + B;
        endcase
    end

    // zeroFlag indica igualdade entre A e B (A - B == 0).
    assign zeroFlag = (A == B);
endmodule
