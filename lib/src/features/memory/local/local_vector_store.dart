import '../../../../objectbox.g.dart';
import 'memory_entity.dart';

/// On-device vector store (ObjectBox HNSW). Provides offline nearest-neighbor
/// (semantic) retrieval over locally-stored memory embeddings — no cloud
/// round-trip for search. This is the "local vector DB for offline retrieval"
/// seam from the architecture plan; the cloud embedding path stays as a quality
/// boost for the query vector.
class LocalVectorStore {
  LocalVectorStore._(this._store) : _box = _store.box<MemoryEntity>();

  final Store _store;
  final Box<MemoryEntity> _box;

  static LocalVectorStore? _instance;

  /// Opens (once) the on-device store in the app's data directory.
  static Future<LocalVectorStore> open() async {
    final existing = _instance;
    if (existing != null) return existing;
    final store = await openStore();
    return _instance = LocalVectorStore._(store);
  }

  int get count => _box.count();

  int upsert(MemoryEntity entity) => _box.put(entity);

  void putMany(List<MemoryEntity> entities) => _box.putMany(entities);

  void clear() => _box.removeAll();

  /// Returns the [k] memories whose embeddings are nearest to [query],
  /// computed entirely on-device.
  List<MemoryEntity> nearest(List<double> query, {int k = 20}) {
    if (query.isEmpty) return const [];
    final built = _box
        .query(MemoryEntity_.embedding.nearestNeighborsF32(query, k))
        .build();
    try {
      return built
          .findWithScores()
          .map((scored) => scored.object)
          .toList(growable: false);
    } finally {
      built.close();
    }
  }

  void close() {
    _store.close();
    _instance = null;
  }
}
