import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'paleta.dart';
import 'tokens.dart';

const String claveModo = '@licostock:modo_tema';

/// Controlador de tema (claro / oscuro / sistema) con persistencia.
class ThemeController extends ChangeNotifier {
  ThemeController(this._modo);

  String _modo;
  Brightness _sistema = Brightness.dark;

  String get modo => _modo;
  Brightness get sistema => _sistema;

  String get clavePaleta {
    if (_modo == 'sistema') {
      return _sistema == Brightness.light ? 'claro' : 'oscuro';
    }
    return _modo;
  }

  Paleta get paleta => paletas[clavePaleta] ?? paletaOscura;

  bool get esOscuro => paleta.esOscuro;

  Future<void> cargarGuardado() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final g = sp.getString(claveModo);
      if (g != null && (g == 'claro' || g == 'oscuro')) {
        _modo = g;
        notifyListeners();
      }
    } catch (_) {}
  }

  void setModo(String nuevo) {
    if (nuevo != 'claro' && nuevo != 'oscuro') return;
    _modo = nuevo;
    SharedPreferences.getInstance().then((sp) {
      sp.setString(claveModo, nuevo);
    }).catchError((_) {});
    notifyListeners();
  }

  void setSistema(Brightness b) {
    if (b == _sistema) return;
    _sistema = b;
    notifyListeners();
  }
}

/// Expone el [ThemeController] vía InheritedNotifier (estilo useTema).
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    return scope?.notifier ?? ThemeScopeFallbackController();
  }
}

class ThemeScopeFallbackController extends ThemeController {
  ThemeScopeFallbackController() : super('oscuro');
}

/// Resultado de `useTema(context)`, análogo al hook original.
class Tema {
  final Paleta paleta;
  final String modo;
  final ValueChanged<String> setModo;
  final bool esOscuro;
  final ThemeController controller;

  const Tema({
    required this.paleta,
    required this.modo,
    required this.setModo,
    required this.esOscuro,
    required this.controller,
  });
}

Tema useTema(BuildContext context) {
  final ctrl = ThemeScope.of(context);
  return Tema(
    paleta: ctrl.paleta,
    modo: ctrl.modo,
    setModo: ctrl.setModo,
    esOscuro: ctrl.esOscuro,
    controller: ctrl,
  );
}

/// ThemeData para widgets Material a partir de la paleta.
ThemeData themeDataDe(Paleta p) {
  final base = ColorScheme.fromSeed(
    seedColor: p.gold,
    brightness: p.esOscuro ? Brightness.dark : Brightness.light,
  );
  final cs = base.copyWith(
    primary: p.gold,
    onPrimary: p.sobreDorado,
    secondary: p.goldLight,
    onSecondary: p.sobreDorado,
    surface: p.surface,
    onSurface: p.text,
    error: p.danger,
    onError: p.sobreDorado,
  );
  return ThemeData(
    brightness: p.esOscuro ? Brightness.dark : Brightness.light,
    colorScheme: cs,
    scaffoldBackgroundColor: p.background,
    canvasColor: p.surface,
    dividerColor: p.borderSubtle,
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXl),
        side: BorderSide(color: p.border),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? p.gold : p.borderSubtle,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? p.gold : p.textMuted,
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.gold,
      selectionColor: p.goldSoft,
      selectionHandleColor: p.gold,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      focusedBorder: InputBorder.none,
      enabledBorder: InputBorder.none,
    ),
  );
}