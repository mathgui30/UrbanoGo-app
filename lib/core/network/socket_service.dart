import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:urbanogo/core/config/app_config.dart';
import 'package:urbanogo/core/models/socket_events_model.dart';
import 'package:urbanogo/core/models/matching_offer_model.dart';

class SocketService {
  io.Socket? _socket;
  final String baseUrl = AppConfig.apiBaseUrl;

  final _matchingOfferController =
      StreamController<MatchingOfferModel>.broadcast();
  final _matchingCancelledController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _rideStatusController =
      StreamController<RideStatusEventModel>.broadcast();
  final _driverLocationController =
      StreamController<DriverLocationModel>.broadcast();
  final _errorController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<MatchingOfferModel> get onMatchingOffer =>
      _matchingOfferController.stream;
  Stream<Map<String, dynamic>> get onMatchingCancelled =>
      _matchingCancelledController.stream;
  Stream<RideStatusEventModel> get onRideStatus => _rideStatusController.stream;
  Stream<DriverLocationModel> get onDriverLocation =>
      _driverLocationController.stream;
  Stream<Map<String, dynamic>> get onError => _errorController.stream;
  Stream<bool> get onConnectionChanged => _connectionController.stream;

  void connect(String token) {
    if (_socket != null && _socket!.connected) return;

    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('Conectado ao WebSocket');
      _connectionController.add(true);
    });
    _socket!.onDisconnect((_) {
      debugPrint('Desconectado do WebSocket');
      _connectionController.add(false);
    });
    _socket!.onConnectError(
      (err) => debugPrint('⚠️ Erro de conexão WebSocket: $err'),
    );

    _socket!.on('matching:offer', (data) {
      _safeAdd('matching:offer', () {
        _matchingOfferController.add(MatchingOfferModel.fromJson(_asMap(data)));
      });
    });

    _socket!.on('matching:cancelled', (data) {
      _safeAdd('matching:cancelled', () {
        _matchingCancelledController.add(_asMap(data));
      });
    });

    _socket!.on('ride:status', (data) {
      _safeAdd('ride:status', () {
        _rideStatusController.add(RideStatusEventModel.fromJson(_asMap(data)));
      });
    });

    _socket!.on('ride:driver_location', (data) {
      _safeAdd('ride:driver_location', () {
        _driverLocationController.add(DriverLocationModel.fromJson(_asMap(data)));
      });
    });

    _socket!.on('error', (data) {
      _safeAdd('error', () {
        _errorController.add(_asMap(data));
      });
    });
  }

  void _safeAdd(String event, void Function() parse) {
    try {
      parse();
    } catch (error, stack) {
      debugPrint('⚠️ Falha ao processar evento $event: $error\n$stack');
    }
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    final normalized = _normalize(data);
    if (normalized is Map<String, dynamic>) return normalized;
    throw FormatException('payload de socket não é um objeto: $data');
  }

  static dynamic _normalize(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, dynamic v) => MapEntry(key.toString(), _normalize(v)),
      );
    }
    if (value is List) return value.map<dynamic>(_normalize).toList();
    return value;
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connectionController.add(false);
  }

  void joinRide(String rideId) {
    _socket?.emit('ride:join', {'ride_id': rideId});
  }

  void leaveRide(String rideId) {
    _socket?.emit('ride:leave', {'ride_id': rideId});
  }

  void sendDriverLocation(DriverLocationModel location) {
    _socket?.emit('driver:location', location.toJson());
  }
}
