/**
 * Tang Nano 9K Top-Level - eSPI Sniffer Phase 1
 * --------------------------------------------
 * This module captures the first 16 bits of any eSPI transaction
 * and sends them as hex strings over UART @ 3Mbps.
 */

module top (
    input  clk,         // 27MHz Crystal
    
    // eSPI Interface
    input  espi_clk,    // Physical pin assigned in .cst
    input  espi_cs_n,
    input  [1:0] espi_io,
    
    // UART Output
    output uart_tx,
    input  uart_rx,
    
    // LEDs
    output [5:0] led
);

    // --- High-Speed Sampling Clock (rPLL Instance) ---
    // Generate ~216MHz from 27MHz for oversampling (8x 27MHz)
    wire clk_sample;
    wire lock;

    rPLL #(
        .FCLKIN("27"),
        .DEVICE("GW1NR-9C"),
        .IDIV_SEL(0),      // 27 / (0+1) = 27
        .FBDIV_SEL(7),     // 27 * (7+1) = 216
        .ODIV_SEL(4),      // 216 / 4 = 54 (or keep at ODIV=2 for 108MHz)
        .DUTYDA_SEL("1000"),
        .DYN_SDIV_SEL(2)
    ) pll_inst (
        .CLKOUT(clk_sample),
        .CLKOUTP(),
        .CLKOUTD(),
        .CLKOUTD3(),
        .RESET(1'b0),
        .RESET_P(1'b0),
        .CLKIN(clk),
        .CLKFB(1'b0),
        .FBDSEL(6'b0),
        .IDSEL(6'b0),
        .ODSEL(6'b0),
        .PSDA(4'b0),
        .DUTYDA(4'b0),
        .FDLY(4'b0),
        .LOCK(lock)
    );

    // --- eSPI Sniffer ---
    wire [15:0] espi_raw;
    wire        espi_valid;

    espi_sniffer sniffer_inst (
        .clk_sample(clk_sample),
        .rst(!lock),
        .espi_clk(espi_clk),
        .espi_cs_n(espi_cs_n),
        .espi_io(espi_io),
        .raw_data(espi_raw),
        .raw_valid(espi_valid)
    );

    // --- Data Formatting (Hex to ASCII) ---
    wire [63:0] ascii_str; // 8 bytes for " [XXXX]\r\n"
    
    function [7:0] to_char;
        input [3:0] nibble;
        begin
            if (nibble < 4'hA)
                to_char = 8'h30 + nibble;
            else
                to_char = 8'h37 + nibble;
        end
    endfunction

    assign ascii_str = {
        8'h20, 8'h5B,
        to_char(espi_raw[15:12]), to_char(espi_raw[11:8]),
        to_char(espi_raw[7:4]), to_char(espi_raw[3:0]),
        8'h5D, 8'h0A
    };

    // --- UART Interface ---
    reg [2:0] tx_ptr;
    reg       tx_wr_en;
    reg [7:0] tx_byte;
    wire      tx_full;

    uart uart_inst (
        .clk(clk),
        .rst(!lock),
        .rx(uart_rx),
        .tx(uart_tx),
        .tx_wr_en(tx_wr_en),
        .tx_din(tx_byte),
        .tx_full(tx_full),
        .rx_rd_en(1'b0),
        .rx_dout(),
        .rx_empty()
    );

    // State machine to send 8-byte string on every espi_valid
    reg [3:0] send_state;
    always @(posedge clk) begin
        if (!lock) begin
            send_state <= 0;
            tx_wr_en <= 0;
        end else begin
            tx_wr_en <= 0;
            case (send_state)
                0: if (espi_valid) send_state <= 1;
                1,2,3,4,5,6,7,8: begin
                    if (!tx_full) begin
                        tx_wr_en <= 1;
                        // Send bytes from MSB to LSB of ascii_str
                        case (send_state)
                            1: tx_byte <= ascii_str[63:56];
                            2: tx_byte <= ascii_str[55:48];
                            3: tx_byte <= ascii_str[47:40];
                            4: tx_byte <= ascii_str[39:32];
                            5: tx_byte <= ascii_str[31:24];
                            6: tx_byte <= ascii_str[23:16];
                            7: tx_byte <= ascii_str[15:8];
                            8: tx_byte <= ascii_str[7:0];
                        endcase
                        send_state <= send_state + 1'b1;
                    end
                end
                9: send_state <= 0;
            endcase
        end
    end

    // Heartbeat LED
    reg [23:0] cnt;
    always @(posedge clk) cnt <= cnt + 1;
    assign led = ~{5'b0, cnt[23]};

endmodule
