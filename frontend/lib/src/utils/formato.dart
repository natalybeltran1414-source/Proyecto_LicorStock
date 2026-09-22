import 'package:flutter/material.dart';

const List<String> _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

const List<String> _dias = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

String _num2(int n) => n.toString().padLeft(2, '0');

String fmtMoney(Object? n) {
  final v = (n ?? 0) is num
      ? ((n ?? 0) as num).toDouble()
      : double.tryParse(n?.toString() ?? '') ?? 0;
  return '\$${v.toStringAsFixed(2)}';
}

String fmtCorto(Object? n) {
  final v = (n ?? 0) is num
      ? ((n ?? 0) as num).toDouble()
      : double.tryParse(n?.toString() ?? '') ?? 0;
  if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}k';
  return '\$${v.toStringAsFixed(0)}';
}

String capitalizar(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

String saludo(int hora) {
  if (hora < 12) return 'Buenos días';
  if (hora < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

/// "lunes, 21 de septiembre"
String fechaLarga(DateTime d) =>
    '${_dias[d.weekday - 1]} ${d.day} de ${_meses[d.month - 1]}';

/// yyyy-MM-dd (equivalente a toLocaleDateString('en-CA'))
String hoyISO(DateTime d) => '${d.year}-${_num2(d.month)}-${_num2(d.day)}';

String etiquetaFechaMov(DateTime d) {
  final hoy = DateTime.now();
  final ayer = hoy.subtract(const Duration(days: 1));
  final misma = (DateTime a) =>
      a.year == d.year && a.month == d.month && a.day == d.day;
  final fecha = '${d.day} de ${_meses[d.month - 1]}';
  if (misma(hoy)) return 'Hoy, $fecha';
  if (misma(ayer)) return 'Ayer, $fecha';
  return '$fecha de ${d.year}';
}

/// "21 sep"
String fechaCorta(DateTime d) => '${_num2(d.day)} ${_meses[d.month - 1].substring(0, 3)}';

/// "21 sep, 14:05"
String fechaHora(DateTime d) =>
    '${fechaCorta(d)}, ${_num2(d.hour)}:${_num2(d.minute)}';

DateTime? parseandoFecha(Object? iso, {bool corte = false}) {
  if (iso == null) return null;
  try {
    final s = iso.toString();
    final parte = corte ? s.split('T').first : s;
    if (corte) return DateTime.tryParse(parte);
    return DateTime.tryParse(parte);
  } catch (_) {
    return null;
  }
}

String normalizarTelefono(Object? tel) {
  var t = (tel?.toString() ?? '').replaceAll(RegExp(r'\D'), '');
  if (t.isEmpty) return '';
  if (t.startsWith('593')) return t;
  if (t.startsWith('0')) return '593${t.substring(1)}';
  if (t.length == 9) return '593$t';
  return t;
}

int? margenPct(Object? compra, Object? venta) {
  final c = (compra ?? 0) is num
      ? ((compra ?? 0) as num).toDouble()
      : double.tryParse(compra?.toString() ?? '') ?? 0;
  final v = (venta ?? 0) is num
      ? ((venta ?? 0) as num).toDouble()
      : double.tryParse(venta?.toString() ?? '') ?? 0;
  if (c <= 0) return null;
  return ((v - c) / c * 100).round();
}

String iniciales(String? nombre) {
  final partes = (nombre ?? '?').trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (partes.isEmpty) return '?';
  final letras = partes.take(2).map((w) => w[0].toUpperCase()).join();
  return letras.isEmpty ? '?' : letras;
}

Color? colorDeHex(Object? hex) {
  if (hex == null) return null;
  var s = hex.toString().replaceAll('#', '');
  if (s.length == 6) s = 'FF$s';
  if (s.length != 8) return null;
  final v = int.tryParse(s, radix: 16);
  if (v == null) return null;
  return Color(v);
}

/// Combina un color hex con un alpha hexadecimal (ej. `${color}22`).
Color? colorConAlpha(Object? hex, String alpha) {
  final c = colorDeHex(hex);
  if (c == null) return null;
  final a = int.tryParse(alpha, radix: 16) ?? 0xFF;
  return c.withValues(alpha: a / 255);
}

double numADouble(Object? n) {
  if (n == null) return 0;
  if (n is num) return n.toDouble();
  return double.tryParse(n.toString()) ?? 0;
}

int numAInt(Object? n) {
  if (n == null) return 0;
  if (n is num) return n.toInt();
  return int.tryParse(n.toString()) ?? 0;
}