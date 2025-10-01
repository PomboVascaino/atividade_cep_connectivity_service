import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/endereco.dart';

class CacheService {
  static const String _key = 'cache_ceps';

  Future<void> salvarEndereco(String cep, Endereco endereco) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    Map<String, dynamic> cache = data != null ? jsonDecode(data) : {};
    cache[cep] = endereco.toJson();
    await prefs.setString(_key, jsonEncode(cache));
  }

  Future<Endereco?> buscarEndereco(String cep) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return null;
    final cache = jsonDecode(data) as Map<String, dynamic>;
    if (!cache.containsKey(cep)) return null;
    return Endereco.fromJson(cache[cep]);
  }

  Future<List<String>> listarCepsConsultados() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];
    final cache = jsonDecode(data) as Map<String, dynamic>;
    return cache.keys.toList();
  }

  Future<void> limparCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
