class Irasas {
  final int id;
  String idDokumento;
  String pavadinimas;
  DateTime pradzia;
  DateTime? pabaiga;

  Irasas({
    required this.id,
    required this.idDokumento,
    required this.pavadinimas,
    required this.pradzia,
    this.pabaiga,
  });

  factory Irasas.fromJson(Map<String, dynamic> j) => Irasas(
        id: j['id'] as int,
        idDokumento: j['idDokumento'] ?? j['id_dokumento'] ?? '',
        pavadinimas: j['pavadinimas'] ?? j['Pavadinimas'] ?? '',
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
        'pabaiga': pabaiga == null ? null : pabaiga!.toUtc().toIso8601String(),
      };
}
