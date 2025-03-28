import 'dart:typed_data';
import 'dart:convert';
import 'definition_message.dart';
import 'data_message.dart';
import 'developer.dart';
import 'developer_field_definition.dart';

class FitFile {
  Endian? endianness = Endian.little;

  int fileHeaderLength = 0;
  int? protocolVersion;
  int? profileVersion;
  late int dataSize;
  int lineNumber = 0;
  String? dataType;
  int crc = 0;
  int debugPrintFrom;
  int debugPrintTo;

  late ByteBuffer buffer;
  late ByteData byteData;
  int pointer = 0;

  Map definitionMessages = {};
  List<DeveloperFieldDefinition> developerFieldDefinitions = [];
  List<DataMessage> dataMessages = [];
  List<Developer> developers = [];

  FitFile({
    required Uint8List? content,
    this.debugPrintFrom = 0,
    this.debugPrintTo = 0,
  }) {
    if (content != null) {
      buffer = Uint8List.fromList(content).buffer;
      byteData = ByteData.view(buffer);
      _getFileHeader();
    }
  }

  FitFile parse() {
    while (pointer < fileHeaderLength + dataSize) {
      _getNextRecord();
    }
    return this;
  }

  void _getFileHeader() {
    fileHeaderLength = byteData.getUint8(0);
    pointer = fileHeaderLength;
    protocolVersion = byteData.getUint8(1);
    if (debugPrintFrom < debugPrintTo) {
      print('protocolVersion: $protocolVersion');
    }
    profileVersion = byteData.getUint16(2, endianness!);
    if (debugPrintFrom < debugPrintTo) {
      print('profileVersion: $profileVersion');
    }
    dataSize = byteData.getUint32(4, endianness!);
    if (debugPrintFrom < debugPrintTo) print('dataSize: $dataSize');
    dataType = AsciiDecoder().convert(buffer.asUint8List(8, 4));
    if (debugPrintFrom < debugPrintTo) print('dataType: $dataType');

    if (fileHeaderLength == 14) {
      crc = byteData.getUint16(12, endianness!);
      print('crc: $crc');
    }
  }

  void _getNextRecord() {
    var recordHeader = byteData.getUint8(pointer);
    pointer += 1;
    lineNumber += 1;

    if (recordHeader & 64 == 64) {
      if (lineNumber < debugPrintTo && lineNumber >= debugPrintFrom - 1) {
        print('${lineNumber + 1} DefinitionMessage');
      }
      var definitionMessage =
          DefinitionMessage(fitFile: this, recordHeader: recordHeader);
      definitionMessages[definitionMessage.localMessageType] =
          definitionMessage;
    } else {
      if (lineNumber < debugPrintTo && lineNumber >= debugPrintFrom - 1) {
        print('${lineNumber + 1} DataMessage');
      }
      var dataMessage = DataMessage(fitFile: this, recordHeader: recordHeader);
      dataMessages.add(dataMessage);
    }
  }
}
