`timescale 1ns/1ps

module tb_counter8;
    reg clk;
    reg rst;
    reg en;
    wire [7:0] count;
    integer tests;
    integer failures;
    integer cycle_idx;

    counter8 dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .count(count)
    );

    always #2.5 clk = ~clk;

    task check_count;
        input [127:0] label;
        input [7:0] expected;
        begin
            tests = tests + 1;
            if (count === expected) begin
                $display("PASS %0s count=0x%02x", label, count);
            end else begin
                failures = failures + 1;
                $display("FAIL %0s got=0x%02x exp=0x%02x", label, count, expected);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        en = 1'b0;
        tests = 0;
        failures = 0;

        repeat (2) @(posedge clk);
        check_count("reset_asserted", 8'h00);

        rst = 1'b0;
        en = 1'b1;
        repeat (3) @(posedge clk);
        check_count("count_three", 8'h03);

        en = 1'b0;
        repeat (2) @(posedge clk);
        check_count("hold_disabled", 8'h03);

        en = 1'b1;
        repeat (2) @(posedge clk);
        check_count("resume_enable", 8'h05);

        rst = 1'b1;
        @(posedge clk);
        rst = 1'b0;
        en = 1'b1;
        for (cycle_idx = 0; cycle_idx < 255; cycle_idx = cycle_idx + 1) begin
            @(posedge clk);
        end
        check_count("near_rollover", 8'hFF);

        @(posedge clk);
        check_count("rollover", 8'h00);

        if (failures == 0) begin
            $display("PASS tb_counter8 (%0d checks)", tests);
        end else begin
            $display("FAIL tb_counter8 (%0d failures out of %0d checks)", failures, tests);
        end

        $finish;
    end
endmodule
