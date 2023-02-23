part of datastore_dart;

class DatastoreDartError extends Error {
  DatastoreDartError(
    this.message, {
    this.mongoCode,
    String? errorCode,
    this.errorCodeName,
  }) : errorCode = errorCode ?? (mongoCode != null ? '$mongoCode' : null);

  final String message;
  final int? mongoCode;
  final String? errorCode;
  final String? errorCodeName;

  @override
  String toString() => 'Datastore Error: $message';
}
