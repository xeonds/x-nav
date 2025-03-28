import 'package:collection/collection.dart' show IterableExtension;
import 'package:app/utils/fit_parser/src/developer_field.dart';
import 'package:app/utils/fit_parser/src/field.dart';
import 'package:app/utils/fit_parser/src/fields/base_types.dart';
import 'package:app/utils/fit_parser/src/fit_file.dart';
import 'dart:convert';
import 'package:app/utils/fit_parser/src/fit_type.dart';
import 'dart:typed_data';

class Value {
  String? fieldName;
  String? fieldType;
  String? dataType;
  int? size;
  int? baseTypeByte;
  FitFile fitFile;
  dynamic _numericValue;
  dynamic scale;
  double? offset;
  String? units;
  dynamic value;
  late Field field;
  late DeveloperField developerField;
  Map? messageTypeFields;
  int? pointer;
  Endian? architecture;

  int get baseTypeNumber => baseTypeByte! & 31;
  int? get baseType => baseTypes[baseTypeNumber]['type_name'];
  int? get baseTypeSize => baseTypes[baseTypeNumber]['size'];

  Value resolveReference({List<Value>? values}) {
    if (messageTypeFields != null) {
      var referenceFieldName = messageTypeFields!['reference_field_name'];
      Value? referenceValue;

      // Reference field replacement
      if (referenceFieldName != null) {
        referenceValue = values!.firstWhereOrNull((currentValue) {
          return (currentValue.messageTypeFields != null) &&
              (currentValue.messageTypeFields!['field_name'] ==
                  referenceFieldName);
        });
        if (referenceValue != null) {
          Map? reference =
              messageTypeFields!['reference_field_value'][referenceValue.value];
          if (reference != null) {
            fieldName = reference['field_name'] ?? fieldName;
            fieldType = reference['field_type'] ?? fieldType;
            dataType = reference['data_type'] ?? dataType;
            units = reference['data_type'] ?? units;
            scale = reference['scale'] ?? scale;
            offset = reference['offset'] ?? offset;
            value = fieldType != null ? lookupValue() : value;
          }
        }
      }
    }
    return this;
  }

  dynamic lookupValue() {
    if (FitType.type[fieldType] != null) {
      // fieldType parsing
      _numericValue ??= getInt(signed: false, dataTypeSize: size);
      dynamic lookup = FitType.type[fieldType][_numericValue] ?? _numericValue;
      return lookup;
    } else if (fieldType == 'unknown') {
      return null;
    } else {
      throw 'Field type $fieldType not available';
    }
  }

  dynamic determineValue() {
    // Data parsing
    if (fieldType != null) {
      dynamic lookedUpValue = lookupValue();
      fitFile.pointer += size!;
      return lookedUpValue;
    } else if (dataType != null) {
      // dataType parsing
      switch (dataType) {
        case 'bool':
          return getBool();
        case 'sint8':
          return getIntegers(signed: true, dataTypeSize: 1);
        case 'byte':
        case 'enum':
        case 'uint8':
        case 'uint8z':
          return getIntegers(signed: false, dataTypeSize: 1);

        case 'sint16':
          return getIntegers(signed: true, dataTypeSize: 2);
        case 'uint16':
        case 'uint16z':
          return getIntegers(signed: false, dataTypeSize: 2);

        case 'sint32':
          return getIntegers(signed: true, dataTypeSize: 4);
        case 'date_time':
        case 'local_date_time':
        case 'localtime_into_day':
        case 'uint32':
        case 'uint32z':
          return getIntegers(signed: false, dataTypeSize: 4);

        case 'sint64':
          return getIntegers(signed: true, dataTypeSize: 8);
        case 'uint64':
        case 'uint64z':
          return getIntegers(signed: false, dataTypeSize: 8);

        case 'float32':
          return getFloats(dataTypeSize: 4);
        case 'float64':
          return getFloats(dataTypeSize: 8);

        case 'string':
          return getString();
      }
    } else {
      // Neither data type nor field type available!
      fitFile.pointer += size!;
      return null;
    }
  }

  dynamic getIntegers({signed, required int dataTypeSize}) {
    var duplicity = size! ~/ dataTypeSize;
    dynamic value;

    if (duplicity > 1) {
      var values = [];
      for (var counter = 1; counter <= duplicity; counter++) {
        value = getInt(signed: signed, dataTypeSize: dataTypeSize);
        value = value / scale - offset!.round();
        values.add(value);
        fitFile.pointer += dataTypeSize;
      }
      return values;
    } else {
      _numericValue = getInt(signed: signed, dataTypeSize: dataTypeSize);
      value = _numericValue / scale - offset!.round();
      fitFile.pointer += dataTypeSize;
      return value;
    }
  }

  bool getBool() {
    bool tempValue;
    if (fitFile.byteData.getInt8(fitFile.pointer) == 0) {
      tempValue = false;
    } else {
      tempValue = true;
    }
    fitFile.pointer += 1;
    return tempValue;
  }

  int getInt({signed, dataTypeSize}) {
    switch (dataTypeSize) {
      case 1:
        return signed
            ? fitFile.byteData.getInt8(fitFile.pointer)
            : fitFile.byteData.getUint8(fitFile.pointer);
      case 2:
        return signed
            ? fitFile.byteData.getInt16(fitFile.pointer, architecture!)
            : fitFile.byteData.getUint16(fitFile.pointer, architecture!);
      case 4:
        return signed
            ? fitFile.byteData.getInt32(fitFile.pointer, architecture!)
            : fitFile.byteData.getUint32(fitFile.pointer, architecture!);
      case 8:
        return signed
            ? fitFile.byteData.getInt64(fitFile.pointer, architecture!)
            : fitFile.byteData.getUint64(fitFile.pointer, architecture!);
      default:
        throw ('No valid data type size in getInt');
    }
  }

  dynamic getFloats({required int dataTypeSize}) {
    var duplicity = size! ~/ dataTypeSize;
    double value;

    if (duplicity > 1) {
      var values = [];
      for (var counter = 1; counter <= duplicity; counter++) {
        value = getFloat(dataTypeSize: dataTypeSize);
        value = value / scale - offset!;
        values.add(value);
        fitFile.pointer += dataTypeSize;
      }
      return values;
    } else {
      value = getFloat(dataTypeSize: dataTypeSize);
      value = value / scale - offset!;
      fitFile.pointer += dataTypeSize;
      return value;
    }
  }

  double getFloat({signed, dataTypeSize}) {
    switch (dataTypeSize) {
      case 4:
        return fitFile.byteData.getFloat32(fitFile.pointer, architecture!);
      case 8:
        return fitFile.byteData.getFloat64(fitFile.pointer, architecture!);
      default:
        throw ('No valid data type size in getFloat');
    }
  }

  String getString() {
    var value = AsciiCodec().decode(
        fitFile.buffer.asUint8List(fitFile.pointer, size),
        allowInvalid: true);
    fitFile.pointer += size!;
    return value;
  }

  Value({required this.fitFile, required this.field, this.architecture}) {
    pointer = fitFile.pointer;
    messageTypeFields = field.messageTypeFields;
    fieldName = field.fieldName;
    fieldType = field.fieldType;
    dataType = field.dataType;
    scale = field.scale;
    offset = field.offset;
    units = field.units;
    size = field.size;
    baseTypeByte = field.baseTypeByte;
    value = determineValue();
  }

  Value.fromDeveloperField({
    required this.fitFile,
    required this.developerField,
    this.architecture,
  }) {
    pointer = fitFile.pointer;
    size = developerField.size;
    dataType = developerField.dataType;
    units = developerField.units;
    fieldName = developerField.fieldName;
    scale = 1;
    offset = 0;
    value = determineValue();
  }
}
