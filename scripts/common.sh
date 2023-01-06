#!/bin/bash
#
# Script to have common download, install and utility functions
#

: ${quiet_mode:="true"}
if [ "$quiet_mode" == "true" ]; then
  quiet_mode_flag="-q"
fi

#
# This function downloads a installer using wget
#
# $1 is the install folder name, used as tag for log
# $2 is the installer executable name
# $3 is the web path from which to download (wget) the installer
# $4 is additional options to pass to 'wget'
#
wget_download() {
    if [ ! -e $2 ]
    then
        echo "[$1] Downloading ..."
        wget $quiet_mode_flag $3/$2 $4
        chmod +x $2
        echo "[$1] Done"
    fi
}

install_dsplib() {
    local dsplib_version=$1
    local install_dir=$2
    local mcupsdk_setup_dir=$3
    local dsplib_url="https://software-dl.ti.com/sdoemb/sdoemb_public_sw/dsplib/latest//exports/"
    local dsplib_folder="dsplib_c66x_${dsplib_version}"
    local dsplib_install_file="dsplib_c66x_${dsplib_version}_Linux.bin"

    echo "[DSPLIB $1] Checking ..."
    if [ ! -d "${install_dir}/${dsplib_folder}" ]
    then
        wget_download ${dsplib_folder} ${dsplib_install_file} ${dsplib_url}
        chmod +x ${dsplib_install_file}
        ./${dsplib_install_file} --mode silent --prefix ${install_dir}/${dsplib_folder}
        rm -f ${dsplib_install_file}

        #Apply DSPLIB patch
        echo "Applying patch ..."
        pushd ${install_dir}/${dsplib_folder} 1>/dev/null
        patch -p1 < ${mcupsdk_setup_dir}/patch/dsplib_3_4_0_0.patch
        popd 1>/dev/null
    fi

    echo "[DSPLIB $1] Done ..."
}

install_ccs() {
    local ccs_version=$1
    local install_dir=$2
    local ccs_version_major=`echo ${ccs_version} | cut -d "." -f 1`
    local ccs_version_short=`echo ${ccs_version} | cut -d "." -f -3 | sed -e "s|\.|_|g"`
    local ccs_version_short_dot=`echo ${ccs_version_short} | sed -e "s|\_|.|g"`
    local ccs_folder=ccs`echo ${ccs_version} | cut -d "." -f -3 | sed -e "s|\.||g"`
    local ccs_install_file="CCS${ccs_version}_linux-x64.tar.gz"
    local ccs_url="https://dr-download.ti.com/software-development/ide-configuration-compiler-or-debugger/MD-J1VdearkvK/${ccs_version_short_dot}"

    local ccs_untar_folder=`echo ${ccs_install_file} | sed -e "s|\.tar\.gz||g"`

    echo "[ccs $1] Checking ..."
    if [ ! -d "${install_dir}/${ccs_folder}" ]
    then
        wget_download ${ccs_folder} ${ccs_install_file} ${ccs_url}
        mkdir -p "${install_dir}"
        tar xf ${ccs_install_file} -C "${install_dir}"
        echo "[${ccs_folder}] Installing ..."
        ${install_dir}/${ccs_untar_folder}/ccs_setup_${ccs_version}.run --mode unattended --prefix "${install_dir}/${ccs_folder}"

        #Clean-up
        rm -f ${ccs_install_file}
        rm -rf "${install_dir}/${ccs_untar_folder}"
    fi
    echo "[${ccs_folder}] Done "
}

ccs_discover_tools() {
    local ccs_version=$1
    local install_dir=$2
    local ccs_folder=ccs`echo ${ccs_version} | cut -d "." -f -3 | sed -e "s|\.||g"`

    if [ -d "${install_dir}/${ccs_folder}" ]
    then
        echo "[ccs $1] Discover installed tools ..."
        pushd ${install_dir}/${ccs_folder}/ccs/eclipse 1>/dev/null

        ./eclipse -nosplash -application com.ti.common.core.initialize -data ~/workspace 2>>ccs_log.txt
        cat ./configuration/com.ti.common.project.core/compilerProperties.cache.log

        popd 1>/dev/null
        echo "[ccs $1] Discover installed tools ... Done "
    fi
}

install_nodejs() {
    local version=$1
    local mcu_plus_sdk_folder=$2

    if [ ! -d ~/.nvm/versions/node/v${version} ]; then
        echo "[nodejs ${version}] Installing ..."

        curl -sL https://raw.githubusercontent.com/creationix/nvm/v0.35.3/install.sh -o install_nvm.sh
        if [ -e install_nvm.sh ]; then
            if grep -q "nvm" install_nvm.sh; then
                bash install_nvm.sh
                export NVM_DIR="${HOME}/.nvm"
                [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
                nvm install ${version}
                [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
            else
                echo "ERROR: Installation of NodeJS v${version} failed. Please install manually and do 'npm ci' inside mcu_plus_sdk once installed."
                return 1
            fi
        else
            echo "ERROR: Installation of NodeJS v${version} failed. Please install manually and do 'npm ci' inside mcu_plus_sdk once installed."
            return 1
        fi
        #Clean-up
        rm -f install_nvm.sh

        echo "[nodejs ${version}] Done "
    fi

    #Install required nodejs packages
    export PATH=~/.nvm/versions/node/v${version}/bin:$PATH
    if [ ! -d ${mcu_plus_sdk_folder}/node_modules ]; then
        echo "[nodejs packages] Installing required nodejs packages ..."
        cd ${mcu_plus_sdk_folder}
        npm ci
        cd - 1>/dev/null
        echo "[nodejs packages] Done "
    fi
}

install_syscfg() {
    local version=$1
    local install_dir=$2
    local version_dot=`echo ${version} | sed -e "s|\_|.|g"`
    local syscfg_install_file="sysconfig-${version}-setup.run"
    local syscfg_build_version=`echo ${version} | cut -d "_" -f 2`
    local syscfg_folder=sysconfig_`echo ${version} | cut -d "_" -f 1`
    local syscfg_url="https://dr-download.ti.com/software-development/ide-configuration-compiler-or-debugger/MD-nsUM6f7Vvb/${version_dot}"

    echo "[syscfg ${version}] Checking ..."
    if [ ! -d "${install_dir}/${syscfg_folder}" ]
    then
        echo "[syscfg ${version}] Installing ..."

        wget_download ${syscfg_folder} ${syscfg_install_file} ${syscfg_url}
        ./${syscfg_install_file} --mode unattended --prefix "${install_dir}/${syscfg_folder}"

        # Clean-up
        rm -f ${syscfg_install_file}
    fi

    echo "[syscfg ${version}] Done "
}

install_clang() {
    local version=$1
    local clang_url_folder=$2
    local clang_install_folder=$3
    local clang_install_file=$4
    local install_dir=$5

    echo "[ti-cgt-armllvm ${version}] Checking ..."
    if [ ! -d "${install_dir}"/${clang_install_folder} ]
    then
        wget -q https://dr-download.ti.com/software-development/ide-configuration-compiler-or-debugger/MD-ayxs93eZNN/${clang_url_folder}/${clang_install_file}
        chmod +x ${clang_install_file}
        ./${clang_install_file} --mode unattended --prefix "${install_dir}"

        #Clean-up
        rm -f ${clang_install_file}
    fi
    echo "[ti-cgt-armllvm ${version}] Done "
}

install_gcc_aarch64() {
    local version=$1
    local gcc_install_folder=$2
    local gcc_download_file=$3
    local install_dir=$4
    local gcc_url="https://developer.arm.com/-/media/Files/downloads/gnu-a/${version}/binrel"

    echo "[gcc-arm-none-eabi ${version}] Checking ..."

    if [ ! -d "${install_dir}"/${gcc_install_folder} ]
    then
        wget_download ${gcc_install_folder} ${gcc_download_file} ${gcc_url}
        tar -C ${install_dir} -xf ${gcc_download_file}

        #Clean-up
        rm ${gcc_download_file}
    fi
    echo
}

install_gcc_arm() {
    local version=$1
    local gcc_install_folder=$2
    local gcc_download_file=$3
    local install_dir=$4
    local version_folder=$5
    local gcc_url="https://developer.arm.com/-/media/Files/downloads/gnu-rm/${version_folder}"

    echo "[gcc-arm-none-eabi ${version}] Checking ..."

    if [ ! -d "${install_dir}"/${gcc_install_folder} ]
    then
        wget_download ${gcc_install_folder} ${gcc_download_file} ${gcc_url}
        tar -C ${install_dir} -xf ${gcc_download_file}

        #Clean-up
        rm ${gcc_download_file}
    fi
    echo
}

install_doxygen() {
    local version=$1
    local version_underscore=`echo ${version} | sed -e "s|\.|_|g"`

    sudo apt-get install -y cmake flex bison
    sudo apt-get remove -y doxygen

    if ! command -v doxygen  &> /dev/null
    then
        echo "[doxygen ${version}]  Installing ..."
        pushd ${HOME} 1>/dev/null
        git clone -q https://github.com/doxygen/doxygen.git
        cd doxygen
        git checkout Release_${version_underscore} 1>/dev/null
        mkdir build
        cd build
        cmake -G "Unix Makefiles" .. 1>/dev/null
        make -j8    1>/dev/null
        sudo make install
        echo "[doxygen ${version}]  Done"
        popd 1>/dev/null
    fi
}

#
# This function is used to replace the tag/reference in a repo manifest file
#
# $1 is the repo manifest file path
# $2 is the repo name to grep
# $3 is the tag to replace
#
tag_replace() {
    if [ $# -ge 3 ] &&  [ -n "$3" ]; then
        #For Branches or Tags
        local find_str="$2\"[ \t]*revision=\"[0-9A-Za-z_\-\.\/]*\""
        local replace_str="$2\" revision=\"$3\" clone-depth=\"1\""
        sed -i -e "s|$find_str|$replace_str|g" $1
    else
        local find_str="$2\"[ \t]*revision=(\"[0-9A-Za-z_\-]*\")"
        local replace_str="$2\" revision=\1 clone-depth=\"1\""
        sed -r -i -e "s|$find_str|$replace_str|g" $1
    fi
}

#
# This function is used to print the time difference
#
# $1 is the start time
#
print_time_diff() {
    local end_time=`date +%s`
    local start_time=$1
    local deltatime=$((end_time-start_time))
    local hours=$((deltatime/3600))
    local minutes=$((deltatime/60))
    local minutes=$((minutes%60))
    local seconds=$((deltatime%60))
    LC_NUMERIC="en_US.UTF-8" printf "$2: %d:%02d:%02d\n" $hours $minutes $seconds
}

# find highest numbered file with pattern $1, strip filename and extension and keep only the version
get_version_file() {
    if [ -d $3 ]; then
        cd $3
        find . -maxdepth 1 -name "$1*" | sort -r -n | head -n1 | sed "s/.\///" | sed "s/$2//" | sed "s/$1//"
        cd - > /dev/null
    else
        # file not found, script will give a error later, return a reasonable file name here, i.e $1$2
        echo $1$2
    fi
}

recur_copy() {
    #echo "Copying files of type $1 from $2 to $3 ..."
    find ./ -iname $1  | \
    while read filepath; do
        cp --parent --target-directory=$2 "$filepath"
    done
}

tar_xz() {
    tar -cJf ${2}.tar.xz ${1}
}

untar_xz() {
    tar -xf ${1} ${2}
}
