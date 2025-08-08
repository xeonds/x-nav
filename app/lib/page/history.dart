import 'dart:io';

import 'package:app/component/data.dart';
import 'package:app/component/ride_stats_card.dart';
import 'package:app/database.dart';
import 'package:app/page/history/history_detail.dart';
import 'package:app/utils/analysis_utils.dart';
import 'package:app/utils/data_loader.dart';
import 'package:app/utils/fit.dart';
import 'package:app/utils/model.dart';
import 'package:app/utils/path_utils.dart'
    show RideScore, initCenter, initZoom;
import 'package:app/utils/provider.dart';
import 'package:app/utils/storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fit_tool/fit_tool.dart'
    show Message, RecordMessage, SessionMessage;
import 'package:fl_chart/fl_chart.dart'; // 用于图表
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // 用于地图
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:provider/provider.dart' hide Consumer;
import 'package:share_plus/share_plus.dart';

class RideHistory extends StatefulWidget {
  const RideHistory({super.key});

  @override
  State<RideHistory> createState() => RideHistoryState();
}

class RideHistoryState extends State<RideHistory> {
  // multi-select mode states
  bool isMultiSelectMode = false;
  Set<int> selectedIndices = {};
  
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('骑行记录')),
      body: Column(
        children: [
          Consumer(builder: (context, ref, child){
            final kvs = ref.watch(buildStreamProvider((db)=>db.select(db.kVs).watch()));
            return kvs.when(data: (data){
                final dataMap = Map<String, String>.fromEntries(
                data.map((e) => MapEntry(e.key, e.value)),
                );
              
              return RideSummary(totalDistance: dataMap['totalDistance'], totalRides: dataMap['totalRides'], totalTime: dataMap['totalTime']);
            }, error: (s, e)=>const Center(child: Text('加载失败')), loading: ()=>const Center(child: CircularProgressIndicator())
            );
          }),
          Expanded(
            child: Consumer(builder: (context, ref, child){
              final rides = ref.watch(buildStreamProvider((db)=>db.select(db.historys).watch()));
              return 
              rides.when(data: (data)=>data.isEmpty
              ? const Center(child: Text('没有骑行记录'))
              : StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      children: [
                        if (isMultiSelectMode)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '已选择 ${selectedIndices.length} 项',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('确认删除'),
                                        content: const Text('确定要删除选中的骑行记录吗？'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(false),
                                            child: const Text('取消'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text('删除'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      for (var index in selectedIndices) {
                                        await File(sortedHistory[index].key).delete();
                                      }
                                      // await DataLoader().loadHistoryData();
                                      setState(() {
                                        selectedIndices.clear();
                                        isMultiSelectMode = false;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: data.length,
                            itemBuilder: (context, index) {
                              final isSelected = selectedIndices.contains(index);
                              return GestureDetector(
                                onLongPress: () {
                                  setState(() {
                                    isMultiSelectMode = true;
                                    selectedIndices.add(index);
                                  });
                                },
                                onTap: () {
                                  if (isMultiSelectMode) {
                                    setState(() {
                                      if (isSelected) {
                                        selectedIndices.remove(index);
                                        if (selectedIndices.isEmpty) {
                                          isMultiSelectMode = false;
                                        }
                                      } else {
                                        selectedIndices.add(index);
                                      }
                                    });
                                  } else {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) => RideDetailPage(
                                              history: data[index])),
                                    );
                                  }
                                },
                                child: Container(
                                  color: isSelected
                                      ? Colors.grey.withOpacity(0.3)
                                      : Colors.transparent,
                                  child: buildRideHistoryCard(
                                    rideData: data[index],
                                    summary: data[index].summary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                )
              , error: (s, e)=>const Center(child: Text('加载失败')), loading: ()=>const Center(child: CircularProgressIndicator()));
            })
            
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            allowMultiple: true,
          );
          if (result != null) {
            for (var file in result.files) {
              final path = File(file.path!);
              final fitFile = await path.readAsBytes();
              await Storage().saveFitFile(path.path.split('/').last, fitFile);
            }
          }
        },
        child: const Icon(Icons.file_upload),
      ),
    );
  }

  List<Datetime, History> sortHistoryByTime(List<History> histories) {
    return histories..sort((a,b)=>a.summary.startTime.compareTo(b.summary.startTime));
  }
  
  Widget buildRideHistoryCard(History rideData, Summary summary) {
    return Card(
      child: ListTile(
        leading: SizedBox(
          width: 50,
          height: 50,
          child: CustomPaint(painter: RidePathPainter(rideData.route)),
        ),
        title: Text(
            '${DateTime.fromMillisecondsSinceEpoch((summary.startTime! * 1000 + 631065600000).toInt()).toLocal().toString().replaceFirst('T', ' ')} 的骑行'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '里程: ${(summary.totalDistance! / 1000.0).toStringAsFixed(2)} km 耗时: ${(summary.totalElapsedTime! / 60).toStringAsFixed(2)} 分钟 均速: ${(summary.avgSpeed! * 3.6).toStringAsFixed(2)} km/h',
            ),
          ],
        ),
        onTap: Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RideDetailPage(
                  rideData: rideData),
            ),
        ),
      ),
    );
  }
}
