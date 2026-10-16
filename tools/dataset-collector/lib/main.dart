import 'package:flutter/material.dart';

import 'capture_screen.dart';
import 'drive_backup.dart';
import 'store.dart';

void main() => runApp(const CollectorApp());

class CollectorApp extends StatelessWidget {
  const CollectorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'SmileScan Collector', theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal), home: const SetupScreen());
  }
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _id = TextEditingController();
  final _usia = TextEditingController();
  String? _driveEmail;

  @override
  void initState() {
    super.initState();
    DriveBackup.ensureInit().then((_) {
      if (mounted) setState(() => _driveEmail = DriveBackup.account?.email);
    });
  }

  @override
  void dispose() {
    _id.dispose();
    _usia.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmileScan Collector')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text('SOP singkat: kunci 3:4 portrait, zoom 1x, flash mati.\n'
                  'Penuhi kotak hijau, 5 posisi: Frontal/Kanan/Kiri/Atas/Bawah.\n'
                  'Salin via USB tiap akhir sesi.'),
            ),
          ),
          TextField(controller: _id, decoration: const InputDecoration(labelText: 'ID anak (misal A012)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _usia, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Usia (tahun)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: Text(_driveEmail ?? 'Drive: belum login'),
              trailing: _driveEmail == null
                  ? FilledButton.tonal(
                      onPressed: () async {
                        final acc = await DriveBackup.signIn();
                        setState(() => _driveEmail = acc.email);
                      },
                      child: const Text('Login'),
                    )
                  : TextButton(
                      onPressed: () async {
                        await DriveBackup.signOut();
                        setState(() => _driveEmail = null);
                      },
                      child: const Text('Keluar'),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              if (_id.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID anak wajib diisi')));
                return;
              }
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => CaptureScreen(session: Session(_id.text.trim(), _usia.text.trim()))));
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Mulai sesi foto'),
          ),
        ],
      ),
    );
  }
}
