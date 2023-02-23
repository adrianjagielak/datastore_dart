part of datastore_dart;

class Db {
  /// See, edit, configure, and delete your Google Cloud data and see the email
  /// address for your Google Account.
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  /// View and manage your Google Cloud Datastore data
  static const datastoreScope = 'https://www.googleapis.com/auth/datastore';

  /// Creates [Db] class instance for interacting with Datastore.
  Db(
    dynamic clientCredentialsJson, {
    this.scopes = const [
      datastoreScope,
    ],
    this.rootUrl = 'https://datastore.googleapis.com/',
    this.servicePath = '',
    String? projectId,
  })  : clientCredentials = googleapis_auth.ServiceAccountCredentials.fromJson(
          clientCredentialsJson,
        ),
        projectId = _projectIdFrom(
          projectId: projectId,
          clientCredentialsJson: clientCredentialsJson,
        );

  @Deprecated('Use Db() constructor instead')
  Future<Db> create(
    dynamic clientCredentialsJson, {
    List<String> scopes = const [
      datastoreScope,
    ],
    String rootUrl = 'https://datastore.googleapis.com/',
    String servicePath = '',
    String? projectId,
  }) async {
    return Db(
      clientCredentialsJson,
      scopes: scopes,
      rootUrl: rootUrl,
      servicePath: servicePath,
      projectId: projectId,
    );
  }

  final googleapis_auth.ServiceAccountCredentials? clientCredentials;

  /// OAuth client scopes.
  ///
  /// Working with Datastore requires one of the following OAuth scopes:
  ///
  ///  * https://www.googleapis.com/auth/datastore
  ///  * https://www.googleapis.com/auth/cloud-platform
  ///
  /// For more information, see the [Authentication Overview](https://cloud.google.com/docs/authentication/).
  final List<String>? scopes;

  final String rootUrl;
  final String servicePath;

  final String projectId;

  datastore_api.DatastoreApi? _api;

  Future<datastore_api.DatastoreApi> _getApi() async {
    if (_api == null) {
      final client = await googleapis_auth_io.clientViaServiceAccount(
        clientCredentials!,
        scopes!,
      );

      _api = datastore_api.DatastoreApi(
        client,
        rootUrl: rootUrl,
        servicePath: servicePath,
      );
    }

    return _api!;
  }

  /// Returns [DbCollection] class instance for interacting with Datastore.
  DbCollection collection(String collectionName) {
    return DbCollection(this, collectionName);
  }

  @Deprecated('No-op, not needed')
  Future open({
    dynamic writeConcern,
    dynamic secure,
    dynamic tlsAllowInvalidCertificates,
    dynamic tlsCAFile,
    dynamic tlsCertificateKeyFile,
    dynamic tlsCertificateKeyFilePassword,
  }) async {}

  @Deprecated('No-op, not needed')
  bool get isConnected => true;

  @Deprecated('No-op, not needed')
  Future close() async {}
}

String _projectIdFrom({
  required String? projectId,
  required dynamic clientCredentialsJson,
}) {
  if (projectId != null) {
    return projectId;
  }

  final Map json;
  if (clientCredentialsJson is String) {
    json = jsonDecode(clientCredentialsJson);
  } else {
    if (clientCredentialsJson is! Map) {
      throw ArgumentError('json must be a Map or a String encoding a Map.');
    }
    json = clientCredentialsJson;
  }

  final foundProjectId = json['project_id'];
  if (foundProjectId == null) {
    throw ArgumentError(
      'Project ID not found in client credentials JSON. '
      'Either provide valid client credentials with "project_id" field in it '
      'or specify project name manually using [projectId] parameter.',
    );
  }

  return foundProjectId;
}
