part of datastore_dart;

/// Entity key.
@immutable
class ObjectId {
  const ObjectId.fromString(this.id);

  final String id;

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(other) => other is ObjectId && id == other.id;

  @override
  String toString() => 'ObjectId("$id")';

  String toJson() => id;
}
