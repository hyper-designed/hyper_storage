import 'dart:convert';

import 'api/serializable_container.dart';

typedef FromJson<E> = E Function(Map<String, dynamic> json);
typedef ToJson<E> = Map<String, dynamic> Function(E object);

final class JsonStorageContainer<T> extends SerializableStorageContainer<T> {
  final ToJson<T> toJson;
  final FromJson<T> fromJson;

  JsonStorageContainer({
    required super.backend,
    required this.toJson,
    required this.fromJson,
    super.idGetter,
    required super.name,
    super.random,
    super.delimiter,
    super.seed,
  });

  @override
  T deserialize(String value) => fromJson(jsonDecode(value));

  @override
  String serialize(T value) => jsonEncode(toJson(value));
}
