/**
 * UART Receiver (UART_RX)
 * -----------------------
 * Receives 8-bit serial data (8N1: 8 data bits, No parity, 1 Stop bit).
 * For 3Mbps @ 27MHz, each bit lasts 9 clock cycles.
 * To ensure reliability, sampling occurs at the midpoint (cycle 4 of 9).
 *
 * Sampling Concept Diagram:
 * 
 *     | START |   D0  |   D1  | ...
 *     +       +-------+-------+
 *     |       |       |       |
 *     +-------+       +-------+
 *        ^       ^       ^
 *        |       |       |
 *      Start   Sample  Sample
 *     Detected at cycle 4
 */

module uart_rx (
    input        clk,
    input        rst,
    
    // Serial Data Input
    input        rx_in,
    
    // User Output
    output reg [7:0] rx_data,
    output reg       rx_done
);

    parameter BIT_TICKS = 9; // 27MHz / 3MHz Baudrate
    parameter SAMPLE_POINT = 4; // Midpoint of bit duration

    // Internal state
    reg [3:0] bit_cnt;    // Counter for data bits (0-7)
    reg [3:0] tick_cnt;   // Counter for clock ticks per bit
    reg [7:0] shift_reg;  // Register to assemble the received byte
    reg       rx_sync1, rx_sync2; // Dual flip-flops for synchronization

    // State machine definition
    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;

    // Synchronize RX input to internal clock domain (to avoid metastability)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= rx_in;
            rx_sync2 <= rx_sync1;
        end
    end

    // Main Receive State Machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            rx_done <= 1'b0;
            rx_data <= 0;
            tick_cnt <= 0;
            bit_cnt <= 0;
        end else begin
            rx_done <= 1'b0; // Default status is "Not Done"
            
            case (state)
                IDLE: begin
                    if (!rx_sync2) begin // Detected logic Low (Start bit)
                        state <= START;
                        tick_cnt <= 0;
                    end
                end

                START: begin
                    // Verify that the start bit is still low at the midpoint
                    if (tick_cnt == SAMPLE_POINT) begin
                        if (!rx_sync2) begin
                            tick_cnt <= 0;
                            state <= DATA;
                            bit_cnt <= 0;
                        end else begin
                            state <= IDLE; // Spurious noise, return to IDLE
                        end
                    end else begin
                        tick_cnt <= tick_cnt + 1'b1;
                    end
                end

                DATA: begin
                    // Sample the data line once per bit at the midpoint
                    if (tick_cnt == BIT_TICKS - 1) begin
                        tick_cnt <= 0;
                        shift_reg <= {rx_sync2, shift_reg[7:1]};
                        if (bit_cnt == 7) begin
                            state <= STOP;
                        end else begin
                            bit_cnt <= bit_cnt + 1'b1;
                        end
                    end else begin
                        tick_cnt <= tick_cnt + 1'b1;
                    end
                end

                STOP: begin
                    // Ensure valid Stop Bit (High) before finishing
                    if (tick_cnt == BIT_TICKS - 1) begin
                        if (rx_sync2) begin // Stop bit is High
                            rx_data <= shift_reg;
                            rx_done <= 1'b1;
                        end
                        state <= IDLE;
                    end else begin
                        tick_cnt <= tick_cnt + 1'b1;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
