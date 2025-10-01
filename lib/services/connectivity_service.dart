import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  ConnectivityService() {
    // Sempre escuta mudanças e emite true/false
    _connectivity.onConnectivityChanged.listen((event) {
      bool online = event != ConnectivityResult.none;
      _controller.add(online);
    });

    // Faz uma checagem inicial (quando app abre)
    temConexao().then((online) => _controller.add(online));
  }

  Stream<bool> get statusConexao => _controller.stream;

  Future<bool> temConexao() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
