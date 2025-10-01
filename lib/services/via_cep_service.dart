import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/endereco.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';

class ViaCepService {
  final ConnectivityService connectivity;
  final CacheService cache;

  ViaCepService({required this.connectivity, required this.cache});

  Future<Map<String, dynamic>> buscarCep(String cep) async {
    cep = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) {
      throw Exception("CEP inválido");
    }

    final temInternet = await connectivity.temConexao();

    if (temInternet) {
      try {
        final url = Uri.parse("https://viacep.com.br/ws/$cep/json/");
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data.containsKey("erro")) {
            throw Exception("CEP não encontrado");
          }
          final endereco = Endereco.fromJson(data);
          await cache.salvarEndereco(cep, endereco);
          return {"fonte": "API", "endereco": endereco};
        } else {
          throw Exception("Erro na API ViaCEP");
        }
      } catch (_) {
        final enderecoCache = await cache.buscarEndereco(cep);
        if (enderecoCache != null) {
          return {"fonte": "CACHE", "endereco": enderecoCache};
        }
        rethrow;
      }
    } else {
      final enderecoCache = await cache.buscarEndereco(cep);
      if (enderecoCache != null) {
        return {"fonte": "CACHE", "endereco": enderecoCache};
      } else {
        throw Exception("Sem conexão e CEP não encontrado no cache");
      }
    }
  }
}
