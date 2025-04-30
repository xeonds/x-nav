import 'package:flutter/material.dart';

class RideStatsCard extends StatelessWidget {
  final int totalRides;
  final double totalTime; // 单位：秒
  final double totalDistance; // 单位：米
  final double totalAscent; // 单位：米

  const RideStatsCard({
    Key? key,
    required this.totalRides,
    required this.totalTime,
    required this.totalDistance,
    required this.totalAscent,
  }) : super(key: key);

  String get formattedTime {
    final hours = (totalTime ~/ 3600);
    final minutes = ((totalTime % 3600) ~/ 60);
    return '${hours}小时${minutes}分';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('骑行次数', totalRides.toString()),
            _buildStatItem('骑行时间', formattedTime),
            _buildStatItem(
                '骑行距离', '${(totalDistance / 1000).toStringAsFixed(1)} km'),
            _buildStatItem('海拔爬升', '${totalAscent.toStringAsFixed(0)} m'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
