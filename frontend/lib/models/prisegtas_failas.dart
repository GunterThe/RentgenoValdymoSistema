class PrisegtasFailas {
  final String id; // Guid
  final int? irasasId;
  final String fileName;
  final int? size;
  final String? link;
  final DateTime? createdAt;

  PrisegtasFailas({
    required this.id,
    required this.irasasId,
    required this.fileName,
    required this.size,
    required this.link,
    required this.createdAt,
  });

  factory PrisegtasFailas.fromJson(Map<String, dynamic> j) {
    final rawCreated = j['sukurimoLaikas'] ?? j['SukurimoLaikas'];

    return PrisegtasFailas(
      id: (j['id'] ?? j['Id']).toString(),
      irasasId: (j['irasasid'] ?? j['irasasId'] ?? j['Irasasid']) as int?,
      fileName: (j['failoPav'] ?? j['failopav'] ?? j['FailoPav'] ?? '')
          .toString(),
      size: (j['dydis'] ?? j['Dydis']) as int?,
      link: (j['nuoroda'] ?? j['Nuoroda'])?.toString(),
      createdAt:
          rawCreated == null ? null : DateTime.tryParse(rawCreated.toString()),
    );
  }
}
