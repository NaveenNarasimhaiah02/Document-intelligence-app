import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/document.dart';

class StorageService {
  static const String docsBoxName = 'documentsBoxEncrypted';
  static const String settingsBoxName = 'settingsBox';
  static const String keyBoxName = 'securityBox';

  late Box _docsBox;
  late Box _settingsBox;
  final _secureStorage = const FlutterSecureStorage();

  Future<void> init() async {
    await Hive.initFlutter();
    
    // SEC-03: Retrieve or generate encryption key using system Secure Storage
    final encodedKey = await _secureStorage.read(key: 'encryptionKey');
    List<int>? encryptionKey;

    if (encodedKey != null) {
      encryptionKey = base64Url.decode(encodedKey);
    } else {
      // Check legacy storage for migration
      final keyBox = await Hive.openBox(keyBoxName);
      final legacyKey = keyBox.get('encryptionKey')?.cast<int>();
      
      if (legacyKey != null) {
        encryptionKey = legacyKey;
        await _secureStorage.write(key: 'encryptionKey', value: base64Url.encode(encryptionKey!));
        await keyBox.clear(); // Clear legacy key
      } else {
        final newKey = Hive.generateSecureKey();
        encryptionKey = newKey;
        await _secureStorage.write(key: 'encryptionKey', value: base64Url.encode(newKey));
      }
      await keyBox.close();
    }

    _docsBox = await Hive.openBox(docsBoxName, encryptionCipher: HiveAesCipher(encryptionKey!));
    _settingsBox = await Hive.openBox(settingsBoxName);
    
    // Migration: Move data from old unencrypted box if it exists
    if (await Hive.boxExists('documentsBox')) {
      final oldBox = await Hive.openBox('documentsBox');
      if (oldBox.isNotEmpty && _docsBox.isEmpty) {
        for (var key in oldBox.keys) {
          await _docsBox.put(key, oldBox.get(key));
        }
      }
      await oldBox.deleteFromDisk(); // Permanently remove old insecure storage
    }
  }

  Box get settingsBox => _settingsBox;

  List<DocumentModel>? _cachedDocs;

  List<DocumentModel> getAllDocuments() {
    if (_cachedDocs != null) return _cachedDocs!;
    
    final raw = <DocumentModel>[];
    for (final e in _docsBox.values) {
      try {
        raw.add(DocumentModel.fromMap(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    raw.sort((a, b) => b.id.compareTo(a.id));
    _cachedDocs = raw;
    return raw;
  }

  Future<void> saveDocument(DocumentModel doc) async {
    await _docsBox.put(doc.id, doc.toMap());
    _cachedDocs = null;
  }

  Future<void> deleteDocument(String id) async {
    final docMap = _docsBox.get(id);
    if (docMap != null) {
      final doc = DocumentModel.fromMap(Map<String, dynamic>.from(docMap));
      final file = File(doc.imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _docsBox.delete(id);
    _cachedDocs = null;
  }

  Future<String> persistImage(File tempFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}${tempFile.path.substring(tempFile.path.lastIndexOf('.'))}';
    final permanentFile = await tempFile.copy('${appDir.path}/$fileName');
    return permanentFile.path;
  }

  Future<void> clearAll() async {
    for (var docMap in _docsBox.values) {
      final doc = DocumentModel.fromMap(Map<String, dynamic>.from(docMap));
      final file = File(doc.imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _docsBox.clear();
    _cachedDocs = null;
  }

  Future<String> calculateChecksum(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  DocumentModel? findDocumentByChecksum(String checksum) {
    final docs = getAllDocuments();
    for (final doc in docs) {
      if (doc.checksum == checksum) return doc;
    }
    return null;
  }
}
