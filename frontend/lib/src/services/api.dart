import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// URL base del API. Se puede sobreescribir al compilar con
/// `--dart-define=API_URL=http://<ip-o-dominio>:8000/api`
/// En el emulador Android, localhost apunta al propio emulador, entonces
/// se usa 10.0.2.2 como alias del localhost de la PC anfitriona.
String resolverBaseUrl() {
  const env = String.fromEnvironment('API_URL');
  if (env.isNotEmpty) return env;
  if (kIsWeb) return 'http://localhost:8000/api';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000/api';
  }
  return 'http://localhost:8000/api';
}

final String baseUrl = resolverBaseUrl();

class Sesion {
  final String? access;
  final String? refresh;
  final Map<String, dynamic>? user;

  const Sesion({this.access, this.refresh, this.user});
}

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

Future<Map<String, String>> _mapaSesion() async {
  final sp = await _prefs();
  return {
    'access': sp.getString('access') ?? '',
    'refresh': sp.getString('refresh') ?? '',
    'user': sp.getString('user') ?? '',
  };
}

Future<void> saveSession({
  required String access,
  required String refresh,
  Map<String, dynamic>? user,
}) async {
  final sp = await _prefs();
  await sp.setString('access', access);
  await sp.setString('refresh', refresh);
  if (user != null) {
    await sp.setString('user', jsonEncode(user));
  }
}

Future<Sesion> getSession() async {
  final m = await _mapaSesion();
  Map<String, dynamic>? user;
  final userJson = m['user'];
  if (userJson != null && userJson.isNotEmpty) {
    try {
      user = Map<String, dynamic>.from(jsonDecode(userJson) as Map);
    } catch (_) {
      user = null;
    }
  }
  return Sesion(
    access: (m['access']?.isNotEmpty ?? false) ? m['access'] : null,
    refresh: (m['refresh']?.isNotEmpty ?? false) ? m['refresh'] : null,
    user: user,
  );
}

Future<void> clearSession() async {
  final sp = await _prefs();
  await sp.remove('access');
  await sp.remove('refresh');
  await sp.remove('user');
}

/// Expiración de sesión por inactividad: si la app pasa más de este
/// umbral sin actividad, el siguiente arranque pide login.
const int tiempoSesionMs = 5 * 60 * 1000;

const String actividadKey = 'ultima_actividad';

Future<void> marcarActividad() async {
  try {
    final sp = await _prefs();
    await sp.setInt(actividadKey, DateTime.now().millisecondsSinceEpoch);
  } catch (_) {}
}

Future<bool> sesionExpirada() async {
  try {
    final sp = await _prefs();
    final marca = sp.getInt(actividadKey);
    if (marca == null) return true;
    return DateTime.now().millisecondsSinceEpoch - marca > tiempoSesionMs;
  } catch (_) {
    return true;
  }
}

Dio _crearApi() {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: const {'Content-Type': 'application/json'},
    ),
  );
  _initInterceptores(dio);
  return dio;
}

final Dio api = _crearApi();

void _initInterceptores(Dio dio) {
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final sp = await _prefs();
          final token = sp.getString('access');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {}
        marcarActividad();
        handler.next(options);
      },
      onError: (err, handler) async {
        final status = err.response?.statusCode;
        final retry = err.requestOptions.extra['_retry'] ?? false;
        if (status == 401 && retry != true) {
          err.requestOptions.extra['_retry'] = true;
          try {
            final sp = await _prefs();
            final refresh = sp.getString('refresh');
            if (refresh != null && refresh.isNotEmpty) {
              final res = await Dio().post('$baseUrl/auth/refresh/', data: {
                'refresh': refresh,
              });
              final nuevoAccess = res.data['access'] as String;
              await sp.setString('access', nuevoAccess);
              err.requestOptions.headers['Authorization'] = 'Bearer $nuevoAccess';
              final response = await dio.fetch<dynamic>(err.requestOptions);
              handler.resolve(response);
              return;
            }
          } catch (_) {
            await clearSession();
          }
        }
        handler.next(err);
      },
    ),
  );
}

bool _esTimeOut(DioException e) =>
    e.type == DioExceptionType.connectionTimeout ||
    e.type == DioExceptionType.receiveTimeout ||
    e.type == DioExceptionType.sendTimeout;

Object? _dataDe(DioException e) => e.response?.data;

/// Extrae mensaje amigable de un error de red (modo inicio de sesión).
String msgDeErrorDio(DioException e, {String fallback = 'Ocurrió un error'}) {
  if (e.response?.statusCode == 429) return 'Demasiados intentos. Espera un momento.';
  final data = _dataDe(e);
  if (data is Map<String, dynamic>) {
    final det = data['detail'];
    if (det is String && det.isNotEmpty) return det;
    final nf = data['non_field_errors'];
    if (nf is List && nf.isNotEmpty && nf.first != null) {
      return nf.first.toString();
    }
  }
  if (_esTimeOut(e)) return 'Tiempo de espera agotado';
  if (e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.unknown) {
    final fake = e.error;
    if (fake != null &&
        (fake.toString().contains('SocketException') ||
            fake.toString().contains('Failed host lookup') ||
            fake.toString().contains('ClientException'))) {
      return 'No se pudo conectar con el servidor';
    }
  }
  return fallback;
}

/// Extrae mensaje de un body con mapa de campos -> lista de errores.
String msgObjetoCampo(Object? data, {String fallback = 'No se pudo guardar'}) {
  if (data is Map<String, dynamic>) {
    final lineas = <String>[];
    data.forEach((k, v) {
      final etiqueta = k == 'password2' ? 'confirmación' : k;
      if (v is List && v.isNotEmpty) {
        lineas.add('$etiqueta: ${v.first}');
      } else if (v != null) {
        lineas.add('$etiqueta: $v');
      } else {
        lineas.add('$etiqueta: (vacío)');
      }
    });
    if (lineas.isNotEmpty) return lineas.join('\n');
  }
  return fallback;
}

/// Extrae errores por campo de un body del tipo {campo: [errores]}.
Map<String, String> camposErrores(Object? data) {
  final mapa = <String, String>{};
  if (data is Map<String, dynamic>) {
    data.forEach((campo, valor) {
      if (valor is List && valor.isNotEmpty) {
        mapa[campo] = valor.first.toString();
      } else if (valor is String && valor.isNotEmpty) {
        mapa[campo] = valor;
      }
    });
  }
  return mapa;
}

class AuthServicio {
  Future<Map<String, dynamic>> login(String username, String password) async {
    final r = await api.post<dynamic>('/auth/login/', data: {
      'username': username,
      'password': password,
    });
    final d = Map<String, dynamic>.from(r.data as Map);
    await saveSession(
      access: d['access'] as String,
      refresh: d['refresh'] as String,
      user: d['user'] is Map
          ? Map<String, dynamic>.from(d['user'] as Map)
          : null,
    );
    await marcarActividad();
    return d;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final r = await api.post<dynamic>('/auth/register/', data: payload);
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<Map<String, dynamic>> me() async {
    final r = await api.get<dynamic>('/auth/me/');
    final d = Map<String, dynamic>.from(r.data as Map);
    final sp = await _prefs();
    await sp.setString('user', jsonEncode(d));
    return d;
  }

  Future<Map<String, dynamic>> updatePerfil(Map<String, dynamic> payload) async {
    final r = await api.patch<dynamic>('/auth/me/', data: payload);
    final d = Map<String, dynamic>.from(r.data as Map);
    final sp = await _prefs();
    await sp.setString('user', jsonEncode(d));
    return d;
  }

  Future<void> cambiarPassword(Map<String, dynamic> payload) async {
    await api.post<dynamic>('/auth/cambiar-password/', data: payload);
  }

  Future<void> logout() async {
    try {
      final sp = await _prefs();
      final refresh = sp.getString('refresh');
      if (refresh != null && refresh.isNotEmpty) {
        await api.post<dynamic>('/auth/logout/', data: {'refresh': refresh});
      }
    } catch (_) {
      // el token pudo ya estar inválido; se limpia igual
    }
    await clearSession();
  }
}

final authService = AuthServicio();