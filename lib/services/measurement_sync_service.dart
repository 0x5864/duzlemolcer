import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MeasurementSyncService {
  MeasurementSyncService({
    required SharedPreferences prefs,
    String? baseUrl,
    http.Client? client,
    int maxQueueLength = 400,
  }) : _prefs = prefs,
       _client = client ?? http.Client(),
       _maxQueueLength = maxQueueLength,
       _baseUrl = _resolveBaseUrl(baseUrl);

  static const String _queueStorageKey = 'pending_measurements_v1';
  static const String _authTokenStorageKey = 'api_auth_token_v1';

  static const String _authTokenFromDefine = String.fromEnvironment(
    'API_AUTH_TOKEN',
  );
  static const String _authEmailFromDefine = String.fromEnvironment(
    'API_AUTH_EMAIL',
  );
  static const String _authPasswordFromDefine = String.fromEnvironment(
    'API_AUTH_PASSWORD',
  );

  final SharedPreferences _prefs;
  final http.Client _client;
  final int _maxQueueLength;
  final String _baseUrl;

  bool _isFlushing = false;
  Timer? _retryTimer;

  static String _resolveBaseUrl(String? providedBaseUrl) {
    final fromDefine = const String.fromEnvironment('API_BASE_URL');
    if (providedBaseUrl != null && providedBaseUrl.trim().isNotEmpty) {
      return providedBaseUrl.trim();
    }
    if (fromDefine.trim().isNotEmpty) {
      return fromDefine.trim();
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }

    return 'http://127.0.0.1:8080';
  }

  void startAutoRetry({Duration interval = const Duration(seconds: 10)}) {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(interval, (_) {
      unawaited(flushPending());
    });
  }

  void dispose() {
    _retryTimer?.cancel();
    _client.close();
  }

  Future<void> enqueueMeasurement({
    required double angleX,
    required double angleY,
    required String mode,
  }) async {
    final queue = await _readQueue();
    queue.add({
      'angle_x': angleX,
      'angle_y': angleY,
      'mode': mode,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    while (queue.length > _maxQueueLength) {
      queue.removeAt(0);
    }

    await _writeQueue(queue);
    unawaited(flushPending());
  }

  Future<void> flushPending() async {
    if (_isFlushing) {
      return;
    }

    _isFlushing = true;
    try {
      final queue = await _readQueue();
      if (queue.isEmpty) {
        return;
      }

      final authToken = await _resolveAuthToken();
      if (authToken == null) {
        return;
      }

      final endpoint = Uri.parse(_baseUrl).resolve('/api/measurements');
      final remaining = List<Map<String, Object?>>.from(queue);

      while (remaining.isNotEmpty) {
        final item = remaining.first;
        final payload = {
          'angle_x': item['angle_x'],
          'angle_y': item['angle_y'],
          'mode': item['mode'],
        };

        final response = await _client
            .post(
              endpoint,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $authToken',
              },
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 401) {
          await _clearStoredAuthToken();
          break;
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          break;
        }

        remaining.removeAt(0);
        await _writeQueue(remaining);
      }
    } catch (_) {
      // Keep queue for next retry.
    } finally {
      _isFlushing = false;
    }
  }

  Future<String?> _resolveAuthToken() async {
    final tokenFromDefine = _authTokenFromDefine.trim();
    if (tokenFromDefine.isNotEmpty) {
      return tokenFromDefine;
    }

    final storedToken = _prefs.getString(_authTokenStorageKey);
    if (storedToken != null && storedToken.trim().isNotEmpty) {
      return storedToken.trim();
    }

    final email = _authEmailFromDefine.trim();
    final password = _authPasswordFromDefine;
    if (email.isEmpty || password.isEmpty) {
      return null;
    }

    final token = await _loginOrRegister(email: email, password: password);
    if (token == null) {
      return null;
    }

    await _prefs.setString(_authTokenStorageKey, token);
    return token;
  }

  Future<void> _clearStoredAuthToken() async {
    final tokenFromDefine = _authTokenFromDefine.trim();
    if (tokenFromDefine.isNotEmpty) {
      return;
    }

    await _prefs.remove(_authTokenStorageKey);
  }

  Future<String?> _loginOrRegister({
    required String email,
    required String password,
  }) async {
    final loginUri = Uri.parse(_baseUrl).resolve('/api/auth/login');
    final registerUri = Uri.parse(_baseUrl).resolve('/api/auth/register');
    final body = jsonEncode({'email': email, 'password': password});

    final loginResponse = await _client
        .post(
          loginUri,
          headers: const {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 4));

    if (loginResponse.statusCode >= 200 && loginResponse.statusCode < 300) {
      return _extractToken(loginResponse.body);
    }

    if (loginResponse.statusCode != 401) {
      return null;
    }

    final registerResponse = await _client
        .post(
          registerUri,
          headers: const {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 4));

    if (registerResponse.statusCode >= 200 &&
        registerResponse.statusCode < 300) {
      return _extractToken(registerResponse.body);
    }

    if (registerResponse.statusCode == 409) {
      final retryLogin = await _client
          .post(
            loginUri,
            headers: const {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 4));
      if (retryLogin.statusCode >= 200 && retryLogin.statusCode < 300) {
        return _extractToken(retryLogin.body);
      }
    }

    return null;
  }

  String? _extractToken(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final token = decoded['token'];
      if (token is String && token.trim().isNotEmpty) {
        return token.trim();
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, Object?>>> _readQueue() async {
    final raw = _prefs.getString(_queueStorageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map((entry) => Map<String, Object?>.from(entry))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeQueue(List<Map<String, Object?>> queue) async {
    if (queue.isEmpty) {
      await _prefs.remove(_queueStorageKey);
      return;
    }

    await _prefs.setString(_queueStorageKey, jsonEncode(queue));
  }
}
