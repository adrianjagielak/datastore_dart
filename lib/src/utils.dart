part of datastore_dart;

datastore_api.Entity _entityFromJson(Map json, String kind) {
  final Map effectiveJson = Map.from(json);

  final datastore_api.PathElement keyPathElement = datastore_api.PathElement(
    kind: kind,
  );

  if (effectiveJson.containsKey('_id')) {
    if (effectiveJson['_id'] is ObjectId) {
      keyPathElement.id = (effectiveJson['_id'] as ObjectId).id;
      effectiveJson.remove('_id');
    } else if (effectiveJson['_id'] is String) {
      keyPathElement.id = effectiveJson['_id'] as String;
      effectiveJson.remove('_id');
    }
  }

  return datastore_api.Entity(
    key: datastore_api.Key(
      path: [keyPathElement],
    ),
    properties: _datastoreValuesFromJson(effectiveJson),
  );
}

datastore_api.Value _datastoreValueFromJson(dynamic value) {
  final apiValue = datastore_api.Value();

  if (value == null) {
    return apiValue..nullValue = 'NULL_VALUE';
  } else if (value is bool) {
    return apiValue..booleanValue = value;
  } else if (value is int) {
    return apiValue..integerValue = value.toString();
  } else if (value is double) {
    return apiValue..doubleValue = value;
  } else if (value is String) {
    return apiValue..stringValue = value;
  } else if (value is DateTime) {
    return apiValue..timestampValue = value.toUtc().toIso8601String();
  } else if (value is List) {
    return apiValue
      ..arrayValue = datastore_api.ArrayValue(
        values: value.map(_datastoreValueFromJson).toList(),
      );
  } else if (value is Map) {
    return apiValue
      ..entityValue = datastore_api.Entity(
        properties: _datastoreValuesFromJson(value),
      );
  } else if (value is BlobValue) {
    return apiValue..blobValueAsBytes = value.bytes;
  } else if (value is ObjectId) {
    return apiValue
      ..keyValue = datastore_api.Key(
        path: [datastore_api.PathElement(id: value.id)],
      );
  } else {
    throw UnsupportedError(
      'Type ${value.runtimeType} cannot be used for serializing.',
    );
  }
}

Map<String, datastore_api.Value> _datastoreValuesFromJson(Map json) {
  final Map<String, datastore_api.Value> result = {};

  for (final entry in json.entries) {
    final key = entry.key;
    final value = entry.value;

    result[key] = _datastoreValueFromJson(value);
  }

  return result;
}

Map<String, dynamic> _jsonFromDatastoreEntity(datastore_api.Entity entity) {
  final Map<String, dynamic> result = {};

  final keyPath = entity.key?.path ?? [];
  if (keyPath.isNotEmpty && keyPath.last.id != null) {
    result['_id'] = ObjectId.fromString(keyPath.last.id!);
  }

  for (final MapEntry<String, datastore_api.Value> property
      in entity.properties?.entries.toList() ?? []) {
    final key = property.key;
    final value = property.value;

    result[key] = _jsonFromDatastoreValue(value);
  }

  return result;
}

dynamic _jsonFromDatastoreValue(datastore_api.Value value) {
  if (value.booleanValue != null) {
    return value.booleanValue;
  } else if (value.integerValue != null) {
    return int.parse(value.integerValue!);
  } else if (value.doubleValue != null) {
    return value.doubleValue;
  } else if (value.stringValue != null) {
    return value.stringValue;
  } else if (value.timestampValue != null) {
    return DateTime.parse(value.timestampValue!);
  } else if (value.blobValue != null) {
    return BlobValue(value.blobValueAsBytes);
  } else if (value.keyValue != null) {
    final keyPath = value.keyValue?.path ?? [];
    if (keyPath.isEmpty || keyPath.last.id == null) {
      throw UnsupportedError('Keys without IDs are not supported.');
    }
    return ObjectId.fromString(keyPath.last.id!);
  } else if (value.arrayValue != null && value.arrayValue!.values != null) {
    return value.arrayValue!.values!.map(_jsonFromDatastoreValue).toList();
  } else if (value.entityValue != null) {
    return _jsonFromDatastoreEntity(value.entityValue!);
  } else if (value.geoPointValue != null) {
    throw UnsupportedError('GeoPoint values are not supported.');
  }
  return null;
}

extension GetSetRemoveNestedMapExtension on Map {
  dynamic _get(String key) {
    final keys = key.split('.');
    dynamic value = Map.from(this);
    for (final k in keys) {
      if (value == null) {
        return null;
      }
      value = value[k];
    }
    return value;
  }

  void _set(String key, dynamic value) {
    final keys = key.split('.');
    if (keys.length == 1) {
      this[key] = value;
    } else {
      if (!containsKey(keys.first)) {
        this[keys.first] = {};
      }
      this[keys.first]._set(keys.sublist(1).join('.'), value);
    }
  }

  void _removeNested(String key) {
    final keys = key.split('.');
    if (keys.length == 1) {
      remove(key);
    } else {
      if (!containsKey(keys.first)) {
        return;
      }
      this[keys.first]._removeNested(keys.sublist(1).join('.'));
    }
  }
}

const _equality = DeepCollectionEquality();

extension _InsertKindToQueryExtension on datastore_api.Query {
  void _insertKind(String kind) {
    this.kind = [datastore_api.KindExpression(name: kind)];

    for (final propertyFilter in (filter?.compositeFilter?.filters ?? [])
        .map((e) => e.propertyFilter)
        .toList()) {
      if ((propertyFilter?.value?.keyValue?.path ?? []).isNotEmpty) {
        propertyFilter!.value!.keyValue!.path!.last.kind = kind;
      }
      if ((propertyFilter?.value?.arrayValue?.values?.isNotEmpty ?? false) &&
          (propertyFilter!.value!.arrayValue!.values!
              .any((value) => value.keyValue != null))) {
        final List<datastore_api.Value> newValues = [];
        for (final value in propertyFilter.value!.arrayValue!.values!) {
          if ((value.keyValue?.path ?? []).isNotEmpty) {
            value.keyValue!.path!.last.kind = kind;
          }

          newValues.add(value);
        }
        propertyFilter.value!.arrayValue!.values = newValues;
      }
    }
  }
}
