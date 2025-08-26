import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/settings_models.dart';

class SettingsRepository {
  static const _localKey = 'search_settings_v1';
  final _db = FirebaseFirestore.instance;

  Future<SearchSettings?> loadLocal() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_localKey);
    if (raw == null) return null;
    return SearchSettings.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveLocal(SearchSettings s) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_localKey, jsonEncode(s.toMap()));
  }

  Future<SearchSettings?> loadRemote(String uid) async {
    final d = await _db.collection('users').doc(uid).collection('settings').doc('default').get();
    if (!d.exists) return null;
    return SearchSettings.fromMap(d.data()!);
  }

  Future<void> saveRemote(String uid, SearchSettings s) async {
    await _db.collection('users').doc(uid).collection('settings').doc('default').set(s.toMap(), SetOptions(merge: true));
  }
}
