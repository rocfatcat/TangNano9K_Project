/**
 * Tang Nano 9K Top-Level Module
 * -----------------------------
 * This module demonstrates the 3MHz UART by implementing a simple echo loopback.
 * All characters received on UART_RX are buffered in a 1KB FIFO and sent back 
 * through UART_TX.
 */

module top (
    input  clk,       // 27MHz Onboard Crystal
    input  uart_rx,   // Pin 18
    output uart_tx,   // Pin 17
    output [5:0] led  // Pins 10, 11, 13, 14, 15, 16
);
    
    // --- LED Blinky Heartbeat ---
    // 27MHz / 2^25 ~ 0.8 seconds cycle
    reg [24:0] counter;
    always @(posedge clk) begin
        counter <= counter + 1'b1;
    end
    assign led = ~counter[24:19]; // Bitwise NOT as LEDs are active Low

    // --- UART Instance ---
    wire [7:0] rx_data;
    wire       rx_empty;
    wire       tx_full;
    reg        rx_rd_en;
    reg        tx_wr_en;

    uart uart_inst (
        .clk(clk),
        .rst(1'b0), // Hardwired reset to logic 0 (not active)
        .rx(uart_rx),
        .tx(uart_tx),
        
        // Data input for TX
        .tx_wr_en(tx_wr_en),
        .tx_din(rx_data),
        .tx_full(tx_full),
        
        // Data output from RX
        .rx_rd_en(rx_rd_en),
        .rx_dout(rx_data),
        .rx_empty(rx_empty)
    );

    /**
     * ECHO LOOPBACK LOGIC
     * -------------------
     * If the Receive FIFO is NOT empty AND the Transmit FIFO is NOT full:
     * 1. Pulse 'rx_rd_en' to extract a byte from the RX buffer.
     * 2. Pulse 'tx_wr_en' to push that same byte into the TX buffer.
     */
    always @(*) begin
        if (!rx_empty && !tx_full) begin
            rx_rd_en = 1'b1;
            tx_wr_en = 1'b1;
        end else begin
            rx_rd_en = 1'b0;
            tx_wr_en = 1'b0;
        end
    end

endmodule
