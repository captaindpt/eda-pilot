`timescale 1ns/1ps

module tb_alu4;
    reg [3:0] a;
    reg [3:0] b;
    reg [1:0] op;
    wire [3:0] y;
    wire cout;
    integer tests;
    integer failures;

    alu4_flow_demo dut (
        .a(a),
        .b(b),
        .op(op),
        .y(y),
        .cout(cout)
    );

    task check_case;
        input [127:0] label;
        input [3:0] a_in;
        input [3:0] b_in;
        input [1:0] op_in;
        input [3:0] expected_y;
        input expected_cout;
        begin
            a = a_in;
            b = b_in;
            op = op_in;
            #1;
            tests = tests + 1;
            if (y === expected_y && cout === expected_cout) begin
                $display("PASS %0s a=%0d b=%0d op=%b y=%0d cout=%0d", label, a, b, op, y, cout);
            end else begin
                failures = failures + 1;
                $display(
                    "FAIL %0s a=%0d b=%0d op=%b got_y=%0d exp_y=%0d got_cout=%0d exp_cout=%0d",
                    label, a, b, op, y, expected_y, cout, expected_cout
                );
            end
        end
    endtask

    initial begin
        tests = 0;
        failures = 0;
        a = 4'd0;
        b = 4'd0;
        op = 2'b00;

        check_case("add_basic", 4'd3, 4'd5, 2'b00, 4'd8, 1'b0);
        check_case("add_overflow", 4'd15, 4'd1, 2'b00, 4'd0, 1'b1);

        check_case("sub_basic", 4'd9, 4'd4, 2'b01, 4'd5, 1'b0);
        check_case("sub_underflow", 4'd0, 4'd1, 2'b01, 4'd15, 1'b1);

        check_case("and_mask", 4'b1100, 4'b1010, 2'b10, 4'b1000, 1'b0);
        check_case("and_zero", 4'b0101, 4'b1010, 2'b10, 4'b0000, 1'b0);

        check_case("xor_basic", 4'b1100, 4'b1010, 2'b11, 4'b0110, 1'b0);
        check_case("xor_self", 4'b1111, 4'b1111, 2'b11, 4'b0000, 1'b0);

        if (failures == 0) begin
            $display("PASS tb_alu4 (%0d checks)", tests);
        end else begin
            $display("FAIL tb_alu4 (%0d failures out of %0d checks)", failures, tests);
        end

        $finish;
    end
endmodule
