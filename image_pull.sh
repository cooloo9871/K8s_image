#!/bin/bash

#set -x

RED='\033[1;31m' # alarm
GRN='\033[1;32m' # notice
YEL='\033[1;33m' # warning
NC='\033[0m' # No Color

[[ ! -f ./images.txt ]] && printf "${RED}images.txt file not found${NC}\n" && exit 1
image_name=$(paste -sd' ' images.txt)


docker_command() {
while read line
do
  sudo docker pull $line &>/dev/null
  if [[ "$?" == 0 ]]; then
    printf "${GRN}download $line success${NC}\n"
  else
    printf "${RED}download $line fail${NC}\n"
  fi
done < images.txt

sudo docker save $image_name > k8s_images.tar

tar --zstd -cf images.tar.zst k8s_images.tar

rm -rf k8s_images.tar
printf "${GRN}All images have been saved as images.tar.zst${NC}\n"
}

podman_command() {
while read line
do
  sudo podman pull $line &>/dev/null
  if [[ "$?" == 0 ]]; then
    printf "${GRN}download $line success${NC}\n"
  else
    printf "${RED}download $line fail${NC}\n"
  fi
done < images.txt

sudo podman save -m $image_name > k8s_images.tar

tar --zstd -cf images.tar.zst k8s_images.tar

rm -rf k8s_images.tar
printf "${GRN}All images have been saved as images.tar.zst${NC}\n"
}

if ! which docker &>/dev/null && ! which podman &>/dev/null; then
  printf "${RED}docker and podman command not found${NC}\n" && exit 1
fi


sudo -n true &>/dev/null
if [[ "$?" != "0" ]]; then
  printf "${RED}Passwordless sudo is NOT enabled${NC}\n" && exit 1
fi

if which docker &>/dev/null; then
  docker_command
else
  podman_command
fi
