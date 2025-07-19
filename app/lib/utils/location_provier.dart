import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;

  Position? get currentPosition => _currentPosition;

  final _positionController =
      StreamController<LocationMarkerPosition>.broadcast();

  Stream<LocationMarkerPosition> get positionStream =>
      _positionController.stream;

  LocationProvider() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      final markerPos = LocationMarkerPosition(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
      _positionController.add(markerPos);
      _currentPosition = position;
      notifyListeners();
    });
  }

  Future<void> fetchCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      notifyListeners();
    } catch (e) {
      print("定位失败: $e");
    }
  }
}
