import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Control App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'BLE Control'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? writeCharacteristic;
  BluetoothCharacteristic? notifyCharacteristic;
  bool isDeviceOn = false;
  Timer? statusTimer;

  @override
  void initState() {
    super.initState();
    startScan();
  }

  void startScan() {
    setState(() {
      scanResults.clear();
      isScanning = true;
    });
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });
    FlutterBluePlus.isScanning.listen((isScanning) {
      setState(() {
        this.isScanning = isScanning;
      });
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    await device.connect();
    setState(() {
      connectedDevice = device;
    });
    discoverServices();
  }

  void discoverServices() async {
    if (connectedDevice == null) return;
    List<BluetoothService> services = await connectedDevice!.discoverServices();
    services.forEach((service) {
      if (service.uuid.toString() == '4fafc201-1fb5-459e-8fcc-c5c9c331914b') {
        service.characteristics.forEach((characteristic) {
          if (characteristic.uuid.toString() ==
              'beb5483e-36e1-4688-b7f5-ea07361b26a8') {
            writeCharacteristic = characteristic;
          }
          if (characteristic.uuid.toString() ==
              '1c95d5e3-d8cc-4a95-a4d9-3f063ef07d49') {
            notifyCharacteristic = characteristic;
            setupNotifications();
          }
        });
      }
    });
    startStatusTimer();
  }

  void setupNotifications() {
    notifyCharacteristic?.setNotifyValue(true);
    notifyCharacteristic?.lastValueStream.listen((value) {
      if (value.isNotEmpty) {
        setState(() {
          isDeviceOn = value[0] == 1;
        });
      }
    });
  }

  void startStatusTimer() {
    statusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (writeCharacteristic != null) {
        writeCharacteristic!.write([0x02]);
      }
    });
  }

  void toggleDevice() {
    if (writeCharacteristic != null) {
      writeCharacteristic!.write([isDeviceOn ? 0x00 : 0x01]);
    }
  }

  @override
  void dispose() {
    statusTimer?.cancel();
    super.dispose();
  }

  Widget buildDeviceList() {
    if (scanResults.isEmpty) {
      return isScanning
          ? const CircularProgressIndicator()
          : const Text('No devices found');
    }
    return ListView.builder(
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(scanResults[index].device.platformName.isEmpty
              ? "Unknown device"
              : scanResults[index].device.platformName),
          subtitle: Text(scanResults[index].device.remoteId.toString()),
          onTap: () => connectToDevice(scanResults[index].device),
        );
      },
      itemCount: scanResults.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: connectedDevice == null
            ? buildDeviceList()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Connected to: ${connectedDevice!.platformName}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Device is ${isDeviceOn ? 'ON' : 'OFF'}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: toggleDevice,
                    child: Text(isDeviceOn ? 'Turn OFF' : 'Turn ON'),
                  ),
                ],
              ),
      ),
      floatingActionButton: connectedDevice == null
          ? FloatingActionButton(
              onPressed: startScan,
              child: Icon(isScanning ? Icons.stop : Icons.search),
            )
          : null,
    );
  }
}
