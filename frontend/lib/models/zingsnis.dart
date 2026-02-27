class Zingsnis {
  final int id;
  String komentaras;
  DateTime? completedAt;
  int testasIrasasId;
  int zingsnisTemplateId;
  String completedByUserId;

  Zingsnis({
    required this.id,
    required this.komentaras,
    required this.completedAt,
    required this.testasIrasasId,
    required this.zingsnisTemplateId,
    required this.completedByUserId,
  });

  factory Zingsnis.fromJson(Map<String, dynamic> j) {
    final completedRaw = j['completedAt'] ?? j['completed_at'];
    DateTime? completed;
    if (completedRaw is String && completedRaw.isNotEmpty) {
      completed = DateTime.tryParse(completedRaw)?.toLocal();
    }

    return Zingsnis(
      id: j['id'] as int,
      komentaras: (j['komentaras'] ?? '') as String,
      completedAt: completed,
      testasIrasasId:
          (j['testasIrasasId'] ?? j['irasas_testas_id'] ?? 0) as int,
      zingsnisTemplateId:
          (j['zingsnisTemplateId'] ?? j['zingsnis_template_id'] ?? 0) as int,
      completedByUserId:
          (j['completedByUserId'] ?? j['completed_by_user_id'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'komentaras': komentaras,
        'completedAt': completedAt?.toUtc().toIso8601String(),
        'testasIrasasId': testasIrasasId,
        'zingsnisTemplateId': zingsnisTemplateId,
        'completedByUserId': completedByUserId,
      };
}
