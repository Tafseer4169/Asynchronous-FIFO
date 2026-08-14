`timescale 1ns/1ps

module tb_async_fifo;

    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;
    parameter FIFO_DEPTH = 1 << ADDR_WIDTH;

    // Write Domain Signals
    reg                   wr_clk;
    reg                   wr_rst;
    reg                   wr_en;
    reg  [DATA_WIDTH-1:0] data_in;
    wire                  full;

    // Read Domain Signals
    reg                   rd_clk;
    reg                   rd_rst;
    reg                   rd_en;
    wire [DATA_WIDTH-1:0] data_out;
    wire                  empty;

    
    integer i;
    
    // DUT Instantiation

    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .wr_clk   (wr_clk),
        .wr_rst   (wr_rst),
        .wr_en    (wr_en),
        .data_in  (data_in),
        .full     (full),
        
        .rd_clk   (rd_clk),
        .rd_rst   (rd_rst),
        .rd_en    (rd_en),
        .data_out (data_out),
        .empty    (empty)
    );

    // clock generator
  
    initial begin
        wr_clk = 0;
        forever #5 wr_clk = ~wr_clk;  //100MHz
    end

    initial begin
        rd_clk = 0;
        forever #7 rd_clk = ~rd_clk;   //71.4MHz
    end

 
    // Write Task
 
    task write_byte(input [DATA_WIDTH-1:0] wdata);
        begin
            @(posedge wr_clk);
            if (!full) begin
                wr_en   <= 1;
                data_in <= wdata;
                $display("[%0t ns] WRITE: Data = 0x%0h", $time, wdata);
            end else begin
                $display("[%0t ns] WRITE BLOCKED: FIFO is FULL", $time);
            end
            @(posedge wr_clk);
            wr_en <= 0;
        end
    endtask

    
    //Test Stimulus
    
    initial begin
      
		$dumpfile("dump.vcd");
        $dumpvars(0, tb_async_fifo);
      
        // Initialize Inputs
        wr_rst  = 1;
        rd_rst  = 1;
        wr_en   = 0;
        rd_en   = 0;
        data_in = 0;

        // Reset Pulse
        #30;
        @(posedge wr_clk) wr_rst = 0;
        @(posedge rd_clk) rd_rst = 0;
        #20;

      $display("\n--- Step 1: Writing Data to FIFO ---");
        write_byte(8'hA1);
        write_byte(8'hB2);
        write_byte(8'hC3);
        write_byte(8'hD4);

        #50;

        $display("\n--- Step 2: Reading Data from FIFO ---");
        repeat (4) begin
            @(posedge rd_clk);
            if (!empty) begin
                rd_en <= 1;
            end
            @(posedge rd_clk);
            rd_en <= 0;
          	#1;
            $display("[%0t ns] READ: Data = 0x%0h", $time, data_out);
        end

        #50;

        $display("\n--- Step 3: Filling FIFO completely (Testing FULL Flag) ---");
      
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            write_byte(i + 8'h10);
        end

        // Wait for synchronization
        #50;
        $display("[%0t ns] FULL Flag status = %b (Expected: 1)", $time, full);

        $display("\n--- Step 4: Emptying FIFO completely (Testing EMPTY Flag) ---");
        while (!empty) begin
            @(posedge rd_clk);
            rd_en <= 1;
            @(posedge rd_clk);
            rd_en <= 0;
          	#1;
            $display("[%0t ns] READ: Data = 0x%0h", $time, data_out);
        end

        // Wait for synchronization
        #70;
        $display("[%0t ns] EMPTY Flag status = %b (Expected: 1)", $time, empty);

        #100;
        $display("\nSimulation Completed.");
        $finish;
    end

endmodule
