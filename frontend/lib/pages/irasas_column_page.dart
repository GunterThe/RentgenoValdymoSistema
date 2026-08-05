import 'package:flutter/material.dart';

import '../models/irasas.dart';
import '../widgets/app_scaffold.dart';

class IrasasColumnPage extends StatelessWidget {
  final Irasas irasas;

  const IrasasColumnPage({super.key, required this.irasas});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Peržiūrėti FAT',
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                irasas.pavadinimas,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text('Dokumento ID: ${irasas.idDokumento}'),
              const SizedBox(height: 12),
              const Text(
                'FAT stulpeliai ir reikšmės bus čia parodyti.',
              ),
              const SizedBox(height: 8),
              const Text(
                'Ši erdvė yra rezervuota `Peržiūėti FAT` funkcijai — implementuokite atitinkamą UI ir API kvietimus pagal poreikį.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
