# Development Enviroment for armnn-imx with i.MX BSP

用于使用 i.MX BSP 编译 https://source.codeaurora.org/external/imx/armnn-imx

## Usage

运行
```shell
# 用例，编译结果位于 <repo directory>/build
./build_local.sh    # 必要依赖都通过源码编译
# ./build_bsp.sh    # 使用 BSP 中的依赖进行编译（BSP 中必须包含必要的文件）

# 部分可选项
# BSP_LOCATE=<your BSP installation directory>
# ROOT_DIR=$PWD
# MANUAL_DEP=n
# APT_SMART=n ./build.sh
```

> **Note**
>
> 必须先安装 i.MX BSP！
>
> There should be at least one i.MX BSP installed on your machine!

Tested on Ubuntu 18.04

## TODO
1. 自动下载 opencv_extra 的东西
2. 怎么处理 tests_imx 的庞大数据
3. ML 实例添加
