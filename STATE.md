# Project Status: eSPI Bus Monitor for Tang Nano 9K

## Current Phase: Phase 1 (Completed)
**Date**: 2026-04-22
**Status**: Stable & Verified (Phase 1)

## Implemented Features
- **High-Speed Oversampling**: 
  - Internal `rPLL` generates **216MHz** from 27MHz.
  - Frequency-adaptive edge detection for `espi_clk` (supports 20MHz ~ 66MHz).
- **Dual Voltage Support**:
  - Compile-time selection via `make VOLTAGE=1.8` or `make VOLTAGE=3.3`.
  - Automatically maps to correct Bank (Bank 3 for 1.8V, Bank 2 for 3.3V).
- **Core Sniffer (`src/espi_sniffer.v`)**:
  - 3-stage synchronizers for high-speed signals.
  - Captures the first 16 bits of every transaction.
- **High-Performance UART**:
  - **3Mbps** Baudrate with **1KB BSRAM FIFOs**.

## Next Steps: Phase 2
- **Command Decoding**: Identify `Peripheral I/O Write` (0x01/0x09).
- **Wait State Handling**: Support `SBYT` (Wait) cycles from the Host.
- **Address Filter**: Target `0x80` and `0x81` I/O ports specifically.

## Build Commands
```powershell
# For 1.8V (Laptops)
make clean && make VOLTAGE=1.8 && make load

# For 3.3V (Servers/Desktops)
make clean && make VOLTAGE=3.3 && make load
```
Serial terminal: **3,000,000 baud, 8N1**.
