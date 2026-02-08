import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rentgeno Valdymas',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey, brightness: Brightness.dark),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  void _showPlaceholder(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title - dar neįgyvendinta')),
    );
  }

  Widget _buildActionCard(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagrindinis'),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        actions: [
          IconButton(
            tooltip: 'Paskyra',
            onPressed: () => _showPlaceholder(context, 'Paskyra'),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: 'Atsijungti',
            onPressed: () => _showPlaceholder(context, 'Atsijungti'),
            icon: const Icon(Icons.logout),
          ),
          IconButton(
            tooltip: 'Testai',
            onPressed: () => _showPlaceholder(context, 'Testai'),
            icon: const Icon(Icons.list_alt),
          ),
          IconButton(
            tooltip: 'Supakavimas',
            onPressed: () => _showPlaceholder(context, 'Supakavimas'),
            icon: const Icon(Icons.inventory_2_outlined),
          ),
          IconButton(
              tooltip: 'Isvezimas',
              onPressed: () => _showPlaceholder(context, 'Isvezimas'),
              icon: const Icon(Icons.local_shipping_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _showPlaceholder(context, 'Peržiūrėti įrašus '),
                          icon: const Icon(Icons.add_road),
                          label: const Text('Peržiūrėti įrašus'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          onPressed: () => _showPlaceholder(context, 'Peržiūrėti testus'),
                          icon: const Icon(Icons.science_outlined),
                          label: const Text('Peržiūrėti testus'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPlaceholder(context, 'Testai (greita)'),
        child: const Icon(Icons.playlist_add),
      ),
    );
  }
}
