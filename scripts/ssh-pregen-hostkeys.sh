#!/bin/bash
#
# pre-generate SSH host keys for yocto image, uses custom recipe to install,
# run as needed for dev builds only (this is a bad thing, you know that,
# right?)

TOP_DIR=${1:-""}
DEF_PATH=./layers/meta-user-aa1
DEBUG=${2:-"1"}


! [[ -z "${TOP_DIR}" ]]  || TOP_DIR="${DEF_PATH}"

ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key -N ""
ssh-keygen -t ed25519 -f ssh_host_ed25519_key -N ""

# dropbearkey -t rsa -s 4096 -f dropbear_rsa_host_key
# dropbearkey -t ed25519 -f dropbear_ed25519_host_key

! [[ "${DEBUG}" = "1" ]]  || echo "Running with TOP_DIR:  ${TOP_DIR}"

mv -v ssh_host_*_key* "${TOP_DIR}/recipes-connectivity/ssh-pregen-hostkeys/ssh-pregen-hostkeys"
# mv -v dropbear_*_host_key "${TOP_DIR}/recipes-connectivity/ssh-pregen-hostkeys/ssh-pregen-hostkeys"
