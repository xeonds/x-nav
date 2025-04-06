import 'package:app/page/history.dart';
import 'package:app/page/home.dart';
import 'package:app/page/map.dart';
import 'package:app/page/routes.dart';
import 'package:app/page/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'package:app/utils/data_loader.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => DataLoader()..initialize(), // 初始化 DataLoader
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'X-Nav',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.red, brightness: Brightness.dark),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      themeMode:
          ThemeMode.system, // Automatically switch based on system settings
      home: const AppMainPages(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppMainPages extends StatefulWidget {
  const AppMainPages({super.key});

  @override
  State<AppMainPages> createState() => _AppMainPagesState();
}

class _AppMainPagesState extends State<AppMainPages> {
  int _selectedIndex = 0;
  bool _isFullScreen = false;
  final List<int> _supportFullScreenPages = <int>[1, 2];
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      HomePage(),
      MapPage(
        onFullScreenToggle: _toggleFullScreen,
      ),
      RoutesPage(
        onFullScreenToggle: _toggleFullScreen,
      ),
      RideHistory(),
      UserPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isFullScreen = false;
    });
  }

  void _toggleFullScreen(bool isFullScreen) {
    setState(() {
      if (_supportFullScreenPages.contains(_selectedIndex)) {
        _isFullScreen = isFullScreen;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: _isFullScreen
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              backgroundColor: Theme.of(context).colorScheme.surfaceBright,
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map),
                  label: 'Map',
                ),
                NavigationDestination(
                  icon: Icon(Icons.directions),
                  label: 'Routes',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person),
                  label: 'Me',
                ),
              ],
            ),
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
