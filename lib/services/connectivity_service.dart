import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Lightweight service that exposes the current connectivity state
/// and a stream of changes.
///
/// • [isOnline] – `true` when at least one non-"none" connection exists.
/// • [onConnectivityChanged] – fires whenever the state flips.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService() {
    _subscription = Connectivity().onConnectivityChanged.listen(_handleChange);
  }

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _online = true;

  /// Whether the device currently has network connectivity.
  bool get isOnline => _online;

  /// One-shot check – useful at app startup before the stream fires.
  Future<bool> checkNow() async {
    final results = await Connectivity().checkConnectivity();
    _online = !results.contains(ConnectivityResult.none);
    notifyListeners();
    return _online;
  }

  void _handleChange(List<ConnectivityResult> results) {
    final wasOnline = _online;
    _online = !results.contains(ConnectivityResult.none);
    if (wasOnline != _online) notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
