`timescale 1ns / 1ps

module tb_async_fifo;

    parameter data_width = 8;
    parameter add_width = 4;
    parameter depth = 1 << add_width;

    reg wr_clk, wr_rst, wr_en;
    reg rd_clk, rd_rst, rd_en;
    reg [data_width-1:0] data_in;
    wire full, empty;
    wire [data_width-1:0] data_out;

    // Instantiate the FIFO
    async_fifo #(
        .data_width(data_width),
        .add_width(add_width)
    ) dut (
        .data_in(data_in),
        .wr_en(wr_en),
        .wr_rst(wr_rst),
        .wr_clk(wr_clk),
        .full(full),

        .data_out(data_out),
        .rd_en(rd_en),
        .rd_rst(rd_rst),
        .rd_clk(rd_clk),
        .empty(empty)
    );

    // Write Clock: 100 MHz
    always #5 wr_clk = ~wr_clk;

    // Read Clock: ~71 MHz
    always #7 rd_clk = ~rd_clk;

    initial begin
        // Init signals
        wr_clk = 0; wr_rst = 1; wr_en = 0;
        rd_clk = 0; rd_rst = 1; rd_en = 0;
        data_in = 0;

        // Release reset
        #20;
        wr_rst = 0;
        rd_rst = 0;

        // -------- WRITE until FULL --------
        $display("Writing...");
        repeat (depth + 4) begin  // Try more than depth to test full
            @(posedge wr_clk);
            if (!full) begin
                wr_en = 1;
                data_in = $random % 256;
                $display("Write: %0d, full=%b", data_in, full);
            end else begin
                $display("FULL! Cannot write more.");
                wr_en = 0;
            end
        end
        wr_en = 0;

        // Wait before read
        #50;

        // -------- READ until EMPTY --------
        $display("Reading...");
        repeat (depth + 4) begin
            @(posedge rd_clk);
            if (!empty) begin
                rd_en = 1;
                $display("Read: %0d, empty=%b", data_out, empty);
            end else begin
                $display("EMPTY! Nothing to read.");
                rd_en = 0;
            end
        end
        rd_en = 0;

        #100;
        $finish;
    end

endmodule
