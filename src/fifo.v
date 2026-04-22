/**
 * Synchronous FIFO (BRAM-Friendly Version)
 * ----------------------------------------
 * This version uses a synchronous read (registered output) to ensure 
 * that Yosys/Gowin maps the memory to internal BSRAM primitives.
 */

module fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 10 // 2^10 = 1024 bytes
) (
    input  clk,
    input  rst,
    
    // Write Interface
    input  wr_en,
    input  [DATA_WIDTH-1:0] din,
    output full,
    
    // Read Interface
    input  rd_en,
    output reg [DATA_WIDTH-1:0] dout, // Synchronous Output
    output empty,
    
    // Status
    output [ADDR_WIDTH:0] data_count
);

    // Memory array (BSRAM Inference)
    reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];
    
    // Internal pointers and counter
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [ADDR_WIDTH:0]   count;

    assign full  = (count == 2**ADDR_WIDTH);
    assign empty = (count == 0);
    assign data_count = count;

    // --- Synchronous Memory Operations ---
    always @(posedge clk) begin
        if (wr_en && !full) begin
            mem[wr_ptr] <= din;
        end
        
        // This registered read is the key to BSRAM inference
        if (rd_en && !empty) begin
            dout <= mem[rd_ptr];
        end else if (!empty) begin
            // Optional: Maintain current output if not reading
            dout <= mem[rd_ptr];
        end
    end

    // --- Pointer and Counter Logic ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: begin // Write
                    wr_ptr <= wr_ptr + 1'b1;
                    count  <= count + 1'b1;
                end
                2'b01: begin // Read
                    rd_ptr <= rd_ptr + 1'b1;
                    count  <= count - 1'b1;
                end
                2'b11: begin // Read & Write
                    wr_ptr <= wr_ptr + 1'b1;
                    rd_ptr <= rd_ptr + 1'b1;
                end
                default: ;
            endcase
        end
    end

endmodule
