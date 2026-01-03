#!/bin/bash

# set -x

RED='\033[1;31m' # alarm
GRN='\033[1;32m' # notice
YEL='\033[1;33m' # warning
NC='\033[0m' # No Color

[[ ! -f ./images.txt ]] && printf "${RED}images.txt file not found${NC}\n" && exit 1

# 初始化變數用來存儲要打包的 image 列表
SAVE_LIST=""

# 定義處理與下載的函數
process_images() {
    local cmd=$1
    local line

    # 讀取檔案，並去除可能的 Windows 換行符號 (\r)
    # 使用 grep -v '^\s*$' 先把完全空白的行濾掉，再進迴圈處理
    grep -v '^\s*$' images.txt | tr -d '\r' | while read line; do

        # 再次確保去除前後空白 (trim)
        line=$(echo "$line" | xargs)

        # 雙重防護：如果行是空的或是註解(#)，則跳過
        if [[ -z "$line" ]] || [[ "$line" == \#* ]]; then
            continue
        fi

        # 執行 Pull
        sudo $cmd pull "$line" &>/dev/null
        if [[ "$?" == 0 ]]; then
            printf "${GRN}download $line success${NC}\n"
        else
            printf "${RED}download $line fail${NC}\n"
        fi
    done
}

# 重新生成乾淨的 image 列表給 save 指令使用 (去除換行，改為以空白分隔)
# grep -v '^\s*$' : 移除空行
# tr '\n' ' ' : 將換行轉為空白，變成一行字串
SAVE_LIST=$(grep -v '^\s*$' images.txt | grep -v '^\s*#' | tr -d '\r' | tr '\n' ' ')

docker_command() {
    # 1. 下載
    process_images "docker"

    # 2. 打包
    if [[ -n "$SAVE_LIST" ]]; then
        # $SAVE_LIST 沒有引號，讓 shell 自動依空白分割參數
        sudo docker save $SAVE_LIST > k8s_images.tar
        if [[ "$?" == 0 ]]; then
             printf "${GRN}All images have been saved as k8s_images.tar${NC}\n"
        else
             printf "${RED}Save failed${NC}\n"
        fi
    else
        printf "${YEL}No valid images found to save.${NC}\n"
    fi
}

podman_command() {
    # 1. 下載
    process_images "podman"

    # 2. 打包
    if [[ -n "$SAVE_LIST" ]]; then
        # Podman 使用 -m 參數來支援 multi-image archive
        sudo podman save -m $SAVE_LIST > k8s_images.tar
        if [[ "$?" == 0 ]]; then
             printf "${GRN}All images have been saved as k8s_images.tar${NC}\n"
        else
             printf "${RED}Save failed${NC}\n"
        fi
    else
        printf "${YEL}No valid images found to save.${NC}\n"
    fi
}

# 檢查指令是否存在
if ! which docker &>/dev/null && ! which podman &>/dev/null; then
    printf "${RED}docker and podman command not found${NC}\n" && exit 1
fi

# 檢查 sudo 權限
sudo -n true &>/dev/null
if [[ "$?" != "0" ]]; then
    printf "${RED}Passwordless sudo is NOT enabled${NC}\n" && exit 1
fi

# 執行主邏輯
if which docker &>/dev/null; then
    docker_command
else
    podman_command
fi
