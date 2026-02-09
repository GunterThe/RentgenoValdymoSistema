class Testas {
  final int id;
  String testotekstas;

  Testas({required this.id, required this.testotekstas});

  factory Testas.fromJson(Map<String, dynamic> j) => Testas(
    id: j['id'] as int,
    testotekstas: j['testotekstas'] ?? j['Testotekstas'] ?? '',
  );

  Map<String, dynamic> toJson() => {'id': id, 'testotekstas': testotekstas};
}
