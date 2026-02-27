class Testas {
  final int id;
  String testotekstas;
  String? tipas;

  Testas({
    required this.id,
    required this.testotekstas,
    this.tipas,
  });

  factory Testas.fromJson(Map<String, dynamic> j) {
    final raw = j['tipas'];
    String? tip;
    if (raw == null) {
      tip = null;
    } else if (raw is String) {
      // sometimes backend may send numeric string like "0"
      final n = int.tryParse(raw);
      if (n != null) {
        tip = _mapIndexToName(n);
      } else {
        tip = raw;
      }
    } else if (raw is int) {
      tip = _mapIndexToName(raw);
    } else {
      tip = raw.toString();
    }

    return Testas(
      id: j['id'] as int,
      testotekstas: j['testotekstas'] ?? j['testotekstas'] ?? '',
      tipas: tip,
    );
  }

  static String _mapIndexToName(int i) {
    switch (i) {
      case 0:
        return 'Testas';
      case 1:
        return 'Isvezimas';
      case 2:
        return 'Pakavimas';
      default:
        return i.toString();
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'testotekstas': testotekstas,
        'tipas': tipas,
      };
}
