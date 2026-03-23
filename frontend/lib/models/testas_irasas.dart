class TestasIrasas {
  final int id;
  final int testasId;
  final int irasasId;
  final int eile;

  TestasIrasas({
    required this.id,
    required this.testasId,
    required this.irasasId,
    required this.eile,
  });

  factory TestasIrasas.fromJson(Map<String, dynamic> j) => TestasIrasas(
        id: j['id'] as int,
        testasId: (j['testasid'] ?? j['testasId'] ?? 0) as int,
        irasasId: (j['irasasid'] ?? j['irasasId'] ?? 0) as int,
      eile: (j['eile'] ?? 0) as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'testasid': testasId,
        'irasasid': irasasId,
      'eile': eile,
      };
}
