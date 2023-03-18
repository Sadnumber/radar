# ADC/UART data capturing using xWR1843/AWR2243 with DCA1000

capture both raw ADC IQ data and processed UART point cloud data simultaneously in pure python code (with a little C code)


## Introduction

该模块分为两部分，mmwave和fpga_udp。
1.  mmwave修改自[OpenRadar](https://github.com/PreSenseRadar/OpenRadar)，用于配置文件读取、串口数据发送与接收、原始数据解析等。
2.  fpga_udp修改自[pybind11 example](https://github.com/pybind/python_example)以及[mmWave-DFP-2G](https://www.ti.com/tool/MMWAVE-DFP)，用于通过C语言编写的socket代码从网口接收DCA1000发回的高速的原始数据。对于AWR2243这种没有片上DSP及ARM核的型号，还实现了利用FTDI通过USB发送指令用SPI控制AWR2243的固件写入、参数配置等操作。


## Prerequisites

### Hardware
#### for xWR1843
* Connect the micro-USB port (UART) on the xWR1843 to your system
* Connect the xWR1843 to a 5V barrel jack
* Set power connector on the DCA1000 to RADAR_5V_IN
* boot in Functional Mode: SOP[2:0]=001
  * either place jumpers on pins marked as SOP0 or toggle SOP0 switches to ON, all others remain OFF
* Connect the RJ45 to your system
* Set a fixed IP to the local interface: 192.168.33.30
#### for AWR2243
* Connect the micro-USB port (FTDI) on the DCA1000 to your system
* Connect the AWR2243 to a 5V barrel jack
* Set power connector on the DCA1000 to RADAR_5V_IN
* Put the device in SOP0
  * Jumper on SOP0, all others disconnected
* Connect the RJ45 to your system
* Set a fixed IP to the local interface: 192.168.33.30

### Software
#### Windows
 - Microsoft Visual C++ 14.0 or greater is required. Get it with "[Microsoft C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/)" and choose "Desktop development with C++"
 - FTDI D2XX driver and DLL is needed. Download version [2.12.36.4](https://www.ftdichip.com/Drivers/CDM/CDM%20v2.12.36.4%20WHQL%20Certified.zip) or newer from [official website](https://ftdichip.com/drivers/d2xx-drivers/) and install `ftdibus.inf`.
#### Linux
 - `sudo apt install python3-dev`
 - FTDI D2XX driver and .so lib is needed. Download version 1.4.27 or newer from [official website](https://ftdichip.com/drivers/d2xx-drivers/) based on your architecture. e.g. [X86](https://ftdichip.com/wp-content/uploads/2022/07/libftd2xx-x86_32-1.4.27.tgz), [X64](https://ftdichip.com/wp-content/uploads/2022/07/libftd2xx-x86_64-1.4.27.tgz), [armv7](https://ftdichip.com/wp-content/uploads/2022/07/libftd2xx-arm-v7-hf-1.4.27.tgz), [aarch64](https://ftdichip.com/wp-content/uploads/2022/07/libftd2xx-arm-v8-1.4.27.tgz), etc.
 - Then you'll need to install the library:
  - ```
    tar -xzvf libftd2xx-arm-v8-1.4.27.tgz
    cd libftd2xx-arm-v8-1.4.27/release
    sudo cp ftd2xx.h /usr/local/include
    sudo cp WinTypes.h /usr/local/include
    cd build
    sudo cp libftd2xx.so.1.4.27 /usr/local/lib
    sudo chmod 0755 /usr/local/lib/libftd2xx.so.1.4.27
    sudo ln -sf /usr/local/lib/libftd2xx.so.1.4.27 /usr/local/lib/libftd2xx.so
    sudo ldconfig -v
    ```


## Installation

 - clone this repository
 - `python3 -m pip install --upgrade pip`
 - `python3 -m pip install --upgrade setuptools`
 - `pip install ./fpga_udp`


## Example

### ***captureAll.py***
同时采集原始ADC采样的IQ数据及片内DSP预处理好的点云等串口数据的示例代码（仅xWR1843）。
#### 1.采集原始数据的一般流程
 1.  (optional)创建从串口接收片内DSP处理好的数据的进程
 2.  通过串口启动雷达（理论上通过网口也能控制，暂未实现）
 3.  通过网口udp发送配置fpga指令
 4.  通过网口udp发送配置record数据包指令
 5.  (optional)启动串口接收进程（只进行缓存清零）
 6.  通过网口udp发送开始采集指令
 7.  实时数据流处理或离线采集保存
 8.  通过网口udp发送停止采集指令
 9.  通过串口关闭雷达 或 通过网口发送重置雷达命令
 10.  (optional)停止接收串口数据
 11.  (optional)解析从串口接收的点云等片内DSP处理好的数据
#### 2."*.cfg"毫米波雷达配置文件要求
 - Default profile in Visualizer disables the LVDS streaming.
 - To enable it, please export the chosen profile and set the appropriate enable bits.
 - adcbufCfg需如下设置，lvdsStreamCfg的第三个参数需设置为1，具体参见mmwave_sdk_user_guide.pdf
    - adcbufCfg -1 0 1 1 1
    - lvdsStreamCfg -1 0 1 0 
#### 3."cf.json"数据采集卡配置文件要求
 - In default conditions, Ethernet throughput varies up to 325 Mbps speed in a 25-µs Ethernet packet delay. 
 - The user can change the Ethernet packet delay from 5 µs to 500 µs to achieve different throughputs.
    - "packetDelay_us":  5 (us)   ~   706 (Mbps)
    - "packetDelay_us": 10 (us)   ~   545 (Mbps)
    - "packetDelay_us": 25 (us)   ~   325 (Mbps)
    - "packetDelay_us": 50 (us)   ~   193 (Mbps)

### ***captureADC_AWR2243.py***
采集原始ADC采样的IQ数据的示例代码（仅AWR2243）。
#### 1.AWR2243采集原始数据的一般流程
 1. 重置雷达与DCA1000(reset_radar、reset_fpga)
 2. 通过SPI初始化雷达并配置相应参数(AWR2243_init、AWR2243_setFrameCfg)(linux下需要root权限)
 3. 通过网口udp发送配置fpga指令(config_fpga)
 4. 通过网口udp发送配置record数据包指令(config_record)
 5. 通过网口udp发送开始采集指令(stream_start)
 6. 通过SPI启动雷达(AWR2243_sensorStart)
 7. 实时处理数据流或离线采集保存(write_frames_to_file)
 8. (optional, 若numFrame==0则不能有)等待雷达采集结束(AWR2243_waitSensorStop)
 9. (optional, 若numFrame==0则必须有)通过网口udp发送停止采集指令(stream_stop)
 10. (optional, 若numFrame==0则必须有)通过SPI停止雷达(AWR2243_sensorStop)
 11. 通过SPI关闭雷达电源与配置文件(AWR2243_poweroff)
#### 2."mmwaveconfig.txt"毫米波雷达配置文件要求
 - TBD
#### 3."cf.json"数据采集卡配置文件要求
 - In default conditions, Ethernet throughput varies up to 325 Mbps speed in a 25-µs Ethernet packet delay. 
 - The user can change the Ethernet packet delay from 5 µs to 500 µs to achieve different throughputs.
    - "packetDelay_us":  5 (us)   ~   706 (Mbps)
    - "packetDelay_us": 10 (us)   ~   545 (Mbps)
    - "packetDelay_us": 25 (us)   ~   325 (Mbps)
    - "packetDelay_us": 50 (us)   ~   193 (Mbps)

### ***testDecode.ipynb***
解析原始ADC采样数据及串口数据（仅IWR1843）的示例代码，需要用Jupyter(推荐VS Code安装Jupyter插件)打开。
#### 1.解析LVDS接收的ADC原始IQ数据
##### 利用numpy对LVDS接收的ADC原始IQ数据进行解析
 - 载入相关库
 - 设置对应参数
 - 载入保存的bin数据并解析
 - 绘制时域IQ波形
 - 计算Range-FFT
 - 计算Doppler-FFT
 - 计算Azimuth-FFT
##### 利用mmwave.dsp提供的函数对LVDS接收的ADC原始IQ数据进行解析
#### 2.解析UART接收的片内DSP处理过的点云、doppler等数据
 - 载入相关库
 - 载入保存的串口解析数据
 - 显示cfg文件设置的数据
 - 显示片内处理时间(可用来判断是否需要调整帧率)
 - 显示各天线温度
 - 显示数据包信息
 - 显示点云数据
 - 计算距离标签及多普勒速度标签
 - 显示range profile及noise floor profile
 - 显示多普勒图Doppler Bins
 - 显示方位角图Azimuth (Angle) Bins

### ***testParam.ipynb***
IWR1843毫米波雷达配置参数合理性校验，需要用Jupyter(推荐VS Code安装Jupyter插件)打开。
 - 主要校验毫米波雷达需要的cfg文件及DCA采集板需要的cf.json文件的参数配置是否正确。
 - 参数的约束条件来自于IWR1843自身的器件特性，具体请参考IWR1843数据手册、mmwave SDK用户手册、chirp编程手册。
 - 若参数满足约束条件将以青色输出调试信息，若不满足则以紫色或黄色输出。
 - 需要注意的是，本程序约束条件并非完全准确，故特殊情况下即使参数全都满足约束条件，也有概率无法正常运行。

### ***testParam_AWR2243.ipynb***
AWR2243毫米波雷达配置参数合理性校验。

### ***testDecodeADCdata.mlx***
解析原始ADC采样数据的MATLAB示例代码
 - 设置对应参数
 - 载入保存的bin原始ADC数据
 - 根据参数解析重构数据格式
 - 绘制时域IQ波形
 - 计算Range-FFT(一维FFT+静态杂波滤除)
 - 计算Doppler-FFT
 - 1D-CA-CFAR Detector on Range-FFT
 - 计算Azimuth-FFT


## Software Architecture

### TBD.py
TBD


## Environmental Requirements

1.  TBD


## Instructions for Use

1.  先按照要求搭建运行环境，未提及的模块在运行时若报错请自己查询添加
2.  TBD