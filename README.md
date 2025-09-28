![Cover.png](https://github.com/ZhaoMeap/Nmap-AutoScan-ShellScript/blob/main/Cover.png)

# ✒️ AutoScan — 自動化 Nmap 掃描 + 打包上傳工具

一個簡單、易用的 Bash 腳本，可自定義掃描的圈數，對指定 IPv4 做 Nmap  TCP 掃描，將每次掃描的結果儲存到使用者桌面，並且將資料夾打包並一次回傳至 Windows 桌面。

> 檔名：`AutoScan_ver1.sh`

---

### 🍀 主要特色

* 以 `-sT`（TCP）掃描
* 接受兩個參數：目標 IPv4、 loop-count 掃描次數
* 每次掃描會把 nmap 的報告印在 Terminal 並透過 `oN` 輸出為 `<timestamp>_ScanResult.txt` 檔案
* 掃描完成後自動生成 `ScanResult` 資料夾，並打包成 `tar.gz`
* 自動透過 `scp` 回傳給 Windows（需輸入密碼）

---

### 🧩 前置需求

在 Windows 端需要：

* 已啟用並執行 OpenSSH Server（或其他可接受 scp 的服務）
* Windows 使用者能寫入 `C:\Users\<username>\Desktop`

在 Linux 主機上需要安裝：

* `nmap`
* `tar`
* `scp`（OpenSSH client）

---

### 📂 安裝

1. 把 `AutoScan_ver1.sh` 放到你的主機（例如 `~/bin/AutoScan_ver1.sh`）
2. 賦予執行權：

```bash
chmod 777 AutoScan_ver1.sh
```

3. 執行：

```bash
bash AutoScan_ver1.sh <IPv4> <loop-count>
```

---

### ⚙️ 設定方式

你可以把 Windows 連線資訊放到環境變數（推薦）或編輯腳本頂端變數。

範例（在執行前 export）：

```bash
export WIN_HOST="192.168.1.1"
export WIN_USER="your_username"       # 用於 SSH/login 的帳號
export WIN_TARGET_USER="win_username" # Windows 桌面的擁有者 (C:/Users/<winuser>/Desktop)
```

> **不要**把明碼密碼直接提交到 GitHub 或放入公開 repo！

---

### ❓ 常見問題與排查

* **`ssh: connect to host ... port 22: Connection timed out`**
  → 檢查 `WIN_HOST` 是否正確、Windows 上是否啟用了 OpenSSH Server、或防火牆是否允許 TCP 22。
* **檔案無法放到桌面**
  → 若你用 `sudo` 執行，腳本會自動把檔案建立在 `SUDO_USER` 的 Desktop；若你先 `sudo -i` 成 root 再執行，腳本找不到 `SUDO_USER`，會把結果放到 root 的 `$HOME`（這不是預期行為）。建議直接 `bash AutoScan.sh ...` 即可。

---

### 🔒 安全提醒

* 不要把密碼或私密金鑰放到公開的 GitHub！
