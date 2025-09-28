# ✒️ AutoScan — 自動化 Nmap 掃描 + 打包上傳工具

一個簡單、易用的 Bash 腳本，可自定義掃描的圈數，對指定 IPv4 做 Nmap  TCP 掃描，將每次掃描的結果儲存到使用者桌面，並且將資料夾打包並一次回傳至 Windows 桌面。輸出經過「清理／美化」，並在每次掃描或上傳結果顯示醒目的大字 `PASS` / `FAIL`。

> 檔名：`AutoScan.sh`（請以 `sudo` 執行）

---

### 目錄

* [主要特色](#️-主要特色)
* [前置需求](#-前置需求)
* [安裝](#-安裝)
* [設定方式](#-設定方式)
* [使用範例](#-使用範例)
* [常見問題與排查](#-常見問題與排查)
* [安全提醒](#-安全提醒)

---

### 🍀 主要特色

* 以 `-sS`（SYN）或在非 root 時自動退回 `-sT`（connect）掃描
* 支援 `-O`（OS fingerprint，需 root）
* 每次掃描會把 nmap 的核心報告（乾淨版）印在終端並存成 `-oN` 檔案
* 掃描完成後自動把 `ScanResult` 資料夾打包成 `tar.gz`，一次上傳到 Windows 桌面（可用密碼或 key）
* 每次掃描 / 上傳會顯示綠色大字 `PASS` 或紅色大字 `FAIL`（上下有分隔線）
* 保留日誌檔（純文字），彩色輸出僅顯示在終端

---

### 🧩 前置需求

在 Windows 端需要：

* 已啟用並執行 OpenSSH Server（或其他可接受 scp 的服務）
* Windows 使用者能寫入 `C:\Users\<username>\Desktop`

在 Linux 主機上需要安裝：

* `nmap`
* `tar`
* `scp`（OpenSSH client）
* 若要用密碼方式上傳：`sshpass`（非必需，但若要免輸入密碼可安裝）

---

### 📂 安裝

1. 把 `AutoScan.sh` 放到你的主機（例如 `~/bin/AutoScan.sh`）
2. 賦予執行權：

```bash
chmod 777 AutoScan.sh
```

3. （建議）用 `sudo` 執行以啟用 OS fingerprint：

```bash
sudo bash AutoScan.sh <IPv4> <loop-count>
```

---

### ⚙️ 設定方式

你可以把 Windows 連線資訊放到環境變數（推薦）或編輯腳本頂端變數。

範例（在執行前 export）：

```bash
export WIN_HOST="192.168.1.1"
export WIN_USER="your_username"       # 用於 SSH/login 的帳號
export WIN_TARGET_USER="win_username" # Windows 桌面的擁有者 (C:/Users/<winuser>/Desktop)
export WIN_PASS="your_password"       # 若要用密碼，可暫時 export
```

或使用 SSH key（推薦、安全）：

```bash
# 在 Linux 建金鑰
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_auto_nmap
# 將公鑰複製到 Windows 的 authorized_keys（假設 Windows 支援）
# 若 ssh-copy-id 在你系統可用：
ssh-copy-id -i ~/.ssh/id_ed25519_auto_nmap.pub winuser@<WIN_HOST>
# 或手動把內容貼到 Windows: C:\Users\<winuser>\.ssh\authorized_keys
```

> **不要**把明碼密碼直接提交到 GitHub 或放入公開 repo！

---

### 📄 使用範例

以 `sudo` 在終端啟動 5 次掃描：

```bash
sudo bash AutoScan.sh 192.168.1.1 5
```

執行流程簡述：

1. 建立 `~/Desktop/ScanResult`（若以 sudo 執行會放到原始使用者的 Desktop）
2. 每次掃描顯示乾淨版 nmap 輸出，並存成 `<TIMESTAMP>_ScanResult.txt`
3. 全部 loop 完成後打包成 `/tmp/ScanResults_<IP>_<TIMESTAMP>.tar.gz` 並透過 `scp` 傳到 Windows Desktop（若設置了 `WIN_*`）

範例終端片段（已經過美化）：

```
Logs will be saved to: /home/raychao/Desktop/ScanResult
Target: 192.168.1.108  Loops: 5  Interval: 60s

Running as root: -sS and -O enabled.
==============================
 Scan #1/5  Timestamp: 20250928_203346
==============================
Starting Nmap 7.95 ( https://nmap.org ) at 2025-09-28 20:33 CST
Nmap scan report for 192.168.1.1
Host is up, received echo-reply ttl 63 (0.0023s latency).
Not shown: 998 closed tcp ports (reset)
PORT    STATE    SERVICE REASON
53/tcp  open     domain  syn-ack ttl 63
443/tcp open     https   syn-ack ttl 63
...

========================================

######      ####      #######   #######  
##   ##    ##  ##    ##        ## 
######    ##    ##   ########  ######## 
##       ##########        ##        ## 
##       ##      ##  #######   #######  

========================================
Scan #1 finished. Saved: /home/raychao/Desktop/ScanResult/20250928_203346_ScanResult.txt

Sleeping 60s before next scan...
```

---

### ❓ 常見問題與排查

* **`ssh: connect to host ... port 22: Connection timed out`**
  → 檢查 `WIN_HOST` 是否正確、Windows 上是否啟用了 OpenSSH Server、或防火牆是否允許 TCP 22。
* **檔案無法放到桌面**
  → 若你用 `sudo` 執行，腳本會自動把檔案建立在 `SUDO_USER` 的 Desktop；若你先 `su` 成 root 再執行，腳本找不到 `SUDO_USER`，會把結果放到 root 的 `$HOME`（這不是預期行為）。建議直接 `sudo bash AutoScan.sh ...`。

---

### 🔒 安全提醒

* 不要把密碼或私密金鑰放到公開的 GitHub。
* 優先使用 SSH key-based authentication。
* 若要使用密碼，請透過環境變數臨時 `export WIN_PASS="..."`，執行後清除 `unset WIN_PASS`。
