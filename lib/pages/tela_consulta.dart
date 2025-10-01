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

  final List<Color> _rainbow = const [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _viaCepService = ViaCepService(
      connectivity: _connectivityService,
      cache: _cache,
    );

    // Escuta mudanças de status da internet em tempo real
    _connectivityService.statusConexao.listen((online) {
      setState(() {
        _offline = !online;
        _statusConexao = online ? "Online 🌐" : "Offline ❌";
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
        SnackBar(
          backgroundColor: Colors.pink,
          content: Text(
            "😱 Oops: ${e.toString()}",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🌈 Consulta de CEP 🌈"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: _rainbow),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _rainbow,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 🔥 Banner de Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _offline ? Colors.redAccent : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _offline ? Icons.wifi_off : Icons.wifi,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _statusConexao,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: InputDecoration(
                  labelText: "Digite o CEP ✨",
                  labelStyle: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () => _buscarCep(_controller.text),
                child: const Text("🔍 Buscar CEP"),
              ),
              const SizedBox(height: 16),
              if (_endereco != null)
                Card(
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.house, color: Colors.deepPurple),
                    title: Text(
                      "${_endereco!.logradouro}, ${_endereco!.bairro}, ${_endereco!.localidade} - ${_endereco!.uf}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("CEP: ${_endereco!.cep}"),
                    trailing: Chip(
                      backgroundColor: Colors.greenAccent,
                      label: Text(_fonte ?? ""),
                    ),
                  ),
                ),
              const Divider(thickness: 2),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _historico
                    .map(
                      (cep) => Chip(
                        backgroundColor:
                            _rainbow[_historico.indexOf(cep) % _rainbow.length],
                        label: Text(
                          cep,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        deleteIcon:
                            const Icon(Icons.history, color: Colors.white),
                        onDeleted: () => _buscarCep(cep),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () async {
                  await _cache.limparCache();
                  _carregarHistorico();
                },
                icon: const Icon(Icons.delete_forever),
                label: const Text("Limpar histórico 🧹"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
