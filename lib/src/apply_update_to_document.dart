part of datastore_dart;

/// Applies [update] to [documents] and returns modified documents list.
List<Map<String, dynamic>> applyUpdateToDocuments(
  List<Map<String, dynamic>> documents,
  ModifierBuilder update,
) {
  final updatedDocuments = <Map<String, dynamic>>[];

  for (final document in documents) {
    updatedDocuments.add(applyUpdateToDocument(document, update));
  }

  return updatedDocuments;
}

/// Applies [update] to [document] and returns modified document.
Map<String, dynamic> applyUpdateToDocument(
  Map<String, dynamic> document,
  ModifierBuilder update,
) {
  for (final operationType in update.map.entries) {
    final operations = (operationType.value as Map<String, dynamic>).entries;

    switch (operationType.key) {
      // ************************
      // *** Field operators

      case r'$inc':
        for (final operation in operations) {
          final fieldName = operation.key;

          final oldValue = document._get(fieldName);
          final operationValue = operation.value;

          if (oldValue == null) {
            document._set(fieldName, operationValue);
          } else {
            document._set(fieldName, oldValue + operationValue);
          }
        }
        break;

      case r'$min':
        for (final operation in operations) {
          final fieldName = operation.key;

          final oldValue = document._get(fieldName);
          final operationValue = operation.value;

          if (oldValue == null) {
            document._set(fieldName, operationValue);
          } else {
            document._set(
              fieldName,
              math.min<num>(oldValue, operationValue),
            );
          }
        }
        break;

      case r'$max':
        for (final operation in operations) {
          final fieldName = operation.key;

          final oldValue = document._get(fieldName);
          final operationValue = operation.value;

          if (oldValue == null) {
            document._set(fieldName, operationValue);
          } else {
            document._set(
              fieldName,
              math.max<num>(oldValue, operationValue),
            );
          }
        }
        break;

      case r'$mul':
        for (final operation in operations) {
          final fieldName = operation.key;

          final oldValue = document._get(fieldName);
          final operationValue = operation.value;

          if (oldValue == null) {
            document._set(fieldName, 0);
          } else {
            document._set(fieldName, oldValue * operationValue);
          }
        }
        break;

      case r'$rename':
        for (final operation in operations) {
          final oldName = operation.key;

          final String newName = operation.value;

          if (document.containsKey(oldName)) {
            document
              .._set(newName, document._get(oldName))
              .._removeNested(oldName);
          }
        }
        break;

      case r'$set':
        for (final operation in operations) {
          final fieldName = operation.key;
          final value = operation.value;

          document._set(fieldName, value);
        }
        break;

      case r'$unset':
        for (final operation in operations) {
          final fieldName = operation.key;

          document._removeNested(fieldName);
        }
        break;

      // ************************
      // *** Array operators

      case r'$addToSet':
        for (final operation in operations) {
          final fieldName = operation.key;
          final value = operation.value;

          final list = List.from(document._get(fieldName) ?? []);

          if (!list.any((e) => _equality.equals(e, value))) {
            list.add(value);
          }

          document._set(fieldName, list);
        }
        break;

      case r'$pop':
        for (final operation in operations) {
          final fieldName = operation.key;
          final value = operation.value;

          final list = List.from(document._get(fieldName) ?? []);

          if (list.isNotEmpty) {
            if (value == -1) {
              // pop first
              list.removeAt(0);
            } else if (value == 1) {
              // pop last
              list.removeLast();
            }
          }

          document._set(fieldName, list);
        }
        break;

      case r'$pull':
        for (final operation in operations) {
          final fieldName = operation.key;
          final value = operation.value;

          final list = List.from(document._get(fieldName) ?? []);

          list.removeWhere((e) => _equality.equals(e, value));

          document._set(fieldName, list);
        }
        break;

      case r'$pullAll':
        for (final operation in operations) {
          final fieldName = operation.key;
          final List value = operation.value;

          final list = List.from(document._get(fieldName) ?? []);

          list.removeWhere((e1) => value.any((e2) => _equality.equals(e1, e2)));

          document._set(fieldName, list);
        }
        break;

      case r'$push':
        for (final operation in operations) {
          final fieldName = operation.key;
          final value = operation.value;

          final list = List.from(document._get(fieldName) ?? []);

          list.add(value);

          document._set(fieldName, list);
        }
        break;

      case r'$pushAll':
        for (final operation in operations) {
          final fieldName = operation.key;
          final List value = operation.value;

          final list = List.from(document._get(fieldName) ?? []);

          list.addAll(value);

          document._set(fieldName, list);
        }
        break;
    }
  }

  return document;
}
