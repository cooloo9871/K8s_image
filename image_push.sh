#!/bin/bash

# set -x

RED='\033[1;31m' # alarm
GRN='\033[1;32m' # notice
YEL='\033[1;33m' # warning
NC='\033[0m' # No Color
registry="$1"


[[ ! -f ./images.txt ]] && printf "${RED}images.txt file not found${NC}\n" && exit 1
image_name=$(paste -sd' ' images.txt)


docker_command() {
sudo docker load < k8s_images.tar &>/dev/null

while read line
do
  img="${line##*/}"
  sudo docker tag $line $registry/library/$img &>/dev/null
  sudo docker push $registry/library/$img &>/dev/null
  if [[ "$?" == 0 ]]; then
    printf "${GRN}push $registry/library/$img success${NC}\n"
  else
    printf "${RED}push $registry/library/$img fail${NC}\n"
  fi
done < images.txt
}

podman_command() {

sudo podman load < k8s_images.tar &>/dev/null

while read line
do
  img="${line##*/}"
  sudo podman tag $line $registry/library/$img &>/dev/null
  sudo podman push --tls-verify=false $registry/library/$img &>/dev/null
  if [[ "$?" == 0 ]]; then
    printf "${GRN}push $registry/library/$img success${NC}\n"
  else
    printf "${RED}push $registry/library/$img fail${NC}\n"
  fi
done < images.txt
}

help() {
  cat <<EOF
Usage: push.sh [harbor domain]

for example: push.sh harbor.example.com
EOF
  exit
}

if ! which docker &>/dev/null && ! which podman &>/dev/null; then
  printf "${RED}docker and podman command not found${NC}\n" && exit 1
fi


sudo -n true &>/dev/null
if [[ "$?" != "0" ]]; then
  printf "${RED}Passwordless sudo is NOT enabled${NC}\n" && exit 1
fi

if [[ "$#" < 1 ]]; then
  help
fi

if which docker &>/dev/null; then
  docker_command
else
  podman_command
fi
