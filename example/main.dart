import 'package:datastore_dart/datastore_dart.dart';

Future main() async {
  // TODO: replace the credentials.
  var credentials = {
    'type': 'service_account',
    'project_id': '',
    'private_key_id': '',
    'private_key': '',
    'client_email': '',
    'client_id': '',
    'auth_uri': '',
    'token_uri': 'https://oauth2.googleapis.com/token',
    'auth_provider_x509_cert_url': 'https://www.googleapis.com/oauth2/v1/certs',
    'client_x509_cert_url': ''
  };

  var db = Db(credentials);
  var collection = db.collection('my_kind');

  // Insert entity
  await collection.insertOne({
    'name': 'Tom',
    'rating': 100,
  });

  // Query entity
  Map<String, dynamic>? result =
      await collection.findOne(where.eq('name', 'Tom').gt('rating', 10));
}
