#!/bin/sh
# =============================================================================
# ARMNN build script written by madobet 2020.12.01
# Tested with Ubuntu 18.04
# =============================================================================
MANUAL_DEP=${MANUAL_DEP:-y}         # 是否手动安装依赖
APT_SMART=${APT_SMART:-n}           # 是否启用 apt-samrt 自动配置镜像源
# export BSP_LOCATE=${BSP_LOCATE:-/opt/fsl-imx-xwayland/5.4-zeus}  # 编译的发行版本
export BSP_LOCATE=${BSP_LOCATE:-/opt/fsl-imx-wayland/5.4-zeus}  # 编译的发行版本
# ! 特别注意 SDK 安装后直接移动是无法正常使用，更换安装位置需要重新运行 .sh 部署
export ROOT_DIR=${1:-$PWD}          # 相对位置
export DEPLOY_TARGET_x86_64=${1:-$ROOT_DIR/build/x86_64} # SDK and unit test deploy path
export DEPLOY_TARGET_arm64=${1:-$ROOT_DIR/build/arm64} # SDK and unit test deploy path
# export DEPLOY_TARGET_x86_64=$BSP_LOCATE/sysroots/x86_64-pokysdk-linux/usr
# export DEPLOY_TARGET_arm64=$BSP_LOCATE/sysroots/aarch64-poky-linux/usr

# 保护现场
export _path_bak="$PATH"
export _ldlib_bak="$LD_LIBRARY_PATH"

# -----------------------------------------------------------------------------
. "$ROOT_DIR/modules/functions.sh"

compile_install_protobuf_x86_64(){
    hint compile_install_protobuf_x86_64
    cd "$ROOT_DIR"
    if [ ! -d protobuf ]; then
        # git clone -b v3.5.2 https://github.com/google/protobuf.git protobuf &&
        git clone -b v3.5.1 https://github.com/google/protobuf.git protobuf &&
        git submodule update --init --recursive
        cd protobuf && ./autogen.sh
    else
        cd protobuf
    fi

    # Requires cUrl, autoconf, llibtool, and other build dependencies
    [ ! -d build_x86_64 ] && mkdir build_x86_64
    cd build_x86_64
    ../configure --prefix="$DEPLOY_TARGET_x86_64"
    make -j$(cpu_cores) && make install
    cd "$ROOT_DIR" && color_print -s "finished!"
}

compile_install_protobuf_arm64(){
    hint compile_install_protobuf_arm64
    sh "$ROOT_DIR/modules/build_protobuf_arm64.sh"
    cd "$ROOT_DIR" && color_print -s "finished!"
}

compile_caffe_x86_64(){
    hint compile_caffe_x86_64
    if [ $MANUAL_DEP = n ]; then
      if command -v apt 2>&1 >/dev/null; then
        export DEBIAN_FRONTEND=noninteractive

        color_print -i $(command -v apt) install dependency...
        # Ubuntu 18.04 installation. These steps are taken from the full Caffe
        # installation documentation at: http://caffe.berkeleyvision.org/install_apt.html
        # Install dependencies:
        sudo apt-get -y upgrade
        sudo apt-get -y install libleveldb-dev libsnappy-dev libopencv-dev libhdf5-serial-dev
        sudo apt-get -y install --no-install-recommends libboost-all-dev
        sudo apt-get -y install libgflags-dev libgoogle-glog-dev liblmdb-dev
        sudo apt-get -y install libopenblas-dev libatlas-base-dev
        sudo apt-get -y install libhdf5-dev libopencv-dev libleveldb-dev libsnappy-dev
        sudo apt-get -y install ghc
        sudo apt-get -y autoremove
      else
        color_print -w apt not found, dependency should be resolved manually
      fi
    else
      color_print -w manually dependency selected
    fi

    # Download Caffe-Master from: https://github.com/BVLC/caffe
    cd "$ROOT_DIR" && smart_clone https://github.com/BVLC/caffe.git
    cd caffe && cp Makefile.config.example Makefile.config
    echo "CPU_ONLY := 1" >> Makefile.config
    # 链接器报找不到引用，取消注释 USE_PKG_CONFIG := 1 让 pgk-config 去找
    echo "USE_PKG_CONFIG := 1" >> Makefile.config
    echo "INCLUDE_DIRS += /usr/include/hdf5/serial/ $DEPLOY_TARGET_x86_64/include/" >> Makefile.config
    echo "LIBRARY_DIRS += /usr/lib/x86_64-linux-gnu/hdf5/serial/ $DEPLOY_TARGET_x86_64/lib/" >> Makefile.config

    # Setup environment, x86 的 protobuf 似乎没有包含在 BSP 的 SDK 里，所以这里要用手动编译的哪个
    export PATH=$DEPLOY_TARGET_x86_64/bin/:$PATH
    export LD_LIBRARY_PATH=$DEPLOY_TARGET_x86_64/lib/:$LD_LIBRARY_PATH

    # Compilation with Make:
    make all -j$(cpu_cores)
    # make test -j$(cpu_cores)
    # make runtest -j$(cpu_cores)

    # caffe.pb.h and caffe.pb.cc will be needed when building ArmNN's Caffe Parser

    # 还原现场
    export PATH=$_path_bak
    export LD_LIBRARY_PATH=$_ldlib_bak
    cd $ROOT_DIR && color_print -s "finished!"
}

compile_install_boost_arm64(){
    hint compile_install_boost_arm64
    sh "$ROOT_DIR/modules/build_boost_arm64.sh"
    cd "$ROOT_DIR" && color_print -s "finished!"
}

compile_compute_lib_arm64(){
    hint compile_compute_lib_arm64
    sh "$ROOT_DIR/modules/build_compute-lib_arm64.sh"
    cd "$ROOT_DIR" && color_print -s "finished!"
}

compile_install_flatbuffer_x86_64(){
    hint compile_install_flatbuffer_x86_64
    cd "$ROOT_DIR"
    if [ ! -d flatbuffer-1.12.0 ]; then
        if [ ! -f flatbuffers-1.12.0.tar.gz ]; then
            color_print -w downloading flatbuffers-1.12.0.tar.gz...
            wget -O flatbuffers-1.12.0.tar.gz \
            https://github.com/google/flatbuffers/archive/v1.12.0.tar.gz
            [ $? -ne 0 ] &&
                color_print -e flatbuffers-1.12.0.tar.gz download failed &&
                return 1
        fi
        color_print -i unarchiving flatbuffers-1.12.0.tar.gz...
        tar -xvf flatbuffers-1.12.0.tar.gz
    fi

    cd flatbuffers-1.12.0
    [ ! -d build_x86_64 ] && mkdir build_x86_64
    cd build_x86_64
    cmake .. -DCMAKE_INSTALL_PREFIX:PATH="$DEPLOY_TARGET_x86_64" \
             -DFLATBUFFERS_BUILD_FLATC=1 \
             -DFLATBUFFERS_BUILD_TESTS=0
    make all -j$(cpu_cores) && make install
    cd "$ROOT_DIR" && color_print -s "finished!"
}

compile_install_flatbuffer_arm64(){
    hint compile_install_flatbuffer_arm64
    cd "$ROOT_DIR"
    sh "$ROOT_DIR/modules/build_flatbuffers_arm64.sh"
    cd "$ROOT_DIR" && color_print -s "finished!"
}

prepare_onnx(){
    hint prepare_onnx
    cd "$ROOT_DIR" && smart_clone https://github.com/onnx/onnx.git
    cd onnx && git fetch https://github.com/onnx/onnx.git \
        f612532843bd8e24efeab2815e45b436479cc9ab && git checkout FETCH_HEAD
    export LD_LIBRARY_PATH=$DEPLOY_TARGET_x86_64/protobuf-host/lib:$LD_LIBRARY_PATH
    $DEPLOY_TARGET_x86_64/bin/protoc $ROOT_DIR/onnx/onnx/onnx.proto \
        --proto_path=$ROOT_DIR/onnx \
        --proto_path=$DEPLOY_TARGET_x86_64/include \
        --cpp_out $ROOT_DIR/onnx
    # 还原现场
    export PATH=$_path_bak
    export LD_LIBRARY_PATH=$_ldlib_bak
    cd $ROOT_DIR && color_print -s "finished!"
}

prepare_tflite(){
    hint prepare_tflite
    cd $ROOT_DIR
    [ ! -d tflite ] && mkdir tflite
    cd tflite &&
    cp $ROOT_DIR/tensorflow/tensorflow/lite/schema/schema.fbs $ROOT_DIR/tflite/
    $ROOT_DIR/flatbuffers-1.12.0/build_x86_64/flatc -c \
        --gen-object-api --reflect-types \
        --reflect-names $ROOT_DIR/tflite/schema.fbs
    cd $ROOT_DIR && color_print -s "finished!"
}

gen_tf_protobuf(){
    cd $ROOT_DIR && smart_clone https://github.com/tensorflow/tensorflow.git
    cd tensorflow/ && git checkout 590d6eef7e91a6a7392c8ffffb7b58f2e0c8bc6b
    $ROOT_DIR/armnn/scripts/generate_tensorflow_protobuf.sh \
        $ROOT_DIR/tensorflow-protobuf $DEPLOY_TARGET_x86_64
    cd $ROOT_DIR && color_print -s "finished!"
}

pre_process_armnn_sdk(){
    hint compile_install_armnn_sdk
    cd "$ROOT_DIR" && smart_clone https://source.codeaurora.org/external/imx/armnn-imx
    # gen_tf_protobuf
    [ ! -d armnn-imx ] && color_print -e "$ROOT_DIR/armnn-imx not found?" && return 1
    cd armnn-imx && git checkout branches/armnn_19_08 && [ $? -ne 0 ] && return 1
    # cd armnn-imx && git checkout branches/armnn_20_08    #! 目前的 default
    [ ! -d build ] && mkdir build
    return 0
}

post_process_armnn_sdk(){
    cd "$ROOT_DIR/armnn-imx/build"
    make -j$(cpu_cores) && [ $? -ne 0 ] && exit 1
    tar --use-compress-program=pigz \
        --exclude='*.o' \
        --exclude='*.os' \
        --exclude='*.cmake' \
        --exclude='CMake*' \
        --exclude='Makefile' \
        --exclude='samples' \
        --exclude='src' \
        -cvf armnn-imx_release_${ver}.tar.gz *
    make install && [ $? -ne 0 ] && exit 1
    cp -f "$DEPLOY_TARGET"/arm64/lib/libprotobuf.so.* ./
    cat << EOF > "$ROOT_DIR/armnn-imx/build/unit_test.sh"
#!/bin/sh
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$ROOT_DIR/armnn-imx/build
printf "[INFO] Please check the LD_LIBRARY_PATH=%s\\n" "\$LD_LIBRARY_PATH"
printf "[WARN] !! MAKE SURE your CURRENT working directory is: $ROOT_DIR/armnn-imx/build !!\\n"
printf "[INFO] Press any key to continue...\\n"
read aha
./UnitTests
EOF
    chmod +x "$ROOT_DIR/armnn-imx/build/unit_test.sh"
}

compile_install_armnn_sdk_local(){

    pre_process_armnn_sdk && cd "$ROOT_DIR/armnn-imx/build"

    # Use CMake to configure build environment

    # SDKTARGETSYSROOT=${BSP_LOCATE}/sysroots/aarch64-poky-linux
    # OECORE_NATIVE_SYSROOT=${BSP_LOCATE}/sysroots/x86_64-pokysdk-linux
    # CXX="$OECORE_NATIVE_SYSROOT/usr/bin/aarch64-poky-linux/aarch64-poky-linux-g++  -fstack-protector-strong  -D_FORTIFY_SOURCE=2 -Wformat -Wformat-security -Werror=format-security --sysroot=$SDKTARGETSYSROOT" \
    # CC="$OECORE_NATIVE_SYSROOT/usr/bin/aarch64-poky-linux/aarch64-poky-linux-gcc  -fstack-protector-strong  -D_FORTIFY_SOURCE=2 -Wformat -Wformat-security -Werror=format-security --sysroot=$SDKTARGETSYSROOT" \

    [ ! -f "$BSP_LOCATE/environment-setup-aarch64-poky-linux" ] &&
        color_print -e "cross compile enviroment $BSP_LOCATE not found?" && exit 1
    . "$BSP_LOCATE/environment-setup-aarch64-poky-linux"

    # TODO No rule to make target '${BSP_LOCATE}/sysroots/aarch64-poky-linux/usr/lib/libboost_system.a', needed by 'libarmnn.so.21.0'.  Stop.
    #! 巨坑 bug，用 -DBoost_ROOT 提示拼写错误要求用 -DBOOST_ROOT
    #! 用了 -DBOOST_ROOT，Debug 输出显示已经接收，但是却不用这个变量，然后找不到 boost 库
    #! 最后必须指定 -DBoost_INCLUDE_DIR -DBoost_LIBRARY_DIR 可以正常编译，
    #! 而使用 -DBOOST_INCLUDEDIR 和 -DBOOST_LIBRARYDIR 也不行…
    cmake .. \
        -DCMAKE_TOOLCHAIN_FILE=$OECORE_NATIVE_SYSROOT/usr/share/cmake/OEToolchainConfig.cmake \
        -DARMCOMPUTE_ROOT=$ROOT_DIR/arm-computelibrary-imx \
        -DARMCOMPUTE_BUILD_DIR=/build \
        -DARMCOMPUTENEON=1 -DARMCOMPUTECL=0 -DARMNNREF=1 \
        -DVSI_NPU=1 -DBUILD_VSI_TESTS=1 \
        -DBoost_DEBUG=1 \
        -DBUILD_TESTS=1 \
        -DBOOST_ROOT=$DEPLOY_TARGET_arm64 \
        -DBoost_INCLUDE_DIR=$DEPLOY_TARGET_arm64/include \
        -DBoost_LIBRARY_DIR=$DEPLOY_TARGET_arm64/lib \
        -DPROTOBUF_ROOT=$DEPLOY_TARGET_arm64 \
        -DPROTOBUF_LIBRARY_DEBUG=$DEPLOY_TARGET_arm64/lib/libprotobuf.so.15.0.1 \
        -DPROTOBUF_LIBRARY_RELEASE=$DEPLOY_TARGET_arm64/lib/libprotobuf.so.15.0.1 \
        -DGENERIC_LIB_VERSION="19.08" && post_process_armnn_sdk
        # -DBUILD_SHARED_LIBS=ON -DREGISTER_INSTALL_PREFIX=OFF \
        # -DARMCOMPUTE_INCLUDE=$ROOT_DIR/arm-computelibrary-imx \
        # -DHALF_INCLUDE=$ROOT_DIR/arm-computelibrary-imx/include \
        # -DTHIRD_PARTY_INCLUDE_DIRS=${STAGING_DIR_HOST}${includedir} \
        #
        # 备选参数：
        #
        # -DBoost_USE_STATIC_LIBS=ON \
        # -DBoost_USE_STATIC_RUNTIME=ON \
        # -DCMAKE_INSTALL_PREFIX:PATH=$DEPLOY_TARGET_arm64 \
        # -DCAFFE_GENERATED_SOURCES=$ROOT_DIR/caffe/build/src/ \
        # -DBUILD_CAFFE_PARSER=1 \
        # -DONNX_GENERATED_SOURCES=$ROOT_DIR/onnx/ \
        # -DBUILD_ONNX_PARSER=1 \
        # -DTF_GENERATED_SOURCES=$ROOT_DIR/tensorflow-protobuf \
        # -DTF_LITE_SCHEMA_INCLUDE_PATH=$ROOT_DIR/tflite \
        # -DBUILD_TF_PARSER=1 -DBUILD_TF_LITE_PARSER=1 \
        # -DTF_LITE_GENERATED_PATH=$ROOT_DIR/tflite/ \
        # -DDYNAMIC_BACKEND_PATHS=$SAMPLE_DYNAMIC_BACKEND_PATH \
        # -DFLATBUFFERS_ROOT=$DEPLOY_TARGET_arm64/ \
        # -DFLATC_DIR=$ROOT_DIR/flatbuffers-1.12.0/build_x86_64 \
        # -DPROTOBUF_ROOT=$DEPLOY_TARGET_x86_64
        # -DSAMPLE_DYNAMIC_BACKEND=1 \
        # -DDYNAMIC_BACKEND_PATHS=$SAMPLE_DYNAMIC_BACKEND_PATH
        #
        # If you want to include standalone sample dynamic backend tests,
        # add the argument to enable the tests and the dynamic backend path to the CMake 上两行
}

compile_dyn_sample(){
    hint compile_dyn_sample
    # The sample dynamic backend is located in:
    cd $ROOT_DIR/armnn/src/dynamic/sample
    mkdir build

    # run it from the armnn/src/dynamic/sample/build directory to set up the armNN build:
    # SDKTARGETSYSROOT=${BSP_LOCATE}/sysroots/aarch64-poky-linux
    # OECORE_NATIVE_SYSROOT=${BSP_LOCATE}/sysroots/x86_64-pokysdk-linux

    cd build
    # CXX="$OECORE_NATIVE_SYSROOT/usr/bin/aarch64-poky-linux/aarch64-poky-linux-g++  -fstack-protector-strong  -D_FORTIFY_SOURCE=2 -Wformat -Wformat-security -Werror=format-security --sysroot=$SDKTARGETSYSROOT" \
    # CC="$OECORE_NATIVE_SYSROOT/usr/bin/aarch64-poky-linux/aarch64-poky-linux-gcc  -fstack-protector-strong  -D_FORTIFY_SOURCE=2 -Wformat -Wformat-security -Werror=format-security --sysroot=$SDKTARGETSYSROOT" \
        [ ! -f ${BSP_LOCATE}/environment-setup-aarch64-poky-linux ] &&
        color_print -e "cross compile enviroment ${BSP_LOCATE} not found?" &&
        exit 1
    . ${BSP_LOCATE}/environment-setup-aarch64-poky-linux
    cmake .. \
        -DCMAKE_CXX_FLAGS=--std=c++14 \
        -DBUILD_SHARED_LIBS=OFF \
        -DBOOST_ROOT=$DEPLOY_TARGET_arm64/ \
        -DBoost_SYSTEM_LIBRARY=$DEPLOY_TARGET_arm64/lib/libboost_system.a \
        -DARMNN_PATH=$DEPLOY_TARGET_arm64/lib/libarmnn.so
    make -j$(cpu_cores)
}

run_unit_test(){
    # Run Unit Tests，该步骤需要在目标机器上进行
    cd $ROOT_DIR/armnn/
    # !Setps!
    # 相当于把 SDK 都弄到测试平台上（包括 UnitTests 二进制文件），
    # 然后设置 LD_LIBRARY_PATH 为 sdk 的 so 文件所在目录
    # link 和运行 UnitTests
    # 1. Copy the build folder to an arm64 linux machine
    # 2. Copy the libprotobuf.so.15.0.1 library file to the build folder
    # If you enable the standalone sample dynamic tests, also copy
    # libArm_SampleDynamic_backend.so library file to the folder specified as
    # $SAMPLE_DYNAMIC_BACKEND_PATH when you build ArmNN
    # 1. cd to the build folder on your arm64 machine and set your LD_LIBRARY_PATH to its current location:
    export LD_LIBRARY_PATH=`pwd`

    # Cr2eate a symbolic link to libprotobuf.so.15.0.1:
    ln -s libprotobuf.so.15.0.1 ./libprotobuf.so.15

    # Run the UnitTests:
    ./UnitTests
    cd $ROOT_DIR && color_print -s "finished!"
}

# -----------------------------------------------------------------------------
if [ $MANUAL_DEP = n ]; then
  if command -v apt 2>&1 >/dev/null; then
    export DEBIAN_FRONTEND=noninteractive
    color_print -i auto update...
    sudo add-apt-repository --yes --update ppa:dns/gnu &&
    sudo add-apt-repository --yes --update ppa:git-core/ppa &&
    sudo add-apt-repository --yes --update ppa:ansible/ansible &&
    sudo apt-get update &&
      sudo apt-get -y install python3 python3-pip python3-setuptools python3-wheel \
        apt-transport-https ca-certificates
    if [ $APT_SMART = y ]; then
      color_print -i pip3 install --user apt-smart --upgrade
      color_print -w will config sources.list by apt-smart $(command -v apt)
      python3 -m pip install --user --upgrade pip &&
      python3 -m pip install --user --upgrade apt-smart &&
      python3 -m pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple &&
      apt-smart --auto-change-mirror --update
      # apt-smart -au
    fi

    color_print -i $(command -v apt) install dependency...
    sudo apt-get -y upgrade &&
      sudo apt-get -y install curl autoconf libtool build-essential g++ scons
    sudo apt-get -y autoremove
  else
    color_print -w apt not found, dependency should be resolved manually
  fi
else
  color_print -w manually dependency selected
fi

# -----------------------------------------------------------------------------
compile_install_protobuf_x86_64
compile_install_protobuf_arm64      #! 可以被包含在 BSP 中？
compile_install_boost_arm64         #! 可以被包含在 BSP 中？
compile_compute_lib_arm64           #! 可以被包含在 BSP 中？
compile_install_armnn_sdk_local     # 使用自编译库
# gen_tf_protobuf                     # 需要 Tensorflow 源码中的一些东西
# compile_install_flatbuffer_x86_64   #! 可以被包含在 BSP 中？
# compile_install_flatbuffer_arm64    #! 可以被包含在 BSP 中？
# compile_caffe_x86_64                #! 可以被包含在 BSP 中？
# prepare_onnx                        # 准备好 ONNX 的源码
# prepare_tflite                      # 准备好 TFLite 的源码
# compile_dyn_sample                  #

# tar --use-compress-program=pigz -czvf armnn_lib.tar.gz $DEPLOY_TARGET_arm64/*
