# Workspace Context: Tang Nano 9K eSPI Bus Monitor

## 🚀 Current Project Status
- **Phase**: Phase 1 (Completed)
- **Milestone**: High-speed (216MHz) oversampling and raw data sniffing operational.
- **Last Updated**: 2026-04-22

## 🛠️ Technical Specifications
- **Sampling Clock**: 216MHz (via rPLL from 27MHz crystal).
- **eSPI Bus**: 1.8V LVCMOS, frequency-adaptive (20MHz - 66MHz).
- **UART Output**: 3,000,000 Baud, 8N1, with 1KB BSRAM FIFOs for TX/RX.
- **IO Pins**:
  - eSPI: CLK(25), CS#(26), IO0(27), IO1(28).
  - UART: TX(17), RX(18).
  - LEDs: Pins 10, 11, 13, 14, 15, 16 (Active Low).

## 📝 Next Implementation Steps (Phase 2)
1. **Peripheral Channel Decoding**: Filter for `Peripheral I/O Write` commands.
2. **Address Matching**: Specifically target I/O addresses `0x80` and `0x81`.
3. **Wait State Handling**: Implement support for Host `SBYT` (Wait) cycles.
4. **Data Logging**: Format and output POST code data to UART.

## ⚠️ Important Notes
- Always use `make` for building and `make load` for programming.
- Ensure the hardware environment matches the 1.8V IO requirements.
- The `fifo.v` must use synchronous reads to correctly infer Block RAM (BSRAM).
