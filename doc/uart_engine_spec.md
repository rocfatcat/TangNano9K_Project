# Module Specification: UART Engine (TX & RX)

## Overview
This specification covers the `uart_tx` and `uart_rx` modules. They provide raw serial-to-parallel and parallel-to-serial conversion at a 3MHz baudrate with a 27MHz system clock.

## Features
- **Baudrate**: 3,000,000 bits per second (3 Mbps).
- **Configuration**: 8 data bits, no parity, 1 stop bit (8N1).
- **Precision**: 9 clock cycles per bit (exactly 27MHz / 3MHz).
- **Reliability**: UART_RX performs sampling at the midpoint (cycle 4 of 9).

## Serial Protocol Waveform
```text
  IDLE | START | D0 | D1 | D2 | D3 | D4 | D5 | D6 | D7 | STOP | IDLE
  -----+       +----+----+----+----+----+----+----+----+------+-----
 (High)|       |                                      |      |(High)
       +-------+                                      +------+
         ^
         Start Bit (Logic Low)
```

## UART_TX Interface
| Pin | Direction | Description |
| :--- | :--- | :--- |
| `clk` | Input | System Clock (27MHz) |
| `rst` | Input | Reset |
| `tx_start`| Input | High pulse to start transmission |
| `tx_data` | Input | Byte to transmit (Latching happens at `tx_start`) |
| `tx_out`  | Output| Serial Data Output |
| `tx_busy` | Output| High while transmitting |

## UART_RX Interface
| Pin | Direction | Description |
| :--- | :--- | :--- |
| `clk` | Input | System Clock (27MHz) |
| `rst` | Input | Reset |
| `rx_in` | Input | Serial Data Input (includes internal 2-FF synchronizer) |
| `rx_data`| Output| Received Byte |
| `rx_done`| Output| High pulse for 1 cycle when a valid byte is ready |

## Midpoint Sampling logic (UART_RX)
The receiver waits for the `rx_in` line to go Low (Start Bit). It then waits 4 cycles to sample the middle of the Start Bit. If still Low, it continues to sample every subsequent bit every 9 cycles at the midpoint.
