#!/bin/bash

# set -x

RED='\033[1;31m' # alarm
GRN='\033[1;32m' # notice
YEL='\033[1;33m' # warning
NC='\033[0m' # No Color
registry="$1"


[[ ! -f ./images.txt ]] && printf "${RED}images.txt file not found${NC}\n" && exit 1
image_name=$(paste -sd' ' images.txt)


ctr_command() {
while read line
do
  sudo ctr -n k8s.io image pull $line &>/dev/null
  if [[ "$?" == 0 ]]; then
    printf "${GRN}download $line success${NC}\n"
  else
    printf "${RED}download $line fail${NC}\n"
  fi
done < images.txt
}

sudo -n true &>/dev/null
if [[ "$?" != "0" ]]; then
  printf "${RED}Passwordless sudo is NOT enabled${NC}\n" && exit 1
fi

if ! which ctr &>/dev/null; then
  printf "${RED}ctr command not found${NC}\n" && exit 1
else
  ctr_command
fi
