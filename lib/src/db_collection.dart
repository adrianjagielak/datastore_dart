part of datastore_dart;

class DbCollection {
  DbCollection(
    this.db,
    this.collectionName,
  );

  final Db db;

  /// Entity kind.
  final String collectionName;

  @Deprecated('Use insertOne instead')
  Future<WriteResult> insert(
    Map<String, dynamic> document, {
    @Deprecated('Not yet implemented') writeConcern,
    @Deprecated('Not yet implemented') bypassDocumentValidation,
    bool? upsert,
  }) {
    return insertOne(
      document,
      writeConcern: writeConcern,
      bypassDocumentValidation: bypassDocumentValidation,
      upsert: upsert,
    );
  }

  Future<WriteResult> insertOne(
    Map<String, dynamic> document, {
    @Deprecated('Not yet implemented') writeConcern,
    @Deprecated('Not yet implemented') bypassDocumentValidation,
    bool? upsert,
  }) async {
    upsert ??= false;

    try {
      final res = await _commit(
        mutations: [
          datastore_api.Mutation(
            insert: !upsert ? _entityFromJson(document, collectionName) : null,
            upsert: upsert ? _entityFromJson(document, collectionName) : null,
          ),
        ],
      );
      return WriteResult()..id = res.firstOrNull;
    } catch (e) {
      return WriteResult()..writeError = e;
    }
  }

  Future<BulkWriteResult> insertMany(
    List<Map<String, dynamic>> documents, {
    @Deprecated('Not yet implemented') writeConcern,
    @Deprecated('Not yet implemented') bypassDocumentValidation,
    bool? upsert,
  }) async {
    upsert ??= false;

    try {
      final res = await _commit(
        mutations: [
          for (final document in documents)
            datastore_api.Mutation(
              insert:
                  !upsert ? _entityFromJson(document, collectionName) : null,
              upsert: upsert ? _entityFromJson(document, collectionName) : null,
            ),
        ],
      );
      return BulkWriteResult()..ids = res;
    } catch (e) {
      return BulkWriteResult()..writeError = e;
    }
  }

  Future<List<ObjectId>> _commit({
    required List<datastore_api.Mutation> mutations,
  }) async {
    final api = await db._getApi();

    final res = await api.projects.commit(
      datastore_api.CommitRequest(
        // TODO(adrianjagielak): Implement transactions.
        mode: 'NON_TRANSACTIONAL',
        mutations: mutations,
      ),
      db.projectId,
    );
    return res.mutationResults
            ?.map((e) => e.key)
            .map((e) => e?.path?.lastOrNull?.id)
            .where((e) => e != null)
            .map((e) => ObjectId.fromString(e!))
            .toList() ??
        [];
  }

  /// Returns one document that satisfies the specified query criteria on the
  /// collection. If multiple documents satisfy the query, this method returns
  /// the first document.
  ///
  /// !!! It's best to filter only by the key (`eq('_id',val)` or `oneFrom('_id',val)`)
  /// and not specify fields/projection or order if possible, so the cheaper [projects.lookup](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/lookup)
  /// API method is used under the hood and not the more expensive [projects.runQuery](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/runQuery)
  /// API method.
  Future<Map<String, dynamic>?> findOne([selector]) async {
    final datastore_api.Query query;

    if (selector is SelectorBuilder) {
      query = selector._query;
      // } else if (selector is String) {
      // TODO(adrianjagielak): Support GQL.
    } else if (selector == null) {
      query = datastore_api.Query();
    } else {
      throw DatastoreDartError(
        'The selector parameter should be a SelectorBuilder',
      );
    }

    query.limit = 1;

    return (await _find(query: query)).firstOrNull;
  }

  /// Returns documents that satisfies the specified query criteria on the
  /// collection. If multiple documents satisfy the query, this method returns
  /// them all.
  ///
  /// !!! It's best to filter only by the key (`eq('_id',val)` or `oneFrom('_id',val)`)
  /// and not specify fields/projection or order if possible, so the cheaper [projects.lookup](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/lookup)
  /// API method is used under the hood and not the more expensive [projects.runQuery](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/runQuery)
  /// API method.
  Future<List<Map<String, dynamic>>> find([selector]) async {
    final datastore_api.Query query;

    if (selector is SelectorBuilder) {
      query = selector._query;
      // } else if (selector is String) {
      // TODO(adrianjagielak): Support GQL.
    } else if (selector == null) {
      query = datastore_api.Query();
    } else {
      throw DatastoreDartError(
        'The selector parameter should be a SelectorBuilder',
      );
    }

    return _find(query: query);
  }

  /// Returns documents that satisfies the specified query criteria on the
  /// collection. If multiple documents satisfy the query, this method returns
  /// them all.
  ///
  /// !!! It's best to filter only by the key (`eq('_id',val)` or `oneFrom('_id',val)`)
  /// and not specify fields/projection or order if possible, so the cheaper [projects.lookup](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/lookup)
  /// API method is used under the hood and not the more expensive [projects.runQuery](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/runQuery)
  /// API method.
  Future<List<Map<String, dynamic>>> findMany([selector]) async {
    final datastore_api.Query query;

    if (selector is SelectorBuilder) {
      query = selector._query;
      // } else if (selector is String) {
      // TODO(adrianjagielak): Support GQL.
    } else if (selector == null) {
      query = datastore_api.Query();
    } else {
      throw DatastoreDartError(
        'The selector parameter should be a SelectorBuilder',
      );
    }

    return _find(query: query);
  }

  Future<List<Map<String, dynamic>>> _find({
    required datastore_api.Query query,
  }) async {
    query._insertKind(collectionName);

    final api = await db._getApi();

    List<datastore_api.EntityResult> entityResults = [];

    // TODO(adrianjagielak): Allow for additional query fields and process
    //  response locally after the lookup.
    final filters = query.filter?.compositeFilter?.filters ?? [];
    datastore_api.PropertyFilter? propertyFilter;
    if (filters.length == 1) {
      propertyFilter = filters.first.propertyFilter;
    }
    final bool canRunLookup = query.projection == null &&
        query.order == null &&
        query.distinctOn == null &&
        (filters.length == 1) &&
        (
//
            ((propertyFilter!.property?.name == '__key__') &&
                    (propertyFilter.op == 'EQUAL') &&
                    (propertyFilter.value?.keyValue != null))
//
                ||
                ((propertyFilter.property?.name == '__key__') &&
                    (propertyFilter.op == 'IN') &&
                    (propertyFilter.value?.arrayValue?.values?.isNotEmpty ??
                        false) &&
                    (propertyFilter.value!.arrayValue!.values!
                        .every((value) => value.keyValue != null)))
//
        );
    if (canRunLookup) {
      final List<datastore_api.Key> keys;

      if (propertyFilter.value!.keyValue != null) {
        keys = [propertyFilter.value!.keyValue!];
      } else {
        keys = propertyFilter.value!.arrayValue!.values!
            .map((e) => e.keyValue!)
            .toList();
      }

      final res = await api.projects.lookup(
        datastore_api.LookupRequest(
          keys: keys,
        ),
        db.projectId,
      );
      entityResults = res.found ?? [];

      if (query.offset != null && entityResults.length >= query.offset!) {
        entityResults = entityResults.skip(query.offset!).toList();
      }
      if (query.limit != null && entityResults.length >= query.limit!) {
        entityResults = entityResults.take(query.limit!).toList();
      }
    } else {
      final res = await api.projects.runQuery(
        datastore_api.RunQueryRequest(
          query: query,
        ),
        db.projectId,
      );
      entityResults = res.batch?.entityResults ?? [];
    }

    final entities = entityResults
        .where((e) => e.entity != null)
        .map((e) => e.entity!)
        .toList();
    return entities.map(_jsonFromDatastoreEntity).toList();
  }

  /// Removes document from a collection.
  ///
  /// !!! It's best to filter only by the key (`eq('_id',val)` or `oneFrom('_id',val)`)
  /// and not specify fields/projection or order if possible, so the cheaper [projects.lookup](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/lookup)
  /// API method is used under the hood and not the more expensive [projects.runQuery](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/runQuery)
  /// API method.
  Future<WriteResult> deleteOne(
    selector, {
    @Deprecated('Not yet implemented') writeConcern,
    @Deprecated('Not yet implemented') collation,
    @Deprecated('Not yet implemented') hint,
    @Deprecated('Not yet implemented') hintDocument,
  }) async {
    final datastore_api.Query query;

    if (selector is SelectorBuilder) {
      query = selector._query;
      // } else if (selector is String) {
      // TODO(adrianjagielak): Support GQL.
    } else if (selector == null) {
      query = datastore_api.Query();
    } else {
      throw DatastoreDartError(
        'The selector parameter should be a SelectorBuilder',
      );
    }

    query.limit = 1;

    return _delete(
      query: query,
    );
  }

  /// Removes documents from a collection.
  ///
  /// !!! It's best to filter only by the key (`eq('_id',val)` or `oneFrom('_id',val)`)
  /// and not specify fields/projection or order if possible, so the cheaper [projects.lookup](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/lookup)
  /// API method is used under the hood and not the more expensive [projects.runQuery](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/runQuery)
  /// API method.
  Future<WriteResult> deleteMany(
    selector, {
    @Deprecated('Not yet implemented') writeConcern,
    @Deprecated('Not yet implemented') collation,
    @Deprecated('Not yet implemented') hint,
    @Deprecated('Not yet implemented') hintDocument,
  }) async {
    final datastore_api.Query query;

    if (selector is SelectorBuilder) {
      query = selector._query;
      // } else if (selector is String) {
      // TODO(adrianjagielak): Support GQL.
    } else if (selector == null) {
      query = datastore_api.Query();
    } else {
      throw DatastoreDartError(
        'The selector parameter should be a SelectorBuilder',
      );
    }

    return _delete(
      query: query,
    );
  }

  @Deprecated('Use deleteMany instead')
  Future<WriteResult> remove(
    selector, {
    @Deprecated('Not yet implemented') writeConcern,
  }) async {
    return deleteMany(
      selector,
      writeConcern: writeConcern,
    );
  }

  Future<WriteResult> _delete({
    required datastore_api.Query query,
  }) async {
    query._insertKind(collectionName);

// region key only selector (single commit request)
    final filters = query.filter?.compositeFilter?.filters ?? [];
    datastore_api.PropertyFilter? propertyFilter;
    if (filters.length == 1) {
      propertyFilter = filters.first.propertyFilter;
    }
    final bool keyOnlySelector = query.offset == null &&
        query.limit == null &&
        query.projection == null &&
        query.order == null &&
        query.distinctOn == null &&
        (filters.length == 1) &&
        (
//
            ((propertyFilter!.property?.name == '__key__') &&
                    (propertyFilter.op == 'EQUAL') &&
                    (propertyFilter.value?.keyValue != null))
//
                ||
                ((propertyFilter.property?.name == '__key__') &&
                    (propertyFilter.op == 'IN') &&
                    (propertyFilter.value?.arrayValue?.values?.isNotEmpty ??
                        false) &&
                    (propertyFilter.value!.arrayValue!.values!
                        .every((value) => value.keyValue != null)))
//
        );
    if (keyOnlySelector) {
      final List<datastore_api.Key> keys;

      if (propertyFilter.value!.keyValue != null) {
        keys = [propertyFilter.value!.keyValue!];
      } else {
        keys = propertyFilter.value!.arrayValue!.values!
            .map((e) => e.keyValue!)
            .toList();
      }

      try {
        final res = await _commit(
          mutations: [
            for (final key in keys)
              datastore_api.Mutation(
                delete: key,
              ),
          ],
        );
        return WriteResult()..id = res.firstOrNull;
      } catch (e) {
        return WriteResult()..writeError = e;
      }
    }
// endregion

// region different selector (two requests, lookup/query and then commit)

    final documents = await _find(query: query);

    try {
      final res = await _commit(
        mutations: [
          for (final document in documents)
            datastore_api.Mutation(
              delete: _entityFromJson(document, collectionName).key,
            ),
        ],
      );
      return WriteResult()..id = res.firstOrNull;
    } catch (e) {
      return WriteResult()..writeError = e;
    }

// endregion
  }

  /// !!! It's best to just insert the modified document using [insertOne] with
  /// `upsert: true` parameter if possible so only one API method is called ([projects.commit](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/commit))
  /// instead two ([projects.lookup](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/lookup)/[projects.runQuery](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/runQuery)
  /// and then [projects.commit](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/commit)).
  /// You can use [applyUpdateToDocument] helper function to apply the update to the document locally.
  /// For more info see [applyUpdateToDocument].
  Future<WriteResult> updateOne(
    selector,
    update, {
    bool? upsert,
    @Deprecated('Not yet implemented') writeConcern,
    @Deprecated('Not yet implemented') collation,
    @Deprecated('Not yet implemented') arrayFilters,
    @Deprecated('Not yet implemented') hint,
    @Deprecated('Not yet implemented') hintDocument,
  }) async {
    final datastore_api.Query query;

    if (selector is SelectorBuilder) {
      query = selector._query;
      // } else if (selector is String) {
      // TODO(adrianjagielak): Support GQL.
    } else if (selector == null) {
      query = datastore_api.Query();
    } else {
      throw DatastoreDartError(
        'The selector parameter should be a SelectorBuilder',
      );
    }

    query.limit = 1;

    if (update is! ModifierBuilder) {
      throw DatastoreDartError(
        'The update parameter should be a ModifierBuilder',
      );
    }

    try {
      final res = await _update(
        query: query,
        update: update,
        upsert: upsert ?? false,
      );
      return WriteResult()..id = res.firstOrNull;
    } catch (e) {
      return WriteResult()..writeError = e;
    }
  }

  /// !!! It's best to just insert the modified documents using [insertMany] with
  /// `upsert: true` parameter if possible so only one API method is called ([projects.commit](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/commit))
  /// instead two ([projects.lookup](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/lookup)/[projects.runQuery](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/runQuery)
  /// and then [projects.commit](https://cloud.google.com/datastore/docs/reference/data/rest/v1/projects/commit)).
  /// You can use [applyUpdateToDocuments] helper function to apply the update to the documents locally.
  /// For more info see [applyUpdateToDocuments].
  Future<BulkWriteResult> updateMany(
    selector,
    update, {
    bool? upsert,
    @Deprecated('Not yet implemented') writeConcern,
    @Deprecated('Not yet implemented') collation,
    @Deprecated('Not yet implemented') arrayFilters,
    @Deprecated('Not yet implemented') hint,
    @Deprecated('Not yet implemented') hintDocument,
  }) async {
    final datastore_api.Query query;

    if (selector is SelectorBuilder) {
      query = selector._query;
      // } else if (selector is String) {
      // TODO(adrianjagielak): Support GQL.
    } else if (selector == null) {
      query = datastore_api.Query();
    } else {
      throw DatastoreDartError(
        'The selector parameter should be a SelectorBuilder',
      );
    }

    if (update is! ModifierBuilder) {
      throw DatastoreDartError(
        'The update parameter should be a ModifierBuilder',
      );
    }

    try {
      final res = await _update(
        query: query,
        update: update,
        upsert: upsert ?? false,
      );
      return BulkWriteResult()..ids = res;
    } catch (e) {
      return BulkWriteResult()..writeError = e;
    }
  }

  Future<List<ObjectId>> _update({
    required datastore_api.Query query,
    required ModifierBuilder update,
    required bool upsert,
  }) async {
    query._insertKind(collectionName);

    final documents = await _find(query: query);

    final updatedDocuments = <Map<String, dynamic>>[];

    // Add empty document if not found existing on upsert
    if (upsert && updatedDocuments.isEmpty) {
      updatedDocuments.add({});
    }

    for (final document in documents) {
      updatedDocuments.add(applyUpdateToDocument(document, update));
    }

    return _commit(
      mutations: [
        for (final document in documents)
          datastore_api.Mutation(
            update: !upsert ? _entityFromJson(document, collectionName) : null,
            upsert: upsert ? _entityFromJson(document, collectionName) : null,
          ),
      ],
    );
  }

  @Deprecated('Not yet implemented')
  Future<WriteResult> replaceOne(
    selector,
    update, {
    upsert,
    writeConcern,
    collation,
    hint,
    hintDocument,
  }) async {
    return WriteResult();
  }

  @Deprecated('Not yet implemented')
  Future<WriteResult> replaceMany(
    selector,
    update, {
    upsert,
  }) async {
    return WriteResult();
  }

  @Deprecated('Not yet implemented')
  Future<Map<String, dynamic>?> findAndModify({
    query,
    sort,
    remove,
    update,
    returnNew,
    fields,
    upsert,
  }) async {
    return null;
  }

  @Deprecated('Not yet implemented')
  Future<int> count([selector]) async {
    return 0;
  }

  @Deprecated('Not yet implemented')
  Future<Map<String, dynamic>> distinct(String field, [selector]) async {
    return {};
  }

  @Deprecated('Not yet implemented')
  Future<bool> drop() async {
    return true;
  }

// TODO(adrianjagielak): Add the following:
//  * bulk
//  * replaceOne
//  * replaceMany
//  * findAndModify
//  * findAndModify
//  * count
//  * distinct
//  * drop ( https://cloud.google.com/dataflow/docs/guides/templates/provided-utilities#datastore-bulk-delete-[deprecated] )

}
