import 'package:flutter/material.dart';
import 'dart:async';
// import 'package:wakelock/wakelock.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class TachometerPage extends StatefulWidget {
  const TachometerPage({Key? key}) : super(key: key);

  @override
  _TachometerPageState createState() => _TachometerPageState();
}

class _TachometerPageState extends State<TachometerPage> {
  double _speed = 0.0;
  double _distance = 0.0;
  Duration _elapsed = Duration.zero;
  LatLng _current = LatLng(0, 0);
  String _navInstruction = '';
  bool _locked = false;
  late Timer _timer;
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    // Wakelock.enable();
    _mapController = MapController();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        _elapsed += Duration(seconds: 1);
        // TODO: 更新 speed, distance, current, navInstruction
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    // Wakelock.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AbsorbPointer(
        absorbing: _locked,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMetric('速度', '${_speed.toStringAsFixed(1)} km/h'),
                    _buildMetric(
                        '里程', '${(_distance / 1000).toStringAsFixed(2)} km'),
                    _buildMetric('时间',
                        '${_elapsed.inMinutes.toString().padLeft(2, '0')}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}'),
                  ],
                ),
              ),
              // Container(
              //   height: 150,
              //   margin: EdgeInsets.symmetric(horizontal: 16),
              //   child: FlutterMap(
              //     mapController: _mapController,
              //     options: MapOptions(center: _current, zoom: 15),
              //     layers: [
              //       TileLayerOptions(
              //           urlTemplate:
              //               'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              //       MarkerLayerOptions(markers: [
              //         Marker(
              //             point: _current,
              //             width: 10,
              //             height: 10,
              //             builder: (_) => Container(color: Colors.red))
              //       ]),
              //     ],
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _navInstruction,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => _locked = !_locked),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800]),
                    child: Text(_locked ? '解锁' : '锁定'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text('结束骑行'),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white70)),
      ],
    );
  }
}
