
module register #(
    parameter WIDTH = 32
) (
    input                  clk,
    input                  rst,
    input      [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk or posedge rst) begin
        if (rst) q <= {WIDTH{1'b0}};
        else     q <= d;
    end
endmodule
