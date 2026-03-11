module alu4_flow_demo (
    input  [3:0] a,
    input  [3:0] b,
    input  [1:0] op,
    output reg [3:0] y,
    output reg       cout
);
    reg [4:0] tmp;

    always @* begin
        tmp  = 5'b0;
        y    = 4'b0;
        cout = 1'b0;

        case (op)
            2'b00: begin
                tmp  = {1'b0, a} + {1'b0, b};
                y    = tmp[3:0];
                cout = tmp[4];
            end
            2'b01: begin
                tmp  = {1'b0, a} - {1'b0, b};
                y    = tmp[3:0];
                cout = tmp[4];
            end
            2'b10: begin
                y    = a & b;
                cout = 1'b0;
            end
            default: begin
                y    = a ^ b;
                cout = 1'b0;
            end
        endcase
    end
endmodule
