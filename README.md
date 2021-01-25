# Development Enviroment for armnn-imx with i.MX BSP

用于使用 i.MX BSP 编译 https://source.codeaurora.org/external/imx/armnn-imx

## Usage

运行
```shell
# 最简单的用法，编译结果位于 <repo directory>/build
./build.sh

# 全部参数都用上
# BSP_LOCATE=<your BSP installation directory> \
# DEPLOY_TARGET=<your ARMNN SDK installation directory> \
# ROOT_DIR=$PWD \
# MANUAL_DEP=n \
# APT_SMART=n ./build.sh
```

> **Note**
>
> 必须先安装 i.MX BSP！
>
> You should have had an i.MX BSP installed on your machine!

Tested on Ubuntu 18.04

## TODO
1. 自动下载 opencv_extra 的东西
2. 怎么处理 tests_imx 的庞大数据
3. ML 实例添加
