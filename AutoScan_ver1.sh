#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <IPv4> <loop-count>"
  echo "Example: sudo $0 192.168.1.100 5"
  exit 1
fi

TARGET_IP="$1"
LOOP_COUNT="$2"

if ! [[ "$LOOP_COUNT" =~ ^[1-9][0-9]*$ ]]; then
  echo "Error: loop-count must be a positive integer."
  exit 1
fi

REAL_HOME=$(getent passwd <your_username> | cut -d: -f6)
DEST_DIR="${REAL_HOME}/Desktop/ScanResult"
SLEEP_SECONDS=60
count=0

mkdir -p "${DEST_DIR}"

echo "Start scanning ${TARGET_IP} for ${LOOP_COUNT} loops (interval ${SLEEP_SECONDS}s)."

while [ $count -lt "$LOOP_COUNT" ]; do
  count=$((count + 1))
  now=$(date +"%Y-%m-%d_%H:%M:%S")

  echo "========================================"
  echo "Loop #${count} / ${LOOP_COUNT}  —  ${now}"
  echo "========================================"

  nmap -sT -oN "${DEST_DIR}/${now}_ScanResult.txt" "${TARGET_IP}"

  if [ $count -ge "$LOOP_COUNT" ]; then
    echo "Completed ${count}/${LOOP_COUNT} loops. Exiting."
    break
  fi

  echo "The next scan will be in ${SLEEP_SECONDS}s ..."
  sleep "${SLEEP_SECONDS}"
done

ARCHIVE_PATH="${REAL_HOME}/Desktop/ScanResults_${TARGET_IP}_$(date +%Y%m%d).tar.gz"
tar -czf "${ARCHIVE_PATH}" -C "${DEST_DIR}" .
scp -r "${ARCHIVE_PATH}" "your_username@<your_win_vEtherNetIPv6>:/<your_win_directory"

echo "Complete!"
exit 0
