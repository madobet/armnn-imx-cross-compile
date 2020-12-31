# 防止 . /opt/fsl-imx-xwayland/5.4-zeus/environment-setup-aarch64-poky-linux
# 污染环境，单独分离脚本
. "$ROOT_DIR/modules/functions.sh" && cd "$ROOT_DIR"

if [ ! -d boost_1_64_0 ]; then
    if [ ! -f boost_1_64_0.tar.bz2 ]; then
        color_print -w downloading boost_1_64_0.tar.bz2...
        wget -O boost_1_64_0.tar.bz2 \
            https://dl.bintray.com/boostorg/release/1.64.0/source/boost_1_64_0.tar.bz2
        [ $? -ne 0 ] &&
            color_print -e boost_1_64_0.tar.bz2 download failed &&
            return 1
    fi
    color_print -i unarchiving boost_1_64_0.tar.bz2...
    tar -xjf boost_1_64_0.tar.bz2
fi
cd boost_1_64_0

[ ! -f "$BSP_LOCATE/environment-setup-aarch64-poky-linux" ] &&
    color_print -e "cross compile enviroment $BSP_LOCATE not found?" && exit 1
. "$BSP_LOCATE/environment-setup-aarch64-poky-linux"

# echo "using gcc : arm : aarch64-linux-gnu-g++ ;" > user_config.jam
echo "using gcc : arm : aarch64-poky-linux-g++ --sysroot=$BSP_LOCATE/sysroots/aarch64-poky-linux ;" > user_config.jam
# echo "using gcc : arm : $CXX ;" > user_config.jam

# ./b2 install toolset=gcc-arm link=static threading=multi cxxflags="-fPIC $CXXFLAGS"
./bootstrap.sh --prefix=$DEPLOY_TARGET_arm64 &&
./b2 install toolset=gcc-arm link=static cxxflags=-fPIC \
    --with-filesystem --with-test --with-log \
    --with-program_options -j$(grep -c "^processor" "/proc/cpuinfo") \
    --user-config=user_config.jam && [ $? -ne 0 ] && exit 1

cd "$ROOT_DIR"
