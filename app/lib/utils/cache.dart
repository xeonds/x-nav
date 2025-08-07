import 'package:app/utils/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Cache {
  final Ref _ref;
  
  Cache(this._ref);
  
  // 获取数据（优先从缓存读取）
  Future<List<T>> getCachedData<T>(ProviderBase<AsyncValue<List<T>>> provider) async {
    final state = _ref.read(provider);
    
    if (state is AsyncData && state.value != null) {
      return state.value!; // 返回缓存数据
    }
    
    // 无缓存时重新加载
    // ignore: unused_result, await_only_futures
    await _ref.refresh(provider);
    return _ref.read(provider).value ?? [];
  }
  
  // 预加载关键数据
  void preloadCriticalData() {
    _ref.read(historyProvider.future); // 提前加载但不阻塞UI
  }
}