import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'drive_backup.dart';
import 'store.dart';

class CaptureScreen extends StatefulWidget {
  final Session session;
  const CaptureScreen({super.key, required this.session});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  CameraController? _ctl;
  String _posisi = positions.first;
  String _status = 'Menyiapkan kamera…';
  String? _lastFile;
  Directory? _dir;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _dir = await subjectDir(widget.session.subjectId);
      final cams = await availableCameras();
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      // Kunci: zoom 1x, flash mati, rasio dijaga 3:4 via crop preview.
      _ctl = CameraController(back, ResolutionPreset.high, enableAudio: false);
      await _ctl!.initialize();
      await _ctl!.setFlashMode(FlashMode.off);
      await _ctl!.setZoomLevel(1.0);
      setState(() => _status = 'Siap — penuhi kotak panduan');
    } catch (e) {
      setState(() => _status = 'Kamera gagal: $e');
    }
  }

  @override
  void dispose() {
    _ctl?.dispose();
    super.dispose();
  }

  Future<void> _shutter() async {
    if (_ctl == null || !_ctl!.value.isInitialized || _busy) return;
    setState(() {
      _busy = true;
      _status = 'Menyimpan…';
    });
    try {
      final shot = await _ctl!.takePicture();
      final dest = await nextFile(_dir!, widget.session.subjectId, _posisi);
      await File(shot.path).copy(dest.path);
      await appendCsv(_dir!, [
        dest.path.split(Platform.pathSeparator).last,
        widget.session.subjectId,
        widget.session.usia,
        _posisi,
        DateTime.now().toIso8601String(),
        Platform.operatingSystem,
      ]);
      setState(() {
        _lastFile = dest.path.split(Platform.pathSeparator).last;
        _status = 'Tersimpan: $_lastFile';
      });
    } catch (e) {
      setState(() => _status = 'Gagal simpan: $e');
      // shortcut: auto blur/gelap check belum ada, konfirmasi manual via preview ulang — upgrade saat uji lapangan butuh.
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctl = _ctl;
    return Scaffold(
      appBar: AppBar(title: Text('ID ${widget.session.subjectId}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: DropdownButtonFormField<String>(
              initialValue: _posisi,
              items: [for (final p in positions) DropdownMenuItem(value: p, child: Text(p))],
              onChanged: (v) => setState(() => _posisi = v!),
              decoration: const InputDecoration(labelText: 'Posisi foto', border: OutlineInputBorder()),
            ),
          ),
          Expanded(
            child: Center(
              child: ctl == null || !ctl.value.isInitialized
                  ? Text(_status)
                  : AspectRatio(
                      aspectRatio: 3 / 4, // kunci portrait 3:4 untuk semua posisi
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRect(
                            child: FittedBox(fit: BoxFit.cover, child: SizedBox(width: ctl.value.previewSize!.height, height: ctl.value.previewSize!.width, child: CameraPreview(ctl))),
                          ),
                          const _GuideOverlay(),
                        ],
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(_status, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(onPressed: _busy ? null : _shutter, icon: const Icon(Icons.camera_alt), label: const Text('Ambil')),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _FileList(dir: _dir!))),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('File'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Kotak panduan mulut + grid agar jarak/framing konsisten.
class _GuideOverlay extends StatelessWidget {
  const _GuideOverlay();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GuidePainter());
  }
}

class _GuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 2;
    // grid 3x3
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(Offset(size.width * i / 3, 0), Offset(size.width * i / 3, size.height), line);
      canvas.drawLine(Offset(0, size.height * i / 3), Offset(size.width, size.height * i / 3), line);
    }
    // kotak mulut di tengah
    final box = Rect.fromCenter(center: size.center(Offset.zero), width: size.width * 0.8, height: size.height * 0.32);
    canvas.drawRect(box, Paint()..color = const Color(0xFF4CAF50)..strokeWidth = 3..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _FileList extends StatelessWidget {
  final Directory dir;
  const _FileList({required this.dir});

  Future<void> _backup(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Mengupload ke Drive…')));
    try {
      final n = await DriveBackup.uploadSessionDir(dir, dir.path.split(Platform.pathSeparator).last,
          log: (m) => messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(m))));
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Selesai: $n file terupload')));
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Backup gagal: $e — login Drive dulu di layar utama')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File sesi ini'), actions: [IconButton(icon: const Icon(Icons.cloud_upload_outlined), tooltip: 'Backup ke Drive', onPressed: () => _backup(context))]),
      body: FutureBuilder(
        future: dir.list().toList(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final jpgs = snap.data!.where((e) => e.path.endsWith('.jpg')).toList();
          return ListView(
            children: [
              ListTile(title: Text(dir.path), subtitle: const Text('Salin via USB tiap akhir sesi')),
              for (final f in jpgs)
                ListTile(
                  title: Text(f.path.split(Platform.pathSeparator).last),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await File(f.path).delete();
                      (ctx as Element).markNeedsBuild();
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
