/**
 * UART Transmitter (UART_TX)
 * --------------------------
 * Sends 8-bit serial data (8N1: 8 data bits, No parity, 1 Stop bit).
 * For 3Mbps @ 27MHz, each bit lasts 9 clock cycles.
 *
 * UART Signal Diagram:
 * 
 *   IDLE | START | D0 | D1 | D2 | D3 | D4 | D5 | D6 | D7 | STOP | IDLE
 *   -----+       +----+----+----+----+----+----+----+----+------+-----
 *  (High)|       |                                      |      |(High)
 *        +-------+                                      +------+
 *          ^
 *          Start Bit (Low)
 */

module uart_tx (
    input        clk,
    input        rst,
    
    // User Control
    input        tx_start,
    input  [7:0] tx_data,
    
    // Output Status
    output reg   tx_out,
    output reg   tx_busy
);

    parameter BIT_TICKS = 9; // 27MHz / 3MHz Baudrate

    // Internal registers
    reg [3:0] bit_cnt;    // Counter for bits (0-7 for data)
    reg [3:0] tick_cnt;   // Counter for clock ticks per bit
    reg [7:0] shift_reg;  // Buffer for data currently being sent

    // State machine definition
    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            tx_out <= 1'b1;  // UART line IDLE state is High
            tx_busy <= 1'b0;
            tick_cnt <= 0;
            bit_cnt <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx_out <= 1'b1;
                    tx_busy <= 1'b0;
                    if (tx_start) begin
                        shift_reg <= tx_data;
                        state <= START;
                        tx_busy <= 1'b1;
                        tick_cnt <= 0;
                    end
                end

                START: begin
                    tx_out <= 1'b0; // Start Bit is always Low
                    if (tick_cnt == BIT_TICKS - 1) begin
                        tick_cnt <= 0;
                        bit_cnt <= 0;
                        state <= DATA;
                    end else begin
                        tick_cnt <= tick_cnt + 1'b1;
                    end
                end

                DATA: begin
                    tx_out <= shift_reg[0]; // Send Least Significant Bit first
                    if (tick_cnt == BIT_TICKS - 1) begin
                        tick_cnt <= 0;
                        if (bit_cnt == 7) begin
                            state <= STOP;
                        end else begin
                            shift_reg <= {1'b0, shift_reg[7:1]};
                            bit_cnt <= bit_cnt + 1'b1;
                        end
                    end else begin
                        tick_cnt <= tick_cnt + 1'b1;
                    end
                end

                STOP: begin
                    tx_out <= 1'b1; // Stop Bit is always High
                    if (tick_cnt == BIT_TICKS - 1) begin
                        state <= IDLE;
                        tx_busy <= 1'b0;
                    end else begin
                        tick_cnt <= tick_cnt + 1'b1;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
