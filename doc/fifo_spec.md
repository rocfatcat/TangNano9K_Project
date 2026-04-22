# Module Specification: FIFO (Circular Buffer)

## Overview
This module implements a Synchronous FIFO (First-In, First-Out) buffer using inferred Block RAM. It acts as a bridge to manage data rate differences between modules.

## Features
- **Depth**: 1024 entries (configurable via `ADDR_WIDTH`).
- **Data Width**: 8 bits (configurable via `DATA_WIDTH`).
- **Resource**: Uses 1KB of BSRAM on the Gowin FPGA.
- **Flags**: Provides Full, Empty, and Data Count status.

## Architecture
The FIFO uses two independent pointers (`wr_ptr` and `rd_ptr`) moving in a circular fashion.

```text
      +---+---+---+---+---+---+---+---+
      | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |  ... 1023
      +---+---+---+---+---+---+---+---+
                ^           ^
                |           |
             rd_ptr       wr_ptr (Tail)
             (Head)
```

## Interface
| Pin | Direction | Description |
| :--- | :--- | :--- |
| `clk` | Input | System Clock (27MHz) |
| `rst` | Input | Active-high synchronous reset |
| `wr_en`| Input | Write enable (Ignored if `full` is High) |
| `din`  | Input | 8-bit Data to be written |
| `rd_en`| Input | Read enable (Ignored if `empty` is High) |
| `dout` | Output| 8-bit Data currently at the head of the FIFO |
| `full` | Output| High when FIFO is at 100% capacity |
| `empty`| Output| High when FIFO contains no data |
| `data_count`| Output| Current number of bytes stored (0 to 1024) |

## Operational Logic
- **Simultaneous Access**: Supports reading and writing in the same clock cycle.
- **Overflow Protection**: Logic prevents writing when full and reading when empty.
