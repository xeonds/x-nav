import 'dart:io';

import 'package:app/utils/fit_parser.dart';

// 生成 mock 类
void main() {
  final result = parseFitFile(
      File('/home/xeonds/code/x-nav/app/test/magene.fit').readAsBytesSync());

  print(result);
}
