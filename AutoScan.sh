#!/usr/bin/env bash
# AutoScan.sh (clean output + ASCII PASS/FAIL)
# Usage: sudo bash AutoScan.sh <IPv4> <loop-count>
set -euo pipefail

SLEEP_SECONDS=60 # 你可以自己調整每次掃描的時間

# Windows upload settings via env vars or edit here
WIN_HOST="" # 輸入你 Windows vEthernet IPv4
WIN_USER="" # 輸入你的 Windows username
WIN_TARGET_USER="" # 輸入你的 Windows target username
WIN_PASS="" # 輸入你的 Windows 密碼

# ======== ANSI 顏色碼 ========
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m' # reset

# ======== ASCII Functions ========
big_pass() {
echo -e "${GREEN}"
cat <<'EOF'
========================================

######      ####       #######   #######
##   ##    ##  ##     ##        ##
######    ##    ##    ########  ########
##       ##########         ##        ##
##       ##      ##   #######   #######

========================================
EOF
echo -e "${NC}"
}

big_fail() {
echo -e "${RED}"
cat <<'EOF'
========================================

#######     ####     ######   ##
##         ##  ##      ##     ##
######    ##    ##     ##     ##
##       ##########    ##     ##
##       ##      ##  ######   ########

========================================
EOF
echo -e "${NC}"
}
# =================================

command -v nmap >/dev/null 2>&1 || { echo "Error: nmap required."; exit 1; }
command -v scp  >/dev/null 2>&1 || { echo "Error: scp required."; exit 1; }
command -v tar  >/dev/null 2>&1 || { echo "Error: tar required."; exit 1; }
if [ -n "${WIN_PASS}" ]; then
  command -v sshpass >/dev/null 2>&1 || { echo "Error: sshpass required when WIN_PASS is set."; exit 1; }
fi

if [ "$#" -ne 2 ]; then
  echo "Usage: sudo bash $0 <IPv4> <loop-count>"
  exit 1
fi

TARGET_IP="$1"
LOOP_COUNT="$2"

if ! [[ "${TARGET_IP}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
  echo "Error: invalid IPv4: ${TARGET_IP}"
  exit 1
fi
if ! [[ "${LOOP_COUNT}" =~ ^[1-9][0-9]*$ ]]; then
  echo "Error: loop-count must be a positive integer."
  exit 1
fi

# Determine real user/home (handles sudo)
if [ -n "${SUDO_USER:-}" ]; then
  REAL_USER="${SUDO_USER}"
  REAL_HOME=$(getent passwd "${REAL_USER}" | cut -d: -f6)
  [ -z "${REAL_HOME}" ] && REAL_HOME="/home/${REAL_USER}"
else
  REAL_USER=$(whoami)
  REAL_HOME="${HOME}"
fi

DEST_DIR="${REAL_HOME}/Desktop/ScanResult"
mkdir -p "${DEST_DIR}"
if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
  chown "${REAL_USER}:${REAL_USER}" "${DEST_DIR}" || true
fi

echo "Logs will be saved to: ${DEST_DIR}"
echo "Target: ${TARGET_IP}  Loops: ${LOOP_COUNT}  Interval: ${SLEEP_SECONDS}s"
echo

# Use SYN if root, else connect scan; enable -O only as root
if [ "$(id -u)" -eq 0 ]; then
  SCAN_TYPE="-sS"
  OS_FLAG="-O"
  echo "Running as root: -sS and -O enabled."
else
  SCAN_TYPE="-sT"
  OS_FLAG=""
  echo "Not root: -sT (no -O)."
fi

UPLOADED=false
ARCHIVE_PATH=""

pack_and_upload() {
  if [ ! -d "${DEST_DIR}" ] || [ -z "$(ls -A "${DEST_DIR}")" ]; then
    echo "No logs to pack."
    return 0
  fi
  ARCHIVE_PATH="/tmp/ScanResults_${TARGET_IP}_$(date +%Y%m%d_%H%M%S).tar.gz"
  tar -czf "${ARCHIVE_PATH}" -C "${DEST_DIR}" .
  if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
    chown "${REAL_USER}:${REAL_USER}" "${ARCHIVE_PATH}" || true
  fi
  echo "Archive created: ${ARCHIVE_PATH}"

  if [ "${UPLOADED}" = true ]; then
    echo "Archive already uploaded; skipping."
    return 0
  fi

  if [ -n "${WIN_HOST}" ] && [ -n "${WIN_USER}" ] && [ -n "${WIN_TARGET_USER}" ]; then
    REMOTE_PATH="/C:/Users/${WIN_TARGET_USER}/Desktop/"
    echo "Uploading archive to ${WIN_USER}@${WIN_HOST}:${REMOTE_PATH} ..."
    if [ -n "${WIN_PASS}" ]; then
      if sshpass -p "${WIN_PASS}" scp -o StrictHostKeyChecking=no "${ARCHIVE_PATH}" "${WIN_USER}@${WIN_HOST}:${REMOTE_PATH}"; then
        big_pass
      else
        big_fail
      fi
    else
      if scp -o StrictHostKeyChecking=no "${ARCHIVE_PATH}" "${WIN_USER}@${WIN_HOST}:${REMOTE_PATH}"; then
        big_pass
      else
        big_fail
      fi
    fi
    UPLOADED=true
  else
    echo "WIN_* not set -> skipping upload."
  fi
}

on_interrupt() {
  echo
  echo "Interrupt received. Packing/uploading current logs..."
  pack_and_upload
  echo "Exiting due to interrupt."
  exit 1
}
trap on_interrupt SIGINT SIGTERM

# ===== main loop =====
count=0
while [ "$count" -lt "${LOOP_COUNT}" ]; do
  count=$((count+1))
  TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
  LOGFILE="${DEST_DIR}/${TIMESTAMP}_ScanResult.txt"

  echo "=============================="
  echo " Scan #${count}/${LOOP_COUNT}  Timestamp: ${TIMESTAMP}"
  echo "=============================="

  if nmap ${SCAN_TYPE} ${OS_FLAG} --reason -oN "${LOGFILE}" "${TARGET_IP}"; then
    big_pass
  else
    big_fail
  fi

  if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
    chown "${REAL_USER}:${REAL_USER}" "${LOGFILE}" || true
  fi

  echo "Scan #${count} finished. Saved: ${LOGFILE}"
  echo

  if [ "$count" -lt "${LOOP_COUNT}" ]; then
    echo "Sleeping ${SLEEP_SECONDS}s before next scan..."
    sleep "${SLEEP_SECONDS}"
    echo
  fi
done

echo "All scans completed. Packing & uploading..."
pack_and_upload

echo "Done. Logs are in: ${DEST_DIR}"
exit 0
