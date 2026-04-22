# Module Specification: eSPI Sniffer (Phase 1)

## Overview
The `espi_sniffer` module is a high-speed bus monitor designed to capture eSPI (Enhanced Serial Peripheral Interface) transactions. It utilizes an **oversampling** architecture to achieve frequency auto-adaptation, enabling it to monitor eSPI buses regardless of whether they operate at 20MHz, 33MHz, 50MHz, or 66MHz.

## Internal Architecture
The module consists of four primary functional blocks:
1.  **Triple-Stage Synchronizers**: Filters asynchronous inputs to prevent metastability.
2.  **Edge Detection Pulse Generator**: Identifies the exact sampling moment of the `espi_clk`.
3.  **Shift Register Pipeline**: Collects serial data from `espi_io` lines.
4.  **Transaction Controller**: Manages state transitions based on `espi_cs_n`.

### 1. Metastability & Signal Conditioning
Because the eSPI signals (`clk`, `cs#`, `io`) are asynchronous to the internal `clk_sample`, we employ **3-stage synchronizers** for control lines (`clk`, `cs#`) and 2-stage for data lines (`io`).
- **Why 3 stages?** At 216MHz sampling, the MTBF (Mean Time Between Failures) is significantly improved compared to 2-stage designs, which is critical for 1.8V high-speed signaling.
- **Hysteresis**: The hardware input buffers are configured with high hysteresis to filter out "ringing" or noise during high-speed transitions.

### 2. Frequency Adaptation Logic (Quick View)
The module does **not** use `espi_clk` as a clock source for logic. Instead, it generates a single-cycle pulse `clk_edge` in the `clk_sample` domain.
- **Sampling Window**: Data is sampled precisely 1 internal clock cycle after the `espi_clk` rising edge is registered.
- **Clock Ratio**: For a 66MHz eSPI bus and 216MHz sample clock, we have ~3.2 samples per bit, which is the minimum recommended for reliable detection.

---

## 🚀 Frequency Adaptive Edge Detection (深度解析)

### 1. 核心概念：將時脈視為資料 (Clock as Data)
在傳統的 FPGA 設計中，外部時脈通常直接連接到全域時脈網路 (Global Clock Network)。但在 eSPI 監聽器中，由於 eSPI 頻率可能隨 BIOS 設定而變動（20MHz ~ 66MHz），且我們無法預先得知確切頻率，因此我們採用**過取樣 (Oversampling)** 技術。
- 我們使用一個固定的高頻內部時脈 `clk_sample` (216MHz) 來對外部 `espi_clk` 進行「連續取樣」。
- 透過這種方式，`espi_clk` 被視為一個普通的高速輸入信號，而非驅動邏輯的時脈源。

### 2. 實作步驟：同步與脈衝產生
為了穩定地偵測邊緣，我們使用三級暫存器鏈：

```verilog
reg [2:0] clk_sync;
always @(posedge clk_sample) begin
    clk_sync <= {clk_sync[1:0], espi_clk};
end

wire clk_edge = (clk_sync[2:1] == 2'b01); // 偵測上升沿
```

- **同步化 (Synchronization)**: `clk_sync[0]` 和 `clk_sync[1]` 用於消除亞穩態 (Metastability)。
- **邊緣偵測 (Edge Detection)**: 比較 `clk_sync[2]` (前一個狀態) 與 `clk_sync[1]` (目前狀態)。當發現從 `0` 變為 `1` 時，產生一個僅持續一個 `clk_sample` 週期的脈衝 `clk_edge`。

### 3. 為什麼它是「自適應」的？
- **無關頻率**: 無論 `espi_clk` 的週期是 50ns (20MHz) 還是 15ns (66MHz)，`clk_edge` 脈衝始終只會在上升沿發生時觸發一次。
- **相位無關**: 由於我們取樣頻率遠高於目標頻率，我們不需要與 eSPI Host 進行相位對齊 (Phase Alignment)。
- **抖動容忍**: 即使 eSPI 時脈存在輕微的抖動 (Jitter)，只要它不超過取樣時脈的週期，邊緣偵測依然能精確定位。

### 4. 效能與限制 (The Nyquist Limit)
為了確保取樣可靠，取樣時脈 `f_sample` 與目標時脈 `f_espi` 之間必須滿足一定的比例：
- **理論極限**: `f_sample > 2 * f_espi` (奈奎斯特頻率)。
- **實作建議**: `f_sample > 3 * f_espi`。
  - 當 eSPI = 66MHz 時，216MHz 提供約 **3.27 倍** 的取樣率。
  - 當 eSPI = 33MHz 時，216MHz 提供約 **6.54 倍** 的取樣率。
- **取樣點位移**: 由於同步化電路的存在，實際資料取樣點會相對於真實 eSPI 邊緣延遲約 2~3 個 `clk_sample` 週期（約 10-15ns），這在 1.8V 的訊號環境下是可以接受的，因為資料線 (`io0/io1`) 也經過了同樣的同步處理，保持了相對的時序關係。

---

## 3. Bit Mapping & Data Capture
Currently, the sniffer supports **Single IO Mode** (Standard eSPI).
- **Endianness**: MSB (Most Significant Bit) first.
- **Phase 1 Limit**: Captures the first 16 bits of each transaction:
  - Bits [15:8]: eSPI Command (e.g., `0x01` for Peripheral Write).
  - Bits [7:0]: Header or start of Address field.

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

## Timing Diagram (Internal)
```text
                  Sample 1        Sample 2        Sample 3
clk_sample:  _| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_
espi_clk:    ___________/----------\___________/----------\________
clk_sync[2:1]: 000000001111111111000000000011111111110000000
clk_edge:    __________|___________|___________|___________|_______
io0_sync[1]: __________|---D0------|___________|---D1------|_______
```

## Logic Flow (Detailed)
1.  **IDLE**: Wait for `espi_cs_n` falling edge.
2.  **START**: Reset `bit_cnt` and `shift_reg` on `cs_falling`.
3.  **SYNC**: Continuously synchronize all incoming eSPI lines into the `clk_sample` domain.
4.  **CAPTURE**: On every `clk_edge`, shift `io0_sync` into `shift_reg`.
5.  **COMPLETE**: When `bit_cnt == 15`, latch `shift_reg` to `raw_data` and pulse `raw_valid`.
6.  **WAIT**: Remain in wait state until `espi_cs_n` returns High.

## Limitations & Considerations
- **Dual/Quad Mode**: Current version assumes Single IO. Logic for Dual/Quad mode will be added in Phase 5.
- **Wait States**: Does not currently parse `SBYT` (Wait) cycles between Command and Address. This is scheduled for Phase 2.
- **Signal Integrity**: Requires clean 1.8V signals. Excessive cable length between Host and FPGA will cause sampling errors at high frequencies.
