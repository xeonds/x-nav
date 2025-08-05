class SortManager<T, K> {
  final bool Function(T a, T b) _comparator;
  final List<Entry<T, K>> dataList = [];

  SortManager(this._comparator);

  void append(T item, K key) {
    dataList.add(Entry(item, key));
  }

  int getPositionTillCurrentIndex(K index) {
    final tIndex = dataList.indexWhere((entry) => entry.key == index);
    if (tIndex == -1) {
      return -1;
    }
    final target = dataList[tIndex];
    final subList = dataList.sublist(0, tIndex + 1);
    subList.sort((a, b) => _comparator(a.item, b.item)
        ? 1
        : _comparator(b.item, a.item)
            ? -1
            : 0);
    for (int i = 0; i < subList.length; i++) {
      if (identical(subList[i], target)) {
        return i;
      }
    }
    return -1;
  }

  int getPositionOfFullList(K index) {
    final tIndex = dataList.indexWhere((entry) => entry.key == index);
    if (tIndex == -1) {
      return -1;
    }
    final target = dataList[tIndex];
    final subList = dataList.sublist(0, dataList.length);
    subList.sort((a, b) => _comparator(a.item, b.item)
        ? 1
        : _comparator(b.item, a.item)
            ? -1
            : 0);
    for (int i = 0; i < subList.length; i++) {
      if (identical(subList[i], target)) {
        return i;
      }
    }
    return -1;
  }
}

class Entry<T, K> {
  final T item;
  final K key;

  Entry(this.item, this.key);
}

// 计算给定滑动窗口尺寸列表的最大平均值算法
Map<int, R> calculateMaxRangeAvgs<T, R extends Comparable<R>>(
    List<int> keys, List<T> values, R Function(int, List<T>) calcRangeAvg) {
  Map<int, R> res = {}; // 结果数组，key为keys, value为最大均值
  for (var key in keys.where((e) => e <= values.length)) {
    // 处理不同区间长度
    R maxAvg = calcRangeAvg(key, values.sublist(0, key)); // 当前区间最大长度
    for (int start = 0; start + key < values.length; start++) {
      // 遍历所有可能的开头点
      final range = values.sublist(start, start + key);
      final avg = calcRangeAvg(key, range);
      maxAvg = maxAvg.compareTo(avg) < 0 ? maxAvg : avg;
    }
    res[key] = maxAvg;
  }
  return res;
}

String secondToFormatTime(num seconds) {
  if (seconds.isInfinite || seconds.isNaN) {
    return '00:00';
  }
  int hours = seconds ~/ 3600;
  int minutes = (seconds % 3600) ~/ 60;
  int secs = seconds.toInt() % 60;

  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  } else {
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
