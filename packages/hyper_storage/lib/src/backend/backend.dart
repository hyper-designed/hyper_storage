import '../container/storage_container.dart';
import 'api.dart';

/// Base class for local storage implementations.
abstract class StorageBackend implements DataAPI {
  Future<void> init();

  Future<HyperStorageContainer> container(String name);
}
