import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'package:ffi/ffi.dart';

// FFI 类型定义
typedef osrm_init_native = Int32 Function(Pointer<Utf8> dataPath);
typedef OsrmInit = int Function(Pointer<Utf8> dataPath);

typedef osrm_route_native = Pointer<Utf8> Function(Pointer<Utf8> jsonRequest);
typedef OsrmRoute = Pointer<Utf8> Function(Pointer<Utf8> jsonRequest);

typedef osrm_free_result_native = Void Function(Pointer<Utf8> result);
typedef OsrmFreeResult = void Function(Pointer<Utf8> result);

class Osrm {
  static final Osrm _instance = Osrm._internal();
  factory Osrm() => _instance;

  late final DynamicLibrary _lib;
  late final OsrmInit _osrmInit;
  late final OsrmRoute _osrmRoute;
  late final OsrmFreeResult _osrmFree;

  Osrm._internal() {
    _lib = _loadLibrary();
    _osrmInit =
        _lib.lookup<NativeFunction<osrm_init_native>>('osrm_init').asFunction();
    _osrmRoute = _lib
        .lookup<NativeFunction<osrm_route_native>>('osrm_route')
        .asFunction();
    _osrmFree = _lib
        .lookup<NativeFunction<osrm_free_result_native>>('osrm_free_result')
        .asFunction();
  }

  DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid || Platform.isLinux) {
      return DynamicLibrary.open('libosrm.so');
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open('libosrm.dylib');
    } else if (Platform.isIOS) {
      return DynamicLibrary.process();
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('osrm.dll');
    } else {
      throw UnsupportedError('不支持的平台');
    }
  }

  /// 初始化 OSRM，dataPath 为 osrm 数据文件路径
  Future<void> init(String dataPath) async {
    final ptr = dataPath.toNativeUtf8();
    final code = _osrmInit(ptr);
    calloc.free(ptr);
    if (code != 0) {
      throw Exception('OSRM 初始化失败，错误码：$code');
    }
  }

  /// 路由查询，jsonRequest 为符合 OSRM API 的 JSON 请求字符串
  Future<Map<String, dynamic>> route(String jsonRequest) async {
    final reqPtr = jsonRequest.toNativeUtf8();
    final resPtr = _osrmRoute(reqPtr);
    calloc.free(reqPtr);
    if (resPtr.address == 0) {
      throw Exception('OSRM 路由返回空');
    }
    final resJson = resPtr.toDartString();
    _osrmFree(resPtr);
    return jsonDecode(resJson) as Map<String, dynamic>;
  }
}
