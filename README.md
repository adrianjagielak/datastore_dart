[![pub package](https://img.shields.io/pub/v/datastore_dart.svg)](https://pub.dartlang.org/packages/datastore_dart)

`datastore_dart` is a Dart package that provides a high-level API for working
with [Google Cloud Datastore](https://cloud.google.com/datastore).
It features an API syntax that matches that of the popular [`mongo_dart`](https://pub.dev/packages/mongo_dart) driver.

## Features

* Query language and methods that closely resemble those of `mongo_dart`.
* Most of the existing code and examples meant for `mongo_dart` should work without almost any changes needed.
* Utilizes Google's official [Datastore v1 API client library for Dart](https://pub.dev/packages/googleapis).
* Automatic conversion of Datastore Entities to and from simple JSON format (mimicking `mongo_dart`), without the need
  for manual conversion.

## Installation

Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  datastore_dart: any
```

Then, run 'pub get' to install the package.

## Usage

```dart
import 'package:datastore_dart/datastore_dart.dart';

Future main() async {
  String jsonCredentials = File('my-project.json');
  Map<String, dynamic> credentials = jsonDecode(jsonCredentials);

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
```

## Implemented methods

| Command      | Notes                                                                                                                                                                                                                                                                                                                                                                                                         |
|--------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `insertOne`  | Implemented using [projects.commit](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/commit) method.                                                                                                                                                                                                                                                                                   |
| `insertMany` | Implemented using [projects.commit](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/commit) method.                                                                                                                                                                                                                                                                                   |
| `findOne`    | Implemented using [projects.lookup](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/lookup) when filtering only by the key (`eq('_id',val)` or `oneFrom('_id',val)`) and not specifying fields/projection or order, [projects.runQuery](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/runQuery) otherwise.                                                  |
| `find`       | Implemented using [projects.lookup](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/lookup) when filtering only by the key (`eq('_id',val)` or `oneFrom('_id',val)`) and not specifying fields/projection or order, [projects.runQuery](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/runQuery) otherwise.                                                  |
| `updateOne`  | Implemented by first calling `findOne`, then calling [projects.commit](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/commit) with the updated entities (therefore simply using `insertOne` with the updated document instead using `updateOne` is strongly recommended when possible).                                                                                              |
| `updateMany` | Implemented by first calling `find`, then calling [projects.commit](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/commit) with the updated entities (therefore simply using `insertMany` with the updated documents instead using `update` is strongly recommended when possible).                                                                                                  |
| `deleteOne`  | Implemented using [projects.commit](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/commit) when filtering only by the key (`eq('_id',val)` or `oneFrom('_id',val)`) and not specifying fields/projection, order, limit or offset, otherwise first calling `findOne`, then calling [projects.commit](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/commit). |
| `deleteMany` | Implemented using [projects.commit](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/commit) when filtering only by the key (`eq('_id',val)` or `oneFrom('_id',val)`) and not specifying fields/projection, order, limit or offset, otherwise first calling `find`, then calling [projects.commit](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/commit).    |

### See also

- mongo_dart [examples](https://github.com/mongo-dart/mongo_dart/tree/main/example).
