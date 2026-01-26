import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

enum ConnectionStateStatus { checking, online, offline }

@singleton
class ConnectivityService {
  static ConnectivityService? instance;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final StreamController<ConnectionStateStatus> _statusController =
      StreamController<ConnectionStateStatus>.broadcast();

  ConnectionStateStatus _status = ConnectionStateStatus.checking;
  ConnectionStateStatus get status => _status;
  Stream<ConnectionStateStatus> get statusStream => _statusController.stream;
  bool get isOnline => _status == ConnectionStateStatus.online;

  ConnectivityService() {
    instance ??= this;
    _init();
  }

  Future<void> _init() async {
    await _checkAndUpdate();
    _subscription = _connectivity.onConnectivityChanged.listen((_) async {
      await _checkAndUpdate();
    });
  }

  Future<void> _checkAndUpdate() async {
    _setStatus(ConnectionStateStatus.checking);
    // Avoid DNS/HTTP calls that may be blocked in restricted environments; rely
    // on connectivity signal to prevent false offline states at startup.
    final results = await _connectivity.checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    _setStatus(hasConnection ? ConnectionStateStatus.online : ConnectionStateStatus.offline);
  }

  Future<void> recheck() async {
    await _checkAndUpdate();
  }

  void markOffline() {
    _setStatus(ConnectionStateStatus.offline);
  }

  void _setStatus(ConnectionStateStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    _statusController.add(newStatus);
  }

  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}
