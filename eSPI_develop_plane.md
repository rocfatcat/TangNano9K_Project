# eSPI Bus Monitor 開發計畫 (eSPI Bus Monitor Development Plan)

此計畫旨在 Tang Nano 9K 上實現 eSPI 匯流排監聽功能，重點在於 Port 80/81 與 Virtual Wire 的解析，並透過 3MHz UART 輸出結果。

## 核心規格 (Target Specs)
- **eSPI 頻率**: 支援 20MHz ~ 66MHz 監聽 (已實現 216MHz PLL 自適應取樣)。
- **電壓**: 1.8V LVCMOS (已於 .cst 配置)。
- **監控通道**: 
  - Peripheral Channel (Port 80h, 81h POST codes)
  - Virtual Wire Channel (System Events)
- **輸出**: UART (3,000,000 Baudrate)

---

## 階段一：物理層與時脈基礎建設 (Physical Layer & Clocking) - [DONE]
**目標**: 建立穩定的高頻取樣時脈並實作「頻率自適應」邊緣偵測。

1. **PLL 設置**: 
   - [x] 使用 `rPLL` 產生 **216MHz** 的高頻取樣時脈 (`clk_sample`)。
2. **IO 配置**: 
   - [x] 設定 `espi_clk`, `espi_cs_n`, `espi_io[1:0]` 為 1.8V 輸入並開啟 `HYSTERESIS`。
3. **頻率自適應邊緣偵測**:
   - [x] 實作三級同步化與邊緣脈衝偵測 (`clk_edge`)。
4. **Raw Data Sniffer**: 
   - [x] 實作 `espi_sniffer` 捕捉首 16 bits 資料。
   - [x] 實作 ASCII 格式化與 UART 輸出邏輯。

## 階段二：指令解析與 Peripheral Channel (Command & Port 80/81) - [IN PROGRESS]
**目標**: 解析 eSPI 封包標頭並過濾 I/O 寫入操作。

1. **Wait State (SBYT) 處理**: 
   - 處理 Host 在 Command 之後可能插入的 Wait 狀態。
2. **Peripheral I/O Write 過濾**: 
   - 識別 `Peripheral I/O Write` 指令 (0x01: Single Byte, 0x09: Multi-Byte)。
3. **位址解析 (Address Decoding)**: 
   - 提取 16/32-bit 位址欄位。
4. **Port 80/81 數據提取**: 
   - 當位址匹配 `0x80` 或 `0x81` 時，抓取對應的數據 Byte。
   - 驗證：UART 輸出格式化字串如 `P80: 4F`。

## 階段三：Virtual Wire Channel 解析 (Virtual Wire Decoding)
**目標**: 監聽 eSPI Virtual Wire 封包以追蹤系統狀態變化。

1. **VW Packet Detection**: 
   - 識別 `Virtual Wire` 指令 (0x04: Get_VWire, 0x05: Set_VWire)。
2. **Index & State Extraction**: 
   - 解析 `Index` (如 0x02: System Event) 與 `Data` (位元映射狀態)。
3. **事件觸發與輸出**: 
   - 偵測 `PLTRST#`, `SUS_STAT#` 等重要信號變化。

## 階段四：資料流與 FIFO 優化 (Data Flow & Buffer Optimization)
1. **深度 FIFO 整合**: 擴大緩衝區以應對開機時的高速 POST code 爆發。
2. **字串格式化模組**: 實作更完整、可讀性更高的 UART 協定。

## 階段五：進階功能與穩定化 (Advanced Features & Stabilization)
1. **CRC8 驗證**: 實作 eSPI CRC8 校驗。
2. **多通道切換**: 支援 Single/Dual/Quad IO 自動偵測。

---

## 最小功能驗證 (MVP Checklist)
- [x] 1. PLL 產生 216MHz 時脈並鎖定 (Lock)。
- [x] 2. UART 能正確輸出 CS# 下降後的原始 16 bits 資料。
- [ ] 3. 成功偵測到 0x80 位址的寫入操作並解析出數據。
- [ ] 4. 成功解析第一個 Virtual Wire 狀態變更。
