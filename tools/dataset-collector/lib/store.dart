import 'dart:io';

import 'package:path_provider/path_provider.dart';

const positions = ['Frontal', 'Kanan', 'Kiri', 'Atas', 'Bawah'];

class Session {
  final String subjectId;
  final String usia;
  Session(this.subjectId, this.usia);
}

String todayStamp() {
  final n = DateTime.now();
  String p(int v) => v.toString().padLeft(2, '0');
  return '${n.year}${p(n.month)}${p(n.day)}';
}

Future<Directory> subjectDir(String subjectId) async {
  final base = await getExternalStorageDirectory();
  final dir = Directory('${base!.path}/SmileScan/$subjectId');
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}

// Nama: ID_TGL_Posisi_Urut.jpg, urut = jumlah file posisi tsb + 1
Future<File> nextFile(Directory dir, String id, String posisi) async {
  final tgl = todayStamp();
  int n = 0;
  await for (final e in dir.list()) {
    final name = e.path.split(Platform.pathSeparator).last;
    if (name.startsWith('${id}_${tgl}_$posisi')) n++;
  }
  return File('${dir.path}/${id}_${tgl}_${posisi}_${(n + 1).toString().padLeft(2, '0')}.jpg');
}

Future<void> appendCsv(Directory dir, List<String> row) async {
  final csv = File('${dir.path}/metadata.csv');
  if (!await csv.exists()) {
    await csv.writeAsString('filename,subject_id,usia,posisi,timestamp,hp\n');
  }
  await csv.writeAsString('${row.join(',')}\n', mode: FileMode.append);
}
