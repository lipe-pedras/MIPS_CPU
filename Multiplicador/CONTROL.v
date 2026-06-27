// =============================================================================
// CONTROL.v - FSM do multiplicador (identica ao Lab 4).
//
// 4 estados: S0 (Idle/Load) -> S1 (Add: Ad=M) -> S2 (Shift) -> ... -> S3 (Done).
// Reset assincrono ativo-alto. Inalterada na adaptacao para 16 bits (a largura
// dos operandos so afeta ACC/Adder/Counter; o controle e o mesmo).
// =============================================================================
module CONTROL (
    input  Clk, K, St, M, rst,
    output reg Idle, Done, Load, Sh, Ad
);
    reg [1:0] state;

    parameter s0 = 2'b00;
    parameter s1 = 2'b01;
    parameter s2 = 2'b10;
    parameter s3 = 2'b11;

    always @(posedge Clk or posedge rst) begin
        if (rst) state <= s0;
        else
            case (state)
                s0: begin
                    if (St) state <= s1;
                    else    state <= s0;
                end
                s1: state <= s2;
                s2: begin
                    if (K) state <= s3;
                    else   state <= s1;
                end
                s3: state <= s0;
            endcase
    end

    always @(*) begin
        Idle = 0; Done = 0; Load = 0; Sh = 0; Ad = 0;
        case (state)
            s0: begin
                Idle = 1;
                if (St) Load = 1;
            end
            s1: Ad = M;          // soma o multiplicando se o bit corrente = 1
            s2: Sh = 1;          // desloca a direita
            s3: Done = 1;
        endcase
    end
endmodule
