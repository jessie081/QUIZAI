import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

enum AppConnectionStatus {
  online,
  offline,
}

class ConnectivityService {
  ConnectivityService([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<AppConnectionStatus> checkStatus() async {
    final results = await _connectivity.checkConnectivity();
    return _mapResults(results);
  }

  Stream<AppConnectionStatus> watchStatus() async* {
    yield await checkStatus();

    await for (final results in _connectivity.onConnectivityChanged) {
      yield _mapResults(results);
    }
  }

  AppConnectionStatus _mapResults(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return AppConnectionStatus.offline;
    }

    return AppConnectionStatus.online;
  }
}
