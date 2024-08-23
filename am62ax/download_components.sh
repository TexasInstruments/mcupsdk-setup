#!/bin/bash
#
# Script to download and install PSDK MCU baselined components
#

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --mcu_plus_sdk_folder=*)
    mcu_plus_sdk_folder="${1#*=}"
    shift # past argument
    ;;
    --install_dir=*)
    install_dir="${1#*=}"
    shift # past argument
    ;;
    --skip_nodejs=*)
    skip_nodejs="${1#*=}"
    shift # past argument
    ;;
    --skip_doxygen=*)
    skip_doxygen="${1#*=}"
    shift # past argument
    ;;
    --skip_ccs=*)
    skip_ccs="${1#*=}"
    shift # past argument
    ;;
    -h|--help)
    echo Usage: $0 [options]
    echo
    echo Options
    echo "--mcu_plus_sdk_folder  Path to the MCU+ SDK Core folder. Default value is mcu_plus_sdk"
    echo "--install_dir          Path where the tools should be installed. Default value is "${HOME}/ti""
    echo "--skip_nodejs          Pass "--skip_nodejs=true" to skip nodejs installation. Default value is false."
    echo "--skip_doxygen         Pass "--skip_doxygen=true" to skip doxygen installation. Default value is false."
    echo "--skip_ccs             Pass "--skip_ccs=true" to skip CCS installation. Default value is false."
    exit 0
    ;;
esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

: ${mcu_plus_sdk_folder:="mcu_plus_sdk"}
: ${install_dir:="${HOME}/ti"}
: ${skip_nodejs:="false"}
: ${skip_doxygen:="false"}
: ${skip_ccs:="false"}

release_version=10_00_00
product_family="am62ax"
THIS_DIR=$(dirname $(realpath $0))
BASE_DIR=$(realpath ${THIS_DIR}/..)
script=${BASE_DIR}/releases/${release_version}/${product_family}/download_components.sh

#Reuse current release version download script
echo "Invoking ${script}"
${script} --mcu_plus_sdk_folder="${mcu_plus_sdk_folder}" --install_dir="${install_dir}" --skip_nodejs="${skip_nodejs}" --skip_doxygen="${skip_doxygen}" --skip_ccs="${skip_ccs}" --product_family="${product_family}"
