import 'package:objectbox/objectbox.dart';

/// On-device vector index row. Holds ONLY a non-reversible reference key and the
/// HNSW-indexed embedding — never the sensitive memory text. The plaintext stays
/// in the encrypted blob store; [refKey] maps a nearest-neighbor hit back to it.
@Entity()
class MemoryEntity {
  MemoryEntity({
    this.id = 0,
    required this.refKey,
    required this.embedding,
  });

  @Id()
  int id;

  @Index()
  String refKey;

  @HnswIndex(dimensions: 1536)
  @Property(type: PropertyType.floatVector)
  List<double> embedding;
}
