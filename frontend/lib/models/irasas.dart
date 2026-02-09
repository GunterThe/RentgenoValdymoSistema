class Irasas {
  final int id;
  String idDokumento;
  String pavadinimas;
  DateTime pradzia;
  DateTime pabaiga;

  Irasas({
    required this.id,
    required this.idDokumento,
    required this.pavadinimas,
    required this.pradzia,
    required this.pabaiga,
  });

  factory Irasas.fromJson(Map<String, dynamic> j) => Irasas(
        id: j['id'] as int,
        idDokumento: j['idDokumento'] ?? j['id_dokumento'] ?? '',
        pavadinimas: j['pavadinimas'] ?? j['Pavadinimas'] ?? '',
        pradzia: DateTime.parse(
          j['pradzia'] ?? j['Pradzia'] ?? DateTime.now().toIso8601String(),
        ),
        pabaiga: DateTime.parse(
          j['pabaiga'] ?? j['Pabaiga'] ?? DateTime.now().toIso8601String(),
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'idDokumento': idDokumento,
        'pavadinimas': pavadinimas,
        'pradzia': pradzia.toIso8601String(),
        'pabaiga': pabaiga.toIso8601String(),
      };
}
