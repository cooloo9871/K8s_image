#!/bin/bash

# set -x

RED='\033[1;31m' # alarm
GRN='\033[1;32m' # notice
YEL='\033[1;33m' # warning
NC='\033[0m' # No Color
registry="$1"

# 檢查 images.txt 是否存在
[[ ! -f ./images.txt ]] && printf "${RED}images.txt file not found${NC}\n" && exit 1

# 定義處理圖片的主要邏輯 (由傳入的指令 docker 或 podman 決定)
process_images() {
  local cmd=$1
  local tls_flag=""

  # 如果是 podman，加入 --tls-verify=false
  if [[ "$cmd" == "podman" ]]; then
    tls_flag="--tls-verify=false"
  fi

  # 1. 檢查檔案是否存在
  if [[ ! -f k8s_images.tar ]]; then
    printf "${RED}Error: k8s_images.tar file not found${NC}\n"
    exit 1
  fi

  # 2. 嘗試載入 tar 檔
  printf "Loading k8s_images.tar... "
  if ! sudo $cmd load < k8s_images.tar &>/dev/null; then
    printf "${RED}Failed${NC}\n"
    printf "${RED}Error: Failed to load k8s_images.tar${NC}\n"
    exit 1
  else
    printf "${GRN}Success${NC}\n"
  fi

  # 讀取 images.txt，過濾掉空行與註解
  while IFS= read -r line || [ -n "$line" ]; do
    # 1. 去除前後空白
    line=$(echo "$line" | xargs)

    # 2. 如果是空行或是註解(#開頭)，就跳過
    if [[ -z "$line" ]] || [[ "$line" == \#* ]]; then
      continue
    fi

    # 取得 image 名稱 (移除路徑，只留最後一段 image:tag)
    img="${line##*/}"

    # Tag 映像檔
    sudo $cmd tag "$line" "$registry/$img" &>/dev/null

    # Push 映像檔
    sudo $cmd push $tls_flag "$registry/$img" &>/dev/null

    if [[ "$?" == 0 ]]; then
      printf "${GRN}push $registry/$img success${NC}\n"
    else
      printf "${RED}push $registry/$img fail${NC}\n"
    fi
  done < images.txt
}

help() {
  cat <<EOF
Usage: push.sh [harbor domain]

for example: push.sh harbor.example.com/library
EOF
  exit
}

# 檢查是否有 docker 或 podman
if ! which docker &>/dev/null && ! which podman &>/dev/null; then
  printf "${RED}docker and podman command not found${NC}\n" && exit 1
fi

# 檢查 sudo 權限
sudo -n true &>/dev/null
if [[ "$?" != "0" ]]; then
  printf "${RED}Passwordless sudo is NOT enabled${NC}\n" && exit 1
fi

# 檢查參數
if [[ "$#" < 1 ]]; then
  help
fi

if which podman &>/dev/null; then
  process_images "podman"
else
  process_images "docker"
fi
