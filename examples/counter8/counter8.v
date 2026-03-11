module counter8 (
    input        clk,
    input        rst,
    input        en,
    output reg [7:0] count
);
    always @(posedge clk) begin
        if (rst) begin
            count <= 8'h00;
        end else if (en) begin
            count <= count + 8'h01;
        end
    end
endmodule
