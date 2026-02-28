class PrisegtasFailas {
  final String id;
  final int? zingsnisId;
  final String? failoPav;
  final int? dydis;
  final DateTime? sukurimoLaikas;

  PrisegtasFailas({
    required this.id,
    required this.zingsnisId,
    required this.failoPav,
    required this.dydis,
    required this.sukurimoLaikas,
  });

  factory PrisegtasFailas.fromJson(Map<String, dynamic> j) {
    final rawTime = j['sukurimoLaikas'] ?? j['sukurimolaikas'];
    DateTime? created;
    if (rawTime is String && rawTime.isNotEmpty) {
      created = DateTime.tryParse(rawTime)?.toLocal();
    }

    return PrisegtasFailas(
      id: (j['id'] ?? '').toString(),
      zingsnisId: (j['zingsnisId'] ?? j['zingsnis_id']) as int?,
      failoPav: (j['failoPav'] ?? j['failopav']) as String?,
      dydis: (j['dydis']) as int?,
      sukurimoLaikas: created,
    );
  }
}
