class Irasas {
  final int id;
  String idDokumento;
  String pavadinimas;
  DateTime pradzia;
  DateTime? pabaiga;
  String statusas;
  int lokacijaId;

  Irasas({
    required this.id,
    required this.idDokumento,
    required this.pavadinimas,
    required this.pradzia,
    this.pabaiga,
    this.statusas = '',
    this.lokacijaId = 0,
  });

  factory Irasas.fromJson(Map<String, dynamic> j) => Irasas(
        id: j['id'] as int,
        idDokumento: j['idDokumento'] ?? j['id_dokumento'] ?? '',
        pavadinimas: j['pavadinimas'] ?? j['Pavadinimas'] ?? '',
      statusas: (j['statusas'] ?? j['Statusas'] ?? '') as String,
      lokacijaId: (j['lokacijaId'] ?? j['lokacija_id'] ?? 0) as int,
        pradzia: DateTime.parse(
          j['pradzia'] ?? j['Pradzia'] ?? DateTime.now().toIso8601String(),
        ).toLocal(),
        pabaiga: j['pabaiga'] == null
            ? null
            : DateTime.parse(j['pabaiga']).toLocal(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'idDokumento': idDokumento,
        'pavadinimas': pavadinimas,
        'pradzia': pradzia.toUtc().toIso8601String(),
        'pabaiga': pabaiga?.toUtc().toIso8601String(),
      'lokacijaId': lokacijaId,
      };
}
