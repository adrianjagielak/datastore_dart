part of datastore_dart;

/// A blob value which can be used as a property value in entities.
class BlobValue {
  const BlobValue(this.bytes);

  /// The binary data of this blob.
  final List<int> bytes;
}
