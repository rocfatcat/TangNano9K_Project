# Module Specification: UART Subsystem (with FIFOs)

## Overview
The `uart` module is a high-level wrapper that integrates the `uart_tx` and `uart_rx` engines with dual 1KB FIFOs. It provides a clean, buffered interface for other modules to communicate over serial.

## Features
- **Transmit Buffer**: 1024-byte FIFO ensures no data is lost during high-speed bursts.
- **Receive Buffer**: 1024-byte FIFO holds incoming bytes for the main system to read.
- **Automatic Transmission**: Built-in logic automatically drains the TX FIFO whenever the UART engine is idle.
- **Resource Usage**: Uses 2KB of BSRAM total.

## Internal Block Diagram
```text
                     +---------------------------------------+
                     |             UART Subsystem            |
                     |                                       |
    [tx_din]   ----->|  +------------+     +------------+    |-----> [tx] (Serial)
    [tx_wr_en] ----->|  |  TX FIFO    |---->| UART TX Eng|    |
    [tx_full]  <-----|  |   (1KB)     |     +------------+    |
                     |  +------------+           ^           |
                     |                           | (tx_start)|
                     |                                       |
                     |  +------------+     +------------+    |
    [rx_dout]  <-----|  |  RX FIFO    |<----| UART RX Eng|<----- [rx] (Serial)
    [rx_rd_en] ----->|  |   (1KB)     |     +------------+    |
    [rx_empty] <-----|  +------------+                       |
                     |                                       |
                     +---------------------------------------+
```

## Interface
| Pin | Direction | Description |
| :--- | :--- | :--- |
| `clk` | Input | System Clock (27MHz) |
| `rst` | Input | System Reset |
| `rx`  | Input | Serial Line Input |
| `tx`  | Output| Serial Line Output |
| `tx_wr_en`| Input | Pulse High to write byte into TX FIFO |
| `tx_din`  | Input | 8-bit Data to be queued for transmission |
| `tx_full` | Output| High if the TX FIFO is full (do not write) |
| `rx_rd_en`| Input | Pulse High to read byte from RX FIFO |
| `rx_dout` | Output| 8-bit Data popped from the RX FIFO |
| `rx_empty`| Output| High if the RX FIFO has no data |

## Operational Principles
1. **Writing**: The user checks if `tx_full` is Low, then pulses `tx_wr_en` with `tx_din`.
2. **Reading**: The user checks if `rx_empty` is Low, then pulses `rx_rd_en` and captures `rx_dout`.
3. **Background Tasks**: The internal state machine handles all handshaking between the FIFOs and the raw UART engines.
