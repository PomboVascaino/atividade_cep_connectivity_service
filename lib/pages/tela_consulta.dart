import 'package:flutter/material.dart';
import '../models/endereco.dart';
import '../services/cache_service.dart';
import '../services/connectivity_service.dart';
import '../services/via_cep_service.dart';

class TelaConsultaCep extends StatefulWidget {
  const TelaConsultaCep({super.key});

  @override
  State<TelaConsultaCep> createState() => _TelaConsultaCepState();
}

class _TelaConsultaCepState extends State<TelaConsultaCep> {
  final _controller = TextEditingController();
  final _cache = CacheService();
  late ViaCepService _viaCepService;
  late ConnectivityService _connectivityService;

  String _statusConexao = "Desconhecido";
  bool _offline = false;
  Endereco? _endereco;
  String? _fonte;
  List<String> _historico = [];

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _viaCepService = ViaCepService(
      connectivity: _connectivityService,
      cache: _cache,
    );

    _connectivityService.statusConexao.listen((online) {
      setState(() {
        _offline = !online;
        _statusConexao = online ? "Online" : "Offline";
      });
    });

    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    final ceps = await _cache.listarCepsConsultados();
    setState(() {
      _historico = ceps;
    });
  }

  Future<void> _buscarCep(String cep) async {
    try {
      final resultado = await _viaCepService.buscarCep(cep);
      setState(() {
        _endereco = resultado["endereco"];
        _fonte = resultado["fonte"];
      });
      _carregarHistorico();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Consulta de CEP")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_offline)
              Container(
                color: Colors.orange,
                padding: const EdgeInsets.all(8),
                child: const Text(
                  "Você está offline",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            Row(
              children: [
                Icon(_offline ? Icons.wifi_off : Icons.wifi,
                    color: _offline ? Colors.red : Colors.green),
                const SizedBox(width: 8),
                Text("Status: $_statusConexao"),
              ],
            ),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: "Digite o CEP",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _buscarCep(_controller.text),
              child: const Text("Buscar CEP"),
            ),
            const SizedBox(height: 16),
            if (_endereco != null)
              Card(
                child: ListTile(
                  title: Text(
                      "${_endereco!.logradouro}, ${_endereco!.bairro}, ${_endereco!.localidade} - ${_endereco!.uf}"),
                  subtitle: Text("CEP: ${_endereco!.cep}"),
                  trailing: Chip(label: Text(_fonte ?? "")),
                ),
              ),
            const Divider(),
            Wrap(
              spacing: 8,
              children: _historico
                  .map((cep) => ActionChip(
                        label: Text(cep),
                        onPressed: () => _buscarCep(cep),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                await _cache.limparCache();
                _carregarHistorico();
              },
              child: const Text("Limpar histórico"),
            ),
          ],
        ),
      ),
    );
  }
}
