. "$ROOT_DIR/modules/functions.sh" && cd "$ROOT_DIR"

if [ ! -d protobuf ]; then
    # git clone -b v3.5.2 https://github.com/google/protobuf.git protobuf &&
    git clone -b v3.5.1 https://github.com/google/protobuf.git protobuf &&
    git submodule update --init --recursive
    cd protobuf && ./autogen.sh
else
    cd protobuf
fi

# requires cUrl, autoconf, llibtool, and other build dependencies
[ ! -d build_arm64 ] && mkdir build_arm64
cd build_arm64

[ ! -f "$BSP_LOCATE/environment-setup-aarch64-poky-linux" ] &&
    color_print -e "cross compile enviroment $BSP_LOCATE not found?" && exit 1
. "$BSP_LOCATE/environment-setup-aarch64-poky-linux"

../configure --host=aarch64-linux \
    --prefix=$DEPLOY_TARGET_arm64 \
    --with-protoc=$DEPLOY_TARGET_x86_64/bin/protoc
make install -j$(grep -c "^processor" "/proc/cpuinfo") && [ $? -ne 0 ] && exit 1

cd "$ROOT_DIR"
