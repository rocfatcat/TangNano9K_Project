# Tang Nano 9K Apicula Template with 3MHz UART

This is a high-performance project template for the Sipeed Tang Nano 9K FPGA board using the open-source [Apicula](https://github.com/YosysHQ/apicula) toolchain. It features a 3MHz UART with 1KB TX/RX FIFOs and an echo loopback test.

## Features

- **3MHz UART**: Custom hand-crafted UART engine running at 3Mbps (9 cycles per bit @ 27MHz).
- **1KB FIFOs**: Independent 1024-byte TX and RX buffers using inferred BSRAM.
- **Echo Loopback**: The default `top.v` echoes all received UART data back to the transmitter.
- **LED Blinky**: Visual heart-beat on the 6 onboard LEDs.

## Prerequisites

You need the following tools installed and in your PATH:

1.  **Yosys**: For Verilog synthesis.
2.  **nextpnr-gowin**: For place and route.
3.  **Apicula**: Provides `gowin_pack` (install via `pip install apicula`).
4.  **openFPGALoader**: For programming the FPGA.

## Project Structure

- `src/top.v`: Top-level module with echo loopback and blinky.
- `src/uart.v`: High-level UART wrapper with FIFOs.
- `src/uart_tx.v` & `src/uart_rx.v`: Core 3MHz UART engines.
- `src/fifo.v`: Synchronous 1KB FIFO using block RAM.
- `src/tangnano9k.cst`: Physical constraints file.
- `Makefile`: Automates the entire build and upload process.

## Usage

### Build the bitstream
To synthesize, place, route, and pack the design:
```bash
make
```
This will produce `top.fs`.

### Upload to SRAM (Volatile)
To test the design immediately:
```bash
make load
```

### Flash to internal memory (Persistent)
To save the design permanently:
```bash
make flash
```

### Testing the UART
Open your favorite serial terminal (e.g., PuTTY, VS Code Serial Monitor) with the following settings:
- **Baudrate**: 3,000,000 (3 Mbps)
- **Data bits**: 8
- **Stop bits**: 1
- **Parity**: None
- **Flow Control**: None

Typing characters should result in an instant echo from the FPGA.

## Hardware Pinout Reference (Tang Nano 9K)

| Component | Pin | Note |
| :--- | :--- | :--- |
| Clock | 52 | 27 MHz |
| UART TX | 17 | Connected to BL702 bridge |
| UART RX | 18 | Connected to BL702 bridge |
| LED 0 | 10 | Active Low |
| LED 1 | 11 | Active Low |
| LED 2 | 13 | Active Low |
| LED 3 | 14 | Active Low |
| LED 4 | 15 | Active Low |
| LED 5 | 16 | Active Low |
| Button S1 | 3 | Active Low |
| Button S2 | 4 | Active Low |
