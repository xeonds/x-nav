// import 'package:app/database.dart';
// import 'package:drift/drift.dart';
import 'dart:typed_data';

import 'package:fit_tool/fit_tool.dart';

void main() async {
  // final db = Database("./test.db");
  final serialized = toSql([
    RecordMessage()
    ..positionLat = 34.2
    ..positionLong = 108.2,
    RecordMessage()
    ..positionLat = 35.2
    ..positionLong = 109.2,
    ]);
  print(serialized);
  final des = fromSql(serialized);
  print("${des.first.positionLat}, ${des[1].positionLong}");
}

List<RecordMessage> fromSql(Uint8List fromDb) {
  final data = ByteData.view(fromDb.buffer);
  int offset = 0;
  final defLength = data.getUint32(offset, Endian.little);
  offset += 4;
  final count = data.getUint32(offset, Endian.little);
  offset += 4;
  final defBytes = fromDb.sublist(offset, offset + defLength);
  offset += defLength;
  final definition = DefinitionMessage.fromBytes(defBytes);
  final messages = <RecordMessage>[];
  for (int i = 0; i < count; i++) {
    final msgLength = data.getUint32(offset, Endian.little);
    offset += 4;
    final msgBytes = fromDb.sublist(offset, offset + msgLength);
    offset += msgLength;
    messages.add(RecordMessage.fromBytes(definition, msgBytes));
  }
  return messages;
}

Uint8List toSql(List<RecordMessage> value) {
  final builder = BytesBuilder();

  final defBytes  = DefinitionMessage.fromDataMessage(value.first).toBytes();

  final header = Uint8List(8);
  final headerData = ByteData.view(header.buffer);

  headerData.setUint32(0, defBytes.length, Endian.little);
  headerData.setUint32(4, value.length, Endian.little);

  builder.add(header);
  builder.add(defBytes);

  for (int i = 0; i < value.length; i++) {
    final msgBytes = value[i].toBytes();
    final lengthHeader = Uint8List(4);
    final lengthData = ByteData.view(lengthHeader.buffer);
    lengthData.setUint32(0, msgBytes.length, Endian.little);

    builder.add(lengthHeader);
    builder.add(msgBytes);
  }

  return builder.toBytes();
}
