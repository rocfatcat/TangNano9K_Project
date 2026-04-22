# System Architecture: eSPI Bus Monitor

## System Overview
The Tang Nano 9K eSPI Bus Monitor is a hardware-based diagnostic tool designed to sniff and analyze the communication between an eSPI Host and its Peripheral. It captures low-level packets, extracts meaningful data (like POST codes and Virtual Wire states), and outputs them to a PC via high-speed UART.

## Component Integration Diagram
```text
  [eSPI Host]           [Tang Nano 9K FPGA]           [PC Terminal]
      |                       |                             |
      |   ESPI_CLK            |   +------------------+      |
      +---------------------->|   |      rPLL        |      |
      |                       |   | (216MHz Sample)  |      |
      |   ESPI_CS#            |   +---------+--------+      |
      +---------------------->|             |               |
      |                       |             V clk_sample    |
      |   ESPI_IO[1:0]        |   +---------+--------+      |
      +---------------------->|   |   espi_sniffer   |      |
                              |   | (Oversampling)   |      |
                              |   +---------+--------+      |
                              |             | espi_raw      |
                              |             V               |
                              |   +---------+--------+      |
                              |   |   ASCII Formatter|      |
                              |   | (Hex -> String)  |      |
                              |   +---------+--------+      |
                              |             |               |
                              |             V UART_TX       |
                              |   +---------+--------+      |
                              |   |    UART Subsys   |----->| UART @ 3M
                              |   | (1KB TX Buffer)  |      |
                              |   +------------------+      |
```

## Key Design Principles
1. **Low Latency Monitoring**: The sniffer works purely in the hardware domain to capture transients that standard logic analyzers might miss.
2. **Frequency Agnostic Monitoring**: By oversampling with a 216MHz clock, the system adapts to any BIOS-driven eSPI clock frequency.
3. **Robust Data Delivery**: The 1KB TX FIFO prevents UART bottlenecks, allowing the system to handle fast bursts of BIOS POST codes (0x80/0x81).

## Current Project Status (Phase 1)
- **Clocking**: PLL generated 216MHz clock is fully integrated and locked.
- **Bus Sniffing**: 16-bit raw capture is active.
- **UART Output**: High-speed 3Mbps UART is transmitting capture results.
- **Physical Constraints**: 1.8V IO with Hysteresis enabled.

## Future Enhancements
- **Phase 2**: Full Command/Address/Data decoding for Port 80h.
- **Phase 3**: Virtual Wire indexing and state tracking.
- **Phase 4**: Long-term logging and PC-side software integration.
