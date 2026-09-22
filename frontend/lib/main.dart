import 'package:flutter/material.dart';

import 'src/navigation/app_router.dart';
import 'src/services/acceso.dart';
import 'src/services/api.dart';
import 'src/theme/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = ThemeController('sistema');
  await controller.cargarGuardado();
  final rutaInicial = await rutaInicialDeSesion();
  runApp(LicorStockApp(
    controller: controller,
    rutaInicial: rutaInicial,
  ));
}

/// Decide la primera pantalla según sesión/PIN legados.
Future<String> rutaInicialDeSesion() async {
  try {
    final s = await getSession();
    final expirada = await sesionExpirada();
    if (s.access == null || s.access!.isEmpty || expirada) {
      return Routes.login;
    }
    if (await tienePin()) {
      return Routes.bloqueo;
    }
    return Routes.main;
  } catch (_) {
    return Routes.login;
  }
}

class LicorStockApp extends StatefulWidget {
  final ThemeController controller;
  final String rutaInicial;

  const LicorStockApp({
    super.key,
    required this.controller,
    required this.rutaInicial,
  });

  @override
  State<LicorStockApp> createState() => _LicorStockAppState();
}

class _LicorStockAppState extends State<LicorStockApp>
    with WidgetsBindingObserver {
  late String _ruta;

  @override
  void initState() {
    super.initState();
    _ruta = widget.rutaInicial;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.setSistema(WidgetsBinding.instance.platformDispatcher
          .platformBrightness);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        widget.controller.setSistema(WidgetsBinding
            .instance.platformDispatcher.platformBrightness);
        _revisarSesion();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        marcarActividad();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _revisarSesion() async {
    try {
      final s = await getSession();
      if (s.access == null) return;
      if (await sesionExpirada()) {
        await clearSession();
        if (mounted) await remontarAlLogin();
      }
    } catch (_) {}
  }

  void actualizarSistema(Brightness b) => widget.controller.setSistema(b);

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: widget.controller,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final paleta = widget.controller.paleta;
          return MaterialApp(
            title: 'LicorStock',
            navigatorKey: navKey,
            debugShowCheckedModeBanner: false,
            theme: themeDataDe(paleta),
            initialRoute: _ruta,
            routes: rutas(),
          );
        },
      ),
    );
  }
}