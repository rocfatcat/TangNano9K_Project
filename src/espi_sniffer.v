/**
 * eSPI Raw Sniffer (Phase 1)
 * -------------------------
 * Captures the first 16 bits of an eSPI transaction using oversampling.
 * Automatically adapts to any eSPI clock frequency.
 */

module espi_sniffer (
    input  clk_sample,      // High-speed sampling clock (e.g., 200MHz)
    input  rst,
    
    // eSPI Physical Interface
    input  espi_clk,
    input  espi_cs_n,
    input  [1:0] espi_io,   // Supports Single/Dual IO
    
    // Captured Data Output
    output reg [15:0] raw_data,
    output reg        raw_valid
);

    // --- Synchronizers ---
    // We use 3 stages to prevent metastability at high sampling speeds.
    reg [2:0] clk_sync;
    reg [2:0] cs_sync;
    reg [1:0] io0_sync;
    reg [1:0] io1_sync;

    always @(posedge clk_sample) begin
        clk_sync <= {clk_sync[1:0], espi_clk};
        cs_sync  <= {cs_sync[1:0],  espi_cs_n};
        io0_sync <= {io0_sync[0],   espi_io[0]};
        io1_sync <= {io1_sync[0],   espi_io[1]};
    end

    // --- Edge Detection ---
    wire clk_edge = (clk_sync[2:1] == 2'b01); // Rising edge of espi_clk
    wire cs_active = !cs_sync[1];            // Active low CS
    wire cs_falling = (cs_sync[2:1] == 2'b10);

    // --- Capture Logic ---
    reg [4:0] bit_cnt;
    reg [15:0] shift_reg;

    always @(posedge clk_sample or posedge rst) begin
        if (rst) begin
            bit_cnt <= 0;
            raw_valid <= 0;
            raw_data <= 0;
        end else begin
            raw_valid <= 0;
            
            if (cs_falling) begin
                bit_cnt <= 0;
                shift_reg <= 0;
            end else if (cs_active && clk_edge) begin
                if (bit_cnt < 16) begin
                    // Shift in 1 bit (Single IO mode assumes IO0 for now)
                    shift_reg <= {shift_reg[14:0], io0_sync[1]};
                    bit_cnt <= bit_cnt + 1'b1;
                end
                
                // Trigger validity once we have 16 bits
                if (bit_cnt == 15) begin
                    raw_data <= {shift_reg[14:0], io0_sync[1]};
                    raw_valid <= 1'b1;
                end
            end
        end
    end

endmodule
