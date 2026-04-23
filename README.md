# Tang Nano 9K Apicula Template with 3MHz UART & eSPI Sniffer

This is a high-performance project template for the Sipeed Tang Nano 9K FPGA board using the open-source [Apicula](https://github.com/YosysHQ/apicula) toolchain. It features a high-speed eSPI Sniffer with 3MHz UART output.

## Features

- **eSPI Sniffer (Phase 1)**: Captures 16-bit raw data with frequency-adaptive edge detection (supports 20MHz ~ 66MHz).
- **Dual Voltage Support**: Supports both **1.8V** and **3.3V** eSPI buses via compile-time parameters.
- **3MHz UART**: Custom hand-crafted UART engine running at 3Mbps (9 cycles per bit @ 27MHz).
- **1KB FIFOs**: Independent 1024-byte TX and RX buffers using inferred BSRAM.

## Usage

### Build the bitstream (Select Voltage)
The Tang Nano 9K has fixed voltage banks. You must select the correct voltage for your target eSPI bus during compilation.

#### For 1.8V eSPI (Bank 3)
Connect signals to Pin 19 (CLK), 20 (CS#), 5 (IO0), 6 (IO1).
```bash
make clean
make VOLTAGE=1.8
```

#### For 3.3V eSPI (Bank 2)
Connect signals to Pin 25 (CLK), 26 (CS#), 27 (IO0), 28 (IO1).
```bash
make clean
make VOLTAGE=3.3
```

### Upload to Board
```bash
make load
```

## Hardware Pinout Reference (Tang Nano 9K)

| Component | Pin (1.8V Mode) | Pin (3.3V Mode) | Note |
| :--- | :--- | :--- | :--- |
| **eSPI CLK** | **19** | **25** | |
| **eSPI CS#** | **20** | **26** | |
| **eSPI IO0** | **5** | **27** | |
| **eSPI IO1** | **6** | **28** | |
| UART TX | 17 | 17 | 3Mbps Output |
| Clock | 52 | 52 | 27 MHz Crystal |
| LED 0 | 10 | 10 | Status LED (Active Low) |

---
*For full technical specifications, see the `doc/` directory.*
