import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> temConexao() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Stream<bool> get statusConexao async* {
    yield await temConexao();
    yield* _connectivity.onConnectivityChanged.map(
      (event) => event != ConnectivityResult.none,
    );
  }
}
