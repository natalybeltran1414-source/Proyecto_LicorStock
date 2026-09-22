import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _flagKey = 'biometric_enabled';

bool _plataformaSoporta() {
  if (kIsWeb) return false;
  if (defaultTargetPlatform == TargetPlatform.linux) return false;
  return true;
}

class TipoBiometria {
  final String label;
  final IconData icono;
  const TipoBiometria(this.label, this.icono);
}

Future<TipoBiometria> tipoBiometria() async {
  try {
    if (!_plataformaSoporta()) {
      return const TipoBiometria('Biometría', Icons.fingerprint);
    }
    final tipos = await LocalAuthentication().getAvailableBiometrics();
    if (tipos.contains(BiometricType.face)) {
      return const TipoBiometria('Reconocimiento facial', Icons.face);
    }
    if (tipos.contains(BiometricType.iris)) {
      return const TipoBiometria('Reconocimiento de iris', Icons.visibility);
    }
    if (tipos.contains(BiometricType.fingerprint)) {
      return const TipoBiometria('Huella digital', Icons.fingerprint);
    }
  } catch (_) {
    // sin soporte
  }
  return const TipoBiometria('Biometría', Icons.fingerprint);
}

Future<bool> hardwareDisponible() async {
  if (!_plataformaSoporta()) return false;
  try {
    final auth = LocalAuthentication();
    final has = await auth.canCheckBiometrics;
    final enroll = await auth.isDeviceSupported();
    return has && enroll;
  } catch (_) {
    return false;
  }
}

Future<bool> verificar(String motivo) async {
  if (!_plataformaSoporta()) return false;
  try {
    return await LocalAuthentication().authenticate(
      localizedReason: motivo,
      biometricOnly: true,
      persistAcrossBackgrounding: false,
    );
  } catch (_) {
    return false;
  }
}

Future<bool> estaActivada() async {
  try {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_flagKey) == 'true';
  } catch (_) {
    return false;
  }
}

Future<void> activar() async {
  final sp = await SharedPreferences.getInstance();
  await sp.setString(_flagKey, 'true');
}

Future<void> desactivar() async {
  final sp = await SharedPreferences.getInstance();
  await sp.remove(_flagKey);
}