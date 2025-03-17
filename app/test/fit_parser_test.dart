import 'package:flutter_test/flutter_test.dart';
import 'package:fit_parser/fit_parser.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:app/utils/fit_parser.dart';

import 'fit_parser_test.mocks.dart';

// 生成 mock 类
@GenerateMocks([FitFile])
void main() {
  group('FitParser', () {
    test('parseFitFile should return correct data', () {
      // 创建 mock FitFile
      final mockFitFile = MockFitFile();
      when(mockFitFile.parse()).thenReturn({
        'dataMessages': [
          {
            'record': {
              'position_lat': 123456789,
              'position_long': 987654321,
              'distance': 10000,
              'timestamp': 3600,
              'speed': 10,
            }
          }
        ]
      } as FitFile);

      // 调用 parseFitFile 函数
      final result = FitParser.parseFitFile('mockFile.fit');

      // 验证结果
      expect(result['distance'], 10.0);
      expect(result['time'], 60);
      expect(result['speed'], 36.0);
      expect(result['points'], [LatLng(12.3456789, 98.7654321)]);
    });
  });
}
