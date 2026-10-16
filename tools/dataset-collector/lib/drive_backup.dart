import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

const driveRootName = 'SmileScan'; // folder root di Drive peneliti
const _scope = drive.DriveApi.driveFileScope; // hanya file buatan app ini

class _AuthClient extends http.BaseClient {
  final Map<String, String> headers;
  final http.Client _inner = http.Client();
  _AuthClient(this.headers);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest req) {
    req.headers.addAll(headers);
    return _inner.send(req);
  }
}

class DriveBackup {
  static bool _inited = false;
  static GoogleSignInAccount? account;

  static Future<void> ensureInit() async {
    if (_inited) return;
    await GoogleSignIn.instance.initialize();
    account = await GoogleSignIn.instance.attemptLightweightAuthentication();
    _inited = true;
  }

  static Future<GoogleSignInAccount> signIn() async {
    await ensureInit();
    account = await GoogleSignIn.instance.authenticate();
    return account!;
  }

  static Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    account = null;
  }

  static Future<drive.DriveApi?> _api({bool prompt = false}) async {
    await ensureInit();
    final acc = account;
    if (acc == null) return null;
    final headers = await acc.authorizationClient.authorizationHeaders([_scope], promptIfNecessary: prompt);
    if (headers == null) return null;
    return drive.DriveApi(_AuthClient(headers));
  }

  static Future<String> _folder(drive.DriveApi api, String name, {String? parent}) async {
    var q = "mimeType='application/vnd.google-apps.folder' and name='$name' and trashed=false";
    if (parent != null) q += " and '$parent' in parents";
    final found = await api.files.list(q: q, $fields: 'files(id)');
    if (found.files?.isNotEmpty == true) return found.files!.first.id!;
    final created = await api.files.create(
      drive.File(name: name, mimeType: 'application/vnd.google-apps.folder', parents: parent == null ? null : [parent]),
    );
    return created.id!;
  }

  /// Upload foto yang belum ada (cocokkan nama) + timpa metadata.csv terbaru.
  /// Mengembalikan jumlah file yang diupload. Gagal jika belum login.
  static Future<int> uploadSessionDir(Directory localDir, String subjectId, {void Function(String)? log}) async {
    final api = await _api(prompt: true);
    if (api == null) throw StateError('Belum login Google');
    final rootId = await _folder(api, driveRootName);
    final subId = await _folder(api, subjectId, parent: rootId);
    final existing = await api.files.list(q: "'$subId' in parents and trashed=false", $fields: 'files(id,name)');
    final names = {for (final f in existing.files ?? []) f.name!: f.id!};

    int uploaded = 0;
    await for (final e in localDir.list()) {
      final name = e.path.split('/').last;
      if (!name.endsWith('.jpg') && name != 'metadata.csv') continue;
      if (name == 'metadata.csv' && names.containsKey(name)) {
        await api.files.delete(names[name]!); // timpa agar csv di Drive selalu terbaru
      } else if (names.containsKey(name)) {
        continue; // foto sama sudah ada, skip hemat kuota
      }
      final file = File(e.path);
      final len = await file.length();
      await api.files.create(
        drive.File(name: name, parents: [subId]),
        uploadMedia: drive.Media(file.openRead(), len),
      );
      uploaded++;
      log?.call('Upload $uploaded: $name');
    }
    return uploaded;
  }
}
