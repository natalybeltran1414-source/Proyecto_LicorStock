import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigation/app_router.dart';
import '../services/api.dart';
import '../theme/paleta.dart';
import '../theme/tokens.dart';
import '../widgets/ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();
  bool _cargando = false;
  String? _error;

  static const Paleta p = paletaOscura;

  @override
  void dispose() {
    _usuario.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final u = _usuario.text.trim();
    final c = _contrasena.text;
    if (u.isEmpty || c.isEmpty) {
      setState(() => _error = 'Ingresa usuario y contraseña');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await authService.login(u, c);
      if (!mounted) return;
      await marcarActividad();
      await Navigator.of(context).pushNamedAndRemoveUntil(
        Routes.main,
        (ruta) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e is Exception
            ? e.toString().replaceAll('Exception: ', '')
            : 'No se pudo iniciar sesión';
      });
    }
  }

  Future<void> _irARegistro() async {
    await Navigator.of(context).pushNamed(Routes.registro);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [p.gradientDark.first, p.background],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: spacingXl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: spacingXl),
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: p.gradientGold),
                          borderRadius: BorderRadius.circular(radiusXl),
                          boxShadow: p.sombraDorada(),
                        ),
                        child: Icon(Icons.local_bar,
                            color: p.sobreDorado, size: 48),
                      ),
                    ),
                    const SizedBox(height: spacingLg),
                    Text(
                      'Bienvenido de nuevo',
                      textAlign: TextAlign.center,
                      style: tipoDisplay.copyWith(color: p.text),
                    ),
                    Text(
                      'Inicia sesión para continuar',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.textSecondary, fontSize: 15),
                    ),
                    const SizedBox(height: spacingXl),
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(spacingMd),
                        decoration: BoxDecoration(
                          color: p.dangerSoft,
                          borderRadius: BorderRadius.circular(radiusMd),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                size: 20, color: p.danger),
                            const SizedBox(width: spacingSm),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: p.danger, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: spacingMd),
                    ],
                    Theme(
                      data: ThemeData.dark().copyWith(
                        scaffoldBackgroundColor: p.background,
                        canvasColor: p.surface,
                        colorScheme: ColorScheme.dark(
                          surface: p.surface,
                          primary: p.gold,
                          onSurface: p.text,
                        ),
                        textSelectionTheme: TextSelectionThemeData(
                          cursorColor: p.gold,
                          selectionHandleColor: p.gold,
                          selectionColor: p.goldSoft,
                        ),
                        inputDecorationTheme: InputDecorationTheme(
                          filled: true,
                          fillColor: p.cardLight,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: spacingMd, vertical: spacingMd),
                          labelStyle: TextStyle(color: p.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(radiusMd),
                            borderSide: const BorderSide(
                                color: Colors.transparent, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(radiusMd),
                            borderSide: BorderSide(color: p.borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(radiusMd),
                            borderSide: BorderSide(color: p.gold, width: 1.6),
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _usuario,
                            autocorrect: false,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(color: p.text),
                            decoration: InputDecoration(
                              labelText: 'Usuario',
                              prefixIcon:
                                  Icon(Icons.person_outline, color: p.textSecondary),
                            ),
                          ),
                          const SizedBox(height: spacingMd),
                          TextField(
                            controller: _contrasena,
                            obscureText: true,
                            autocorrect: false,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _entrar(),
                            style: TextStyle(color: p.text),
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(128),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon:
                                  Icon(Icons.lock_outline, color: p.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: spacingXl),
                    BotonSolido(
                      titulo: 'Iniciar sesión',
                      icono: Icons.logout_rounded,
                      cargando: _cargando,
                      alTocar: _entrar,
                    ),
                    const SizedBox(height: spacingLg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('¿No tienes cuenta?',
                            style: TextStyle(color: p.textSecondary)),
                        TextButton(
                          onPressed: _cargando ? null : _irARegistro,
                          child: Text('Regístrate',
                            style: TextStyle(color: p.gold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}