# eSPI Bus Monitor 開發計畫 (eSPI Bus Monitor Development Plan)

此計畫旨在 Tang Nano 9K 上實現 eSPI 匯流排監聽功能，重點在於 Port 80/81 與 Virtual Wire 的解析，並透過 3MHz UART 輸出結果。

## 核心規格 (Target Specs)
- **eSPI 頻率**: 支援 20MHz / 33MHz 監聽 (需配合 PLL 升頻)。
- **電壓**: 1.8V LVCMOS (需確認硬體連線)。
- **監控通道**: 
  - Peripheral Channel (Port 80h, 81h POST codes)
  - Virtual Wire Channel (System Events)
- **輸出**: UART (3,000,000 Baudrate)

---

## 階段一：物理層與時脈基礎建設 (Physical Layer & Clocking)
**目標**: 建立穩定的高頻取樣時脈並實作「頻率自適應」邊緣偵測。

1. **PLL 設置**: 
   - 使用 Gowin IP Core 產生 **200MHz - 250MHz** 的取樣時脈 (`clk_sample`)。
2. **IO 配置**: 
   - 設定 `espi_clk`, `espi_cs_n`, `espi_io[1:0]` 為 1.8V 輸入，並開啟 `HYSTERESIS` 以減少雜訊。
3. **頻率自適應邊緣偵測 (Frequency Adaptive Edge Detection)**:
   - 實作 `espi_clk` 同步化電路，偵測其上升沿脈衝 (`clk_edge_p`)。
   - 所有 eSPI 資料狀態機將由 `clk_sample` 驅動，但僅在 `clk_edge_p` 為高時更新狀態。
   - **優點**: 無需預知 Host 頻率，自動跟隨 `espi_clk` 的任何速度變化。
4. **Raw Data Sniffer**: 
   - 驗證：透過 UART 輸出捕捉到的原始 16進制數值，確認不同 Host 頻率下資料皆正確。


## 階段二：指令解析與 Peripheral Channel (Command & Port 80/81)
**目標**: 解析 eSPI 封包標頭並過濾 I/O 寫入操作。

1. **Start Bit & Command Decoding**: 
   - 識別 `SBYT` (Wait) 與 `Command` 欄位。
2. **I/O Write Filter**: 
   - 偵測 `Peripheral I/O Write` 指令 (Command 0x01/0x09)。
   - 解析 16-bit 或是 32-bit 位址。
3. **Port 80/81 提取**: 
   - 當位址為 `0x00000080` 或 `0x00000081` 時，抓取 Data 欄位。
   - 驗證：UART 輸出 `P80: XX` 或 `P81: YY`。

## 階段三：Virtual Wire Channel 解析 (Virtual Wire Decoding)
**目標**: 監聽 eSPI Virtual Wire 封包以追蹤系統狀態變化。

1. **VW Packet Detection**: 
   - 識別 `Virtual Wire` 指令 (Command 0x04/0x05)。
2. **Index & State Extraction**: 
   - 解析 `Index` (例如 0x02 為 System Event) 與 `Data` (位元映射狀態)。
3. **事件觸發與輸出**: 
   - 當指定的 Virtual Wire (如 `PLTRST#`, `SUS_STAT#`, `SMI#`) 狀態改變時進行輸出。
   - 驗證：UART 輸出 `VW [Index]: State`。

## 階段四：資料流與 FIFO 優化 (Data Flow & Buffer Optimization)
**目標**: 確保在高頻率大量資料下，UART 輸出不遺失。

1. **深度 FIFO 整合**: 
   - 利用之前建立的 1KB FIFO 緩衝待傳送的字串。
2. **字串格式化模組**: 
   - 實作一個硬體狀態機，將二進位資料轉為 ASCII 字串 (如 "P80: 4F\n") 以便閱讀。
3. **壓力測試**: 
   - 測試系統啟動過程中的大量 POST Code 輸出穩定性。

## 階段五：進階功能與穩定化 (Advanced Features & Stabilization)
1. **CRC8 驗證**: 
   - 實作 eSPI CRC8 校驗以確保解析資料準確。
2. **多通道切換**: 
   - 支援 Single/Dual IO 模式自動偵測。
3. **人機介面優化**: 
   - 加入時間戳記 (Timestamping) 紀錄 POST Code 間隔。

---

## 最小功能驗證 (MVP Checklist)
- [ ] 1. PLL 產生 150MHz+ 時脈成功。
- [ ] 2. UART 能正確輸出 CS# 下降後的首個 Byte。
- [ ] 3. 成功偵測到 0x80 位址的寫入操作。
- [ ] 4. 成功解析第一個 Virtual Wire 狀態變更。
