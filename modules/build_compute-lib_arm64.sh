# TODO apt install scons
. "$ROOT_DIR/modules/functions.sh" && cd "$ROOT_DIR" &&
    smart_clone https://source.codeaurora.org/external/imx/arm-computelibrary-imx
cd arm-computelibrary-imx
# git checkout master
git checkout imx_19.08

[ ! -f "$BSP_LOCATE/environment-setup-aarch64-poky-linux" ] &&
    color_print -e "cross compile enviroment $BSP_LOCATE not found?" && exit 1
. "$BSP_LOCATE/environment-setup-aarch64-poky-linux"

scons install_dir=$DEPLOY_TARGET_arm64 \
    Werror=0 -j$(grep -c "^processor" "/proc/cpuinfo") \
    neon=1 opencl=1 os=linux arch=arm64-v8a \
    build=cross_compile embed_kernels=1 cppthreads=1 \
    mali=0 gles_compute=0 extra_cxx_flags="-fPIC" && [ $? -ne 0 ] && exit 1
    # benchmark_tests=1 validation_tests=1 internal_only=0

cd "$ROOT_DIR"
