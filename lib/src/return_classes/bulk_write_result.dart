part of datastore_dart;

class BulkWriteResult {
  /// The automatically allocated keys.
  ///
  /// Set only when the mutation allocated a keys.
  List<ObjectId>? ids;

  dynamic writeError;

  bool get hasWriteErrors => writeError != null;
}
