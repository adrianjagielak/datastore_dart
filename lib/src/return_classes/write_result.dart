part of datastore_dart;

class WriteResult {
  /// The automatically allocated key.
  ///
  /// Set only when the mutation allocated a key.
  ObjectId? id;

  dynamic writeError;

  bool get hasWriteErrors => writeError != null;
}
