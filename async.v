`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.08.2025 18:31:08
// Design Name: 
// Module Name: async_fifo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module async_fifo#(
    parameter data_width = 8,
    parameter add_width = 4
    )(
       //write domain
      input wire [data_width -1:0]data_in,
      input wire wr_en,
      input wire wr_rst,
      input wire wr_clk,
      output wire full,
      
      //read domain
      output reg [data_width-1:0]data_out,
      input wire rd_en,
      input wire rd_rst,
      input wire rd_clk,
      output wire empty
);
    localparam depth = 1<<add_width;  // depth  = 2^add_width
    
    //fifo memory
    reg [data_width-1:0]mem[0:depth-1];
    
    //write pointer
    reg [add_width :0] wr_ptr_bin,wr_ptr_gray;
    
    // read pointer\
    reg [add_width :0] rd_ptr_bin, rd_ptr_gray;
    
    //synchronised gray pointer
    reg [add_width:0] wr_ptr_gray_sync_rd1, wr_ptr_gray_sync_rd2;
    reg [add_width:0] rd_ptr_gray_sync_wr1, rd_ptr_gray_sync_wr2;
    
    // write operaton
    always @(posedge wr_clk or posedge wr_rst)begin 
        if(wr_rst)begin
            wr_ptr_bin <= 0; 
            wr_ptr_gray <= 0;
            rd_ptr_gray_sync_wr1 <= 0;
            rd_ptr_gray_sync_wr2 <= 0;
        end else begin
            if(wr_en && !full)begin
                mem[wr_ptr_bin[add_width-1:0]] <= data_in;
                wr_ptr_bin <= wr_ptr_bin +1;
               // wr_ptr_bin <= wr_ptr_bin +1;
                wr_ptr_gray <= (wr_ptr_bin +1)^((wr_ptr_bin+1)>>1);   //binary to gray
            end
            
            //synchronised read pointer(gray) into wertite clock domain
            rd_ptr_gray_sync_wr1 <= rd_ptr_gray;
            rd_ptr_gray_sync_wr2 <= rd_ptr_gray_sync_wr1;
       end
    end
    
    //read operation
    always @(posedge rd_clk or posedge rd_rst)begin
        if(rd_rst)begin
            rd_ptr_bin <= 0;
            rd_ptr_gray <= 0;
            wr_ptr_gray_sync_rd1 <= 0;
            wr_ptr_gray_sync_rd2 <= 0;
         end else begin
            if(rd_en && !empty)begin
                data_out <= mem[rd_ptr_bin[add_width-1:0]];
                rd_ptr_bin <= rd_ptr_bin +1;
                rd_ptr_gray <= (rd_ptr_bin + 1)^((rd_ptr_bin+1)>>1);
            end
         
            //sync
            wr_ptr_gray_sync_rd1 <= wr_ptr_gray;
            wr_ptr_gray_sync_rd2 <= wr_ptr_gray_sync_rd1;
         end
     end
    
    //gray to binary
    function automatic [add_width:0] gray_to_bin(input[add_width:0]gray);
        integer i;
        begin
            gray_to_bin[add_width] = gray[add_width];
            for(i = add_width-1; i>=0 ; i=i-1)
                gray_to_bin[i] = gray_to_bin[i+1]^gray[i];
        end
     endfunction
     
     //convert gray pointer to binary
     wire[add_width:0]wr_ptr_gray_to_bin = gray_to_bin(wr_ptr_gray);
     wire[add_width:0]rd_ptr_gray_to_bin = gray_to_bin(rd_ptr_gray);
     wire[add_width:0]rd_ptr_gray_sync_wr2_to_bin  = gray_to_bin(rd_ptr_gray_sync_wr2);
     wire[add_width:0]wr_ptr_gray_sync_rd2_to_bin = gray_to_bin(wr_ptr_gray_sync_rd2);
    
    
    //Full: when next wrt_ptr = rd_ptr with msb inverted
    assign full = (wr_ptr_gray_to_bin[add_width]  != rd_ptr_gray_sync_wr2_to_bin[add_width]) && (wr_ptr_gray_to_bin[add_width-1:0]  == rd_ptr_gray_sync_wr2_to_bin[add_width-1:0]);
    
    //Empty : rd_ptr = wr_ptr(synchronisded)
    
    assign empty = (rd_ptr_gray_to_bin == wr_ptr_gray_sync_rd2_to_bin);
    
   
endmodule
