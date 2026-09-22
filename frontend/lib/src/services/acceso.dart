import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pinKey = 'auth_pin_hash';

String _hashPin(String pin) {
  final bytes = utf8.encode('licorstock::$pin');
  return sha256.convert(bytes).toString();
}

Future<bool> tienePin() async {
  try {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_pinKey) != null;
  } catch (_) {
    return false;
  }
}

Future<void> guardarPin(String pin) async {
  final sp = await SharedPreferences.getInstance();
  await sp.setString(_pinKey, _hashPin(pin));
}

Future<bool> verificarPin(String pin) async {
  try {
    final sp = await SharedPreferences.getInstance();
    final h = sp.getString(_pinKey);
    if (h == null || h.isEmpty) return false;
    return _hashPin(pin) == h;
  } catch (_) {
    return false;
  }
}

Future<void> quitarPin() async {
  final sp = await SharedPreferences.getInstance();
  await sp.remove(_pinKey);
}