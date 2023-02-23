part of datastore_dart;

ModifierBuilder get modify => ModifierBuilder();

class ModifierBuilder {
  Map<String, dynamic> map = {};

  @override
  String toString() => 'ModifierBuilder($map)';

  void _updateOperation(String operator, String fieldName, value) {
    var opMap = map[operator] as Map<String, dynamic>?;
    if (opMap == null) {
      opMap = <String, dynamic>{};
      map[operator] = opMap;
    }
    opMap[fieldName] = value;
  }

  // ************************
  // *** Field operators

  /// Increments the value of the field by the specified amount.
  ModifierBuilder inc(String fieldName, value) {
    _updateOperation(r'$inc', fieldName, value);
    return this;
  }

  /// Only updates the field if the specified value is less than
  /// the existing field value
  ModifierBuilder min(String fieldName, value) {
    _updateOperation(r'$min', fieldName, value);
    return this;
  }

  /// Only updates the field if the specified value is greater than the
  /// existing field value.
  ModifierBuilder max(String fieldName, value) {
    _updateOperation(r'$max', fieldName, value);
    return this;
  }

  /// Multiplies the value of the field by the specified amount
  ModifierBuilder mul(String fieldName, value) {
    _updateOperation(r'$mul', fieldName, value);
    return this;
  }

  ModifierBuilder rename(String oldName, String newName) {
    _updateOperation(r'$rename', oldName, newName);
    return this;
  }

  ModifierBuilder set(String fieldName, value) {
    _updateOperation(r'$set', fieldName, value);
    return this;
  }

  @Deprecated('Not yet implemented')
  ModifierBuilder setOnInsert(String fieldName, value) {
    return this;
  }

  ModifierBuilder unset(String fieldName) {
    _updateOperation(r'$unset', fieldName, 1);
    return this;
  }

  // ************************
  // *** Array operators

  /// Adds elements to an array only if they do not already exist in the set.
  ModifierBuilder addToSet(String fieldName, value) {
    _updateOperation(r'$addToSet', fieldName, value);
    return this;
  }

  /// The popFirst operator removes the first element of an array.
  ModifierBuilder popFirst(String fieldName) {
    _updateOperation(r'$pop', fieldName, -1);
    return this;
  }

  /// The popLast operator removes the last element of an array.
  ModifierBuilder popLast(String fieldName) {
    _updateOperation(r'$pop', fieldName, 1);
    return this;
  }

  /// The pull operator removes from an existing array all instances
  /// of a value that match a specified condition.
  ModifierBuilder pull(String fieldName, value) {
    _updateOperation(r'$pull', fieldName, value);
    return this;
  }

  /// The pull operator removes from an existing array all instances
  /// of values that match a specified condition.
  ModifierBuilder pullAll(String fieldName, List values) {
    _updateOperation(r'$pullAll', fieldName, values);
    return this;
  }

  /// Adds an item to an array.
  ModifierBuilder push(String fieldName, value) {
    _updateOperation(r'$push', fieldName, value);
    return this;
  }

  /// Removes all matching values from an array.
  ModifierBuilder pushAll(String fieldName, List values) {
    _updateOperation(r'$pushAll', fieldName, values);
    return this;
  }
}
