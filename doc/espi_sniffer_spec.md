# Module Specification: eSPI Sniffer (Phase 1)

## Overview
The `espi_sniffer` module is a high-speed bus monitor designed to capture eSPI (Enhanced Serial Peripheral Interface) transactions. It uses oversampling to achieve frequency auto-adaptation, allowing it to monitor eSPI buses running from 20MHz up to 66MHz.

## Features
- **Oversampling Architecture**: Uses a 216MHz sampling clock to monitor lower-frequency eSPI signals.
- **Frequency Adaptive**: No fixed clock division; it tracks the `espi_clk` rising edge pulses.
- **Metastability Protection**: Implements 3-stage synchronizers for all asynchronous input signals.
- **Buffer Capacity**: Captures the first 16 bits of each transaction (expandable in later phases).

## Interface
| Pin | Direction | Description |
| :--- | :--- | :--- |
| `clk_sample` | Input | High-speed sampling clock (e.g., 216MHz from PLL) |
| `rst` | Input | Active-high reset (usually connected to PLL Lock) |
| `espi_clk` | Input | External eSPI Clock signal |
| `espi_cs_n` | Input | External eSPI Chip Select (Active Low) |
| `espi_io[1:0]`| Input | eSPI Data lines (IO0/IO1) |
| `raw_data[15:0]`| Output| First 16 bits captured during the transaction |
| `raw_valid` | Output| Single-cycle pulse when `raw_data` is complete |

## Timing & Sampling Logic
1. **Edge Detection**: The module detects the rising edge of `espi_clk` within the `clk_sample` domain.
2. **Synchronization Delay**: There is a 3-cycle `clk_sample` delay due to the synchronizers, ensuring stability at 1.8V high-speed signaling.
3. **Capture Trigger**: Data is sampled on the `clk_edge` pulse only when `espi_cs_n` is Low.

```text
clk_sample:  _| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_
espi_clk:    ___________/----------\___________/----------
clk_edge:    ____________|_________|___________|_________|
Capture:                 ^ Sample              ^ Sample
```

## Physical Constraints Note
- **Voltage**: 1.8V LVCMOS.
- **Hysteresis**: Recommended to be enabled in the `.cst` file for noise immunity.
