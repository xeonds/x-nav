# X-NAV

一个开源码表系统+硬件设计

## 功能

- 运动记录
    - 路径，传感器数据，时间，图像，...
- 路径导航
    - 路径显示，转向提醒
    - 地图显示
- 设备控制
    - 通过蓝牙控制其他设备
- 记录管理
    - 记录删除，USB/WiFi/蓝牙文件传输

## TODO
- 软件
    - UI
        - 仪表盘界面
        - 导航界面
        - 记录管理界面
        - 蓝牙控制界面
    - 服务
        - fit文件读写
            - 文件系统
        - 蓝牙广播/数据传输/设备连接/控制
        - gps搜索/读取数据
        - 传感器读取
        - 电池状态读取
        - 地图文件读取/显示
- 硬件设计
    - 屏幕
    - 供电
    - 传感器
    - 按键
- web
    - gpx/fit/...->json+逆向转换
    - 热力地图
    - 视频叠加层生成 
    - 数据分析
        - 功率估算
