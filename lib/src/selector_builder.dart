part of datastore_dart;

SelectorBuilder get where => SelectorBuilder();

class SelectorBuilder {
  final datastore_api.Query _query = datastore_api.Query();

  @override
  String toString() => 'SelectorBuilder($_query)';

  void _addPropertyFilterRaw(datastore_api.PropertyFilter filter) {
    _query.filter ??= datastore_api.Filter(
      compositeFilter: datastore_api.CompositeFilter(
        filters: [],
        op: 'AND',
      ),
    );

    _query.filter!.compositeFilter!.filters!.add(
      datastore_api.Filter(
        propertyFilter: filter,
      ),
    );
  }

  void _addPropertyFilter(String fieldName, String? op, value) {
    String effectiveFieldName = fieldName;
    if (effectiveFieldName == '_id') {
      // https://cloud.google.com/datastore/docs/concepts/queries#key_filters
      effectiveFieldName = '__key__';
    }

    _addPropertyFilterRaw(datastore_api.PropertyFilter(
      property: datastore_api.PropertyReference(
        name: effectiveFieldName,
      ),
      op: op,
      value: _datastoreValueFromJson(value),
    ));
  }

  /// The given property is equal to the given [value].
  SelectorBuilder eq(String fieldName, value) {
    _addPropertyFilter(fieldName, 'EQUAL', value);
    return this;
  }

  SelectorBuilder id(ObjectId value) {
    // https://cloud.google.com/datastore/docs/concepts/queries#key_filters
    _addPropertyFilter('__key__', 'EQUAL', value);
    return this;
  }

  SelectorBuilder key(ObjectId value) {
    // https://cloud.google.com/datastore/docs/concepts/queries#key_filters
    _addPropertyFilter('__key__', 'EQUAL', value);
    return this;
  }

  /// The given property is not equal to the given [value].
  ///
  /// Requires:
  ///   * No other `NOT_EQUAL` or `NOT_IN` is in the same query.
  ///   * That property comes first in the `order_by`.
  SelectorBuilder ne(String fieldName, value) {
    _addPropertyFilter(fieldName, 'NOT_EQUAL', value);
    return this;
  }

  /// The given property is greater than the given [value].
  ///
  /// Requires:
  ///   * That property comes first in `order_by`.
  SelectorBuilder gt(String fieldName, value) {
    _addPropertyFilter(fieldName, 'GREATER_THAN', value);
    return this;
  }

  SelectorBuilder lt(String fieldName, value) {
    _addPropertyFilter(fieldName, 'LESS_THAN', value);
    return this;
  }

  /// The given property is greater than or equal to the given [value].
  ///
  /// Requires:
  ///   * That property comes first in `order_by`.
  SelectorBuilder gte(String fieldName, value) {
    _addPropertyFilter(fieldName, 'GREATER_THAN_OR_EQUAL', value);
    return this;
  }

  SelectorBuilder lte(String fieldName, value) {
    _addPropertyFilter(fieldName, 'LESS_THAN_OR_EQUAL', value);
    return this;
  }

  @Deprecated('Not yet implemented')
  SelectorBuilder all(String fieldName, List values) {
    return this;
  }

  /// The value of the property is not in the given array.
  ///
  /// Requires:
  ///   * That [values] is a non-empty list with at most 10 values.
  ///   * No other `IN`, `NOT_IN`, `NOT_EQUAL` is in the same query.
  ///   * That `field` comes first in the `order_by`.
  SelectorBuilder nin(String fieldName, List values) {
    _addPropertyFilter(fieldName, 'NOT_IN', values);
    return this;
  }

  /// The given property is equal to at least one value in the given array.
  ///
  /// Requires:
  ///   * That [values] is a non-empty list with at most 10 values OR this query
  ///     only having this one filter and the type of elements in [values] list
  ///     is only [ObjectId].
  ///   * No other `IN` or `NOT_IN` is in the same query.
  // Name constrained by the reserved Dart keyword "in".
  SelectorBuilder in_(String fieldName, List values) {
    _addPropertyFilter(fieldName, 'IN', values);
    return this;
  }

  /// The given property is equal to at least one value in the given array.
  ///
  /// Requires:
  ///   * That [values] is a non-empty list with at most 10 values OR this query
  ///     only having this one filter and the type of elements in [values] list
  ///     is only [ObjectId].
  ///   * No other `IN` or `NOT_IN` is in the same query.
  SelectorBuilder oneFrom(String fieldName, List values) {
    _addPropertyFilter(fieldName, 'IN', values);
    return this;
  }

  /// The given property is not equal to null.
  ///
  /// Requires:
  ///   * No other `NOT_EQUAL` or `NOT_IN` is in the same query.
  ///   * That property comes first in the `order_by`.
  SelectorBuilder exists(String fieldName) {
    _addPropertyFilter(fieldName, 'NOT_EQUAL', null);
    return this;
  }

  /// The given property is equal to null.
  SelectorBuilder notExists(String fieldName) {
    _addPropertyFilter(fieldName, 'EQUAL', null);
    return this;
  }

  @Deprecated('Not yet implemented')
  SelectorBuilder mod(String fieldName, int value) {
    return this;
  }

  @Deprecated('Not yet implemented')
  SelectorBuilder match(String fieldName, String pattern,
      {bool? multiLine, bool? caseInsensitive, bool? dotAll, bool? extended}) {
    return this;
  }

  /// See: [gt], [gte], [lt], and [lte].
  SelectorBuilder inRange(String fieldName, min, max,
      {bool minInclude = true, bool maxInclude = false}) {
    if (minInclude) {
      _addPropertyFilter(fieldName, 'GREATER_THAN_OR_EQUAL', min);
    } else {
      _addPropertyFilter(fieldName, 'GREATER_THAN', min);
    }
    if (maxInclude) {
      _addPropertyFilter(fieldName, 'LESS_THAN_OR_EQUAL', max);
    } else {
      _addPropertyFilter(fieldName, 'LESS_THAN', max);
    }
    return this;
  }

  SelectorBuilder sortBy(String fieldName, {bool descending = false}) {
    _query.order = [
      datastore_api.PropertyOrder(
        direction: descending ? 'DESCENDING' : 'ASCENDING',
        property: datastore_api.PropertyReference(
          name: fieldName,
        ),
      ),
    ];
    return this;
  }

  @Deprecated('Not yet implemented')
  SelectorBuilder sortByMetaTextScore(String fieldName) {
    return this;
  }

  @Deprecated('Not yet implemented')
  SelectorBuilder hint(String fieldName, {bool descending = false}) {
    return this;
  }

  @Deprecated('Not yet implemented')
  SelectorBuilder hintIndex(String indexName) {
    return this;
  }

  @Deprecated('Not yet implemented')
  SelectorBuilder comment(String commentStr) {
    return this;
  }

  @Deprecated('Not yet implemented')
  SelectorBuilder explain() {
    return this;
  }

  @Deprecated('Not yet implemented')
  SelectorBuilder snapshot() {
    return this;
  }

  @Deprecated('Not yet implemented')
  SelectorBuilder showDiskLoc() {
    return this;
  }

  @Deprecated('Not yet implemented')
  SelectorBuilder returnKey() {
    return this;
  }

  @Deprecated('Not yet implemented')
  SelectorBuilder jsQuery(String javaScriptCode) {
    return this;
  }

  @Deprecated('Not yet implemented')
  SelectorBuilder metaTextScore(String fieldName) {
    return this;
  }

  /// The projection to return.
  ///
  /// Defaults to returning all properties.
  SelectorBuilder fields(List<String> fields) {
    _query.projection = [
      for (final field in fields)
        datastore_api.Projection(
          property: datastore_api.PropertyReference(
            name: field,
          ),
        ),
    ];
    return this;
  }

  @Deprecated('Not yet implemented')
  SelectorBuilder excludeFields(List<String> fields) {
    return this;
  }

  /// The maximum number of results to return.
  ///
  /// Applies after all other constraints. Optional. Unspecified is interpreted
  /// as no limit. Must be \>= 0 if specified.
  SelectorBuilder limit(int limit) {
    _query.limit = limit;
    return this;
  }

  /// The number of results to skip.
  ///
  /// Applies before limit, but after all other constraints. Optional. Must be
  /// \>= 0 if specified.
  SelectorBuilder offset(int offset) {
    _query.offset = offset;
    return this;
  }

  /// The number of results to skip.
  ///
  /// Applies before limit, but after all other constraints. Optional. Must be
  /// \>= 0 if specified.
  SelectorBuilder skip(int skip) {
    _query.offset = skip;
    return this;
  }

  @Deprecated('Not yet implemented')
  SelectorBuilder raw(Map<String, dynamic> rawSelector) {
    return this;
  }

  @Deprecated('Not yet implemented')
  SelectorBuilder within(String fieldName, value) {
    return this;
  }

  @Deprecated('Not yet implemented')
  SelectorBuilder near(String fieldName, var value, [double? maxDistance]) {
    return this;
  }

  @Deprecated('Not yet implemented')
  SelectorBuilder geoWithin(String fieldName, dynamic shape) {
    return this;
  }

  @Deprecated('Not yet implemented')
  SelectorBuilder nearSphere(String fieldName, dynamic point,
      {double? maxDistance, double? minDistance}) {
    return this;
  }

  @Deprecated('Not yet implemented')
  SelectorBuilder geoIntersects(String fieldName, dynamic coordinate) {
    return this;
  }

  /// Combine current expression with expression in parameter.
  /// [SelectorBuilder] can chain queries together so these two expression will produce
  /// identical queries:
  ///
  ///     where.eq('price', 1.99).lt('qty', 20).eq('sale', true);
  ///     where.eq('price', 1.99).and(where.lt('qty',20)).and(where.eq('sale', true))
  ///
  /// Both these queries would result in identical query.
  SelectorBuilder and(SelectorBuilder other) {
    final List<datastore_api.PropertyFilter> filters =
        (_query.filter?.compositeFilter?.filters ?? [])
            .where((e) => e.propertyFilter != null)
            .map((e) => e.propertyFilter!)
            .toList();
    if (filters.isEmpty) {
      throw StateError('`And` operation is not supported on empty query');
    }
    filters.forEach(_addPropertyFilterRaw);
    return this;
  }

  /// Combine current expression with expression in parameter by logical operator **OR**.
  /// [See MongoDB doc](http://docs.mongodb.org/manual/reference/operator/and/#op._S_or)
  /// For example
  ///    inventory.find(where.eq('price', 1.99).and(where.lt('qty',20).or(where.eq('sale', true))));
  ///
  /// This query will select all documents in the inventory collection where:
  /// * the **price** field value equals 1.99 and
  /// * either the **qty** field value is less than 20 or the **sale** field value is true
  /// MongoDB json query from this expression would be
  ///      {'\$query': {'\$and': [{'price':1.99}, {'\$or': [{'qty': {'\$lt': 20 }}, {'sale': true }]}]}}
  @Deprecated('Not yet implemented')
  SelectorBuilder or(SelectorBuilder other) {
    return this;
  }
}
