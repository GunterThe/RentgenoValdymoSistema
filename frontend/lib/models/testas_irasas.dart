class TestasIrasas {
  final int testasid;
  final int irasasid;
  bool atliktas;

  TestasIrasas({
    required this.testasid,
    required this.irasasid,
    required this.atliktas,
  });

  factory TestasIrasas.fromJson(Map<String, dynamic> j) => TestasIrasas(
    testasid: (j['testasid'] ?? j['Testasid']) as int,
    irasasid: (j['irasasid'] ?? j['Irasasid']) as int,
    atliktas: (j['atliktas'] ?? j['Atliktas'] ?? false) as bool,
  );

  Map<String, dynamic> toJson() => {
    'testasid': testasid,
    'irasasid': irasasid,
    'atliktas': atliktas,
  };
}
