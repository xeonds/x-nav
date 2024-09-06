import bluetooth
import machine
import time

# BLE相关定义
ble = bluetooth.BLE()
ble.active(True)

# 定义服务和特征UUID
SERVICE_UUID = bluetooth.UUID('4fafc201-1fb5-459e-8fcc-c5c9c331914b')
WRITE_CHAR_UUID = bluetooth.UUID('beb5483e-36e1-4688-b7f5-ea07361b26a8')
NOTIFY_CHAR_UUID = bluetooth.UUID('1c95d5e3-d8cc-4a95-a4d9-3f063ef07d49')

# 控制的GPIO引脚
control_pin = machine.Pin(2, machine.Pin.OUT)

# BLE连接标志
connected = False

# 处理BLE事件的回调函数
def ble_irq(event, data):
    global connected
    if event == 1:  # 连接事件
        connected = True
        print("BLE Connected")
    elif event == 2:  # 断开连接事件
        connected = False
        print("BLE Disconnected")
        ble.gap_advertise(100, adv_data)
    elif event == 3:  # 收到写入请求
        buffer = ble.gatts_read(write_handle)
        if buffer[0] == 0x00:
            control_pin.value(0)
        elif buffer[0] == 0x01:
            control_pin.value(1)
        elif buffer[0] == 0x02:
            notify_status()

# 通知客户端当前状态
def notify_status():
    ble.gatts_notify(0, notify_handle, bytes([control_pin.value()]))

# 设置BLE服务
ble.irq(ble_irq)
((write_handle, notify_handle),) = ble.gatts_register_services(((SERVICE_UUID, ((WRITE_CHAR_UUID, bluetooth.FLAG_WRITE), (NOTIFY_CHAR_UUID, bluetooth.FLAG_NOTIFY))),))

# 设置广播数据
name = "ESP32-BLE"
adv_data = bytes('\x02\x01\x02') + bytes((len(name) + 1, 0x09)) + name.encode('UTF-8')
ble.gap_advertise(100, adv_data)
print("Started BLE advertising")

while True:
    if connected:
        notify_status()
    time.sleep(1)