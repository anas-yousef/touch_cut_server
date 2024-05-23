import 'dart:convert';
import 'dart:io';

import 'package:supabase/supabase.dart';

class FileStorage implements GotrueAsyncStorage {
  FileStorage(String path) : file = File(path);
  final File file;

  @override
  Future<void> removeItem({required String key}) async {
    final json = await _readJson();
    json.remove(key);
    await _writeJson(json);
  }

  @override
  Future<String?> getItem({required String key}) async {
    final json = await _readJson();
    return json[key] as String?;
  }

  @override
  Future<void> setItem({
    required String key,
    required String value,
  }) async {
    final json = await _readJson();
    json[key] = value;
    await _writeJson(json);
  }

  Future<Map<String, dynamic>> _readJson() async {
    if (!await file.exists()) {
      return {};
    }
    final contents = await file.readAsString();
    return jsonDecode(contents) as Map<String, dynamic>;
  }

  Future<void> _writeJson(Map<String, dynamic> json) async {
    await file.writeAsString(jsonEncode(json));
  }
}
