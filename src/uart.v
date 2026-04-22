/**
 * UART Module with TX and RX FIFOs
 * --------------------------------
 * This module encapsulates the UART transmitter and receiver engines, 
 * adding a 1KB FIFO to each. This prevents data loss when burst transmissions 
 * exceed the processing speed.
 *
 * Internal Architecture:
 * 
 *     User Write -> [TX FIFO (1K)] -> UART TX Engine -> Serial Output
 *     Serial Input -> UART RX Engine -> [RX FIFO (1K)] -> User Read
 */

module uart (
    input        clk,
    input        rst,
    
    // Serial Ports
    input        rx,
    output       tx,
    
    // User interface - TX side
    input        tx_wr_en,
    input  [7:0] tx_din,
    output       tx_full,
    
    // User interface - RX side
    input        rx_rd_en,
    output [7:0] rx_dout,
    output       rx_empty
);

    wire [7:0] tx_fifo_dout;
    wire       tx_fifo_empty;
    wire       tx_busy;
    reg        tx_start;

    /**
     * TRANSMIT BUFFER (1KB)
     * Collects bytes from the user and passes them to the TX engine.
     */
    fifo #(.DATA_WIDTH(8), .ADDR_WIDTH(10)) tx_fifo (
        .clk(clk),
        .rst(rst),
        .wr_en(tx_wr_en),
        .din(tx_din),
        .rd_en(tx_start),
        .dout(tx_fifo_dout),
        .full(tx_full),
        .empty(tx_fifo_empty)
    );

    /**
     * TX Controller Logic
     * Monitors the TX FIFO. If it's not empty and the TX engine is free, 
     * trigger a new byte transmission.
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_start <= 1'b0;
        end else begin
            if (!tx_fifo_empty && !tx_busy && !tx_start) begin
                tx_start <= 1'b1;
            end else begin
                tx_start <= 1'b0;
            end
        end
    end

    // The Hardware TX Core
    uart_tx #(.BIT_TICKS(9)) tx_engine (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_fifo_dout),
        .tx_out(tx),
        .tx_busy(tx_busy)
    );

    wire [7:0] rx_engine_data;
    wire       rx_engine_done;

    // The Hardware RX Core
    uart_rx #(.BIT_TICKS(9), .SAMPLE_POINT(4)) rx_engine (
        .clk(clk),
        .rst(rst),
        .rx_in(rx),
        .rx_data(rx_engine_data),
        .rx_done(rx_engine_done)
    );

    /**
     * RECEIVE BUFFER (1KB)
     * Collects bytes from the RX engine and holds them for the user.
     */
    fifo #(.DATA_WIDTH(8), .ADDR_WIDTH(10)) rx_fifo (
        .clk(clk),
        .rst(rst),
        .wr_en(rx_engine_done), // Write whenever the RX engine finish a byte
        .din(rx_engine_data),
        .rd_en(rx_rd_en),
        .dout(rx_dout),
        .full(), // We assume RX buffer doesn't overflow
        .empty(rx_empty)
    );

endmodule
