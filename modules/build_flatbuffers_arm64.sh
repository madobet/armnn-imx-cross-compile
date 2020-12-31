. "$ROOT_DIR/modules/functions.sh" && cd "$ROOT_DIR"

[ ! -d flatbuffer-1.12.0 ] && tar -xvf flatbuffers-1.12.0.tar.gz
cd flatbuffers-1.12.0
[ ! -d build_arm64 ] && mkdir build_arm64
cd build_arm64

[ ! -f "$BSP_LOCATE/environment-setup-aarch64-poky-linux" ] &&
    color_print -e "cross compile enviroment $BSP_LOCATE not found?" && exit 1
. "$BSP_LOCATE/environment-setup-aarch64-poky-linux"

# Add -fPIC to allow us to use the libraries in shared objects.
CXXFLAGS=${CXXFLAGS:+$CXXFLAGS "-fPIC"} \
cmake .. -DCMAKE_INSTALL_PREFIX:PATH=$DEPLOY_TARGET_arm64 \
         -DCMAKE_C_COMPILER=aarch64-poky-linux-gcc \
         -DCMAKE_CXX_COMPILER=aarch64-poky-linux-g++ \
         -DFLATBUFFERS_BUILD_FLATC=1 \
         -DFLATBUFFERS_BUILD_TESTS=0
make all -j$(grep -c "^processor" "/proc/cpuinfo") &&
make install && [ $? -ne 0 ] && exit 1

cd "$ROOT_DIR"
