import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../navigation/app_router.dart';
import '../services/api.dart';
import '../theme/paleta.dart';
import '../theme/tokens.dart';
import '../widgets/ui.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _usuario = TextEditingController();
  final _primerNombre = TextEditingController();
  final _correo = TextEditingController();
  final _telefono = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmacion = TextEditingController();
  bool _cargando = false;
  Map<String, String> _errores = {};

  static const Paleta p = paletaOscura;

  @override
  void dispose() {
    _usuario.dispose();
    _primerNombre.dispose();
    _correo.dispose();
    _telefono.dispose();
    _contrasena.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (_contrasena.text != _confirmacion.text) {
      setState(() => _errores = {'password2': 'Las contraseñas no coinciden'});
      return;
    }
    final payload = <String, dynamic>{
      'username': _usuario.text.trim(),
      'first_name': _primerNombre.text.trim(),
      'email': _correo.text.trim(),
      'telefono': _telefono.text.trim(),
      'password': _contrasena.text,
      'password2': _confirmacion.text,
    };
    setState(() {
      _cargando = true;
      _errores = {};
    });
    try {
      final res = await authService.register(payload);
      if (!mounted) return;
      final detalle =
          (res['detail']?.toString().isNotEmpty ?? false) ? res['detail'] : null;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(
            detalle?.toString() ?? 'Cuenta creada. Inicia sesión.',
          ),
        ));
      await Navigator.of(context).pushNamedAndRemoveUntil(
        Routes.login,
        (ruta) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      if (e is DioException) {
        final campos = camposErrores(e.response?.data);
        if (campos.isNotEmpty) {
          setState(() => _errores = campos);
          return;
        }
        if (e.response?.statusCode == 429) {
          setState(() => _errores = {
            'password': 'Demasiados intentos. Espera un momento.'
          });
          return;
        }
      }
      snaki(context, 'No se pudo crear la cuenta', ok: false);
    }
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(spacingMd),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: p.text),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: spacingSm),
                      Text('Crear cuenta',
                        style: TextStyle(
                            color: p.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: spacingXl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CampoLogin(
                          controlador: _usuario,
                          etiqueta: 'Nombre de usuario',
                          icono: Icons.person_outline,
                          error: _errores['username'],
                          textoTeclado: TextInputType.text,
                        ),
                        const SizedBox(height: spacingMd),
                        _CampoLogin(
                          controlador: _primerNombre,
                          etiqueta: 'Nombre completo',
                          icono: Icons.badge_outlined,
                          error: _errores['first_name'],
                          textoTeclado: TextInputType.name,
                        ),
                        const SizedBox(height: spacingMd),
                        _CampoLogin(
                          controlador: _correo,
                          etiqueta: 'Correo electrónico',
                          icono: Icons.mail_outline,
                          error: _errores['email'],
                          textoTeclado:
                              TextInputType.emailAddress,
                        ),
                        const SizedBox(height: spacingMd),
                        _CampoLogin(
                          controlador: _telefono,
                          etiqueta: 'Teléfono',
                          icono: Icons.phone_outlined,
                          error: _errores['telefono'],
                          textoTeclado: TextInputType.phone,
                        ),
                        const SizedBox(height: spacingMd),
                        _CampoLogin(
                          controlador: _contrasena,
                          etiqueta: 'Contraseña',
                          icono: Icons.lock_outline,
                          error: _errores['password'],
                          esContrasena: true,
                          textoTeclado: TextInputType.text,
                        ),
                        const SizedBox(height: spacingMd),
                        _CampoLogin(
                          controlador: _confirmacion,
                          etiqueta: 'Confirmar contraseña',
                          icono: Icons.lock_outline,
                          error: _errores['password2'],
                          esContrasena: true,
                          textoTeclado: TextInputType.text,
                          alEnviar: _registrar,
                        ),
                        const SizedBox(height: spacingLg),
                        BotonSolido(
                          titulo: 'Crear cuenta',
                          icono: Icons.person_add_alt,
                          cargando: _cargando,
                          alTocar: _registrar,
                        ),
                        const SizedBox(height: spacingLg),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo de texto del formulario de registro.
class _CampoLogin extends StatelessWidget {
  final TextEditingController controlador;
  final String etiqueta;
  final IconData icono;
  final String? error;
  final bool esContrasena;
  final TextInputType textoTeclado;
  final VoidCallback? alEnviar;

  const _CampoLogin({
    required this.controlador,
    required this.etiqueta,
    required this.icono,
    this.error,
    this.esContrasena = false,
    required this.textoTeclado,
    this.alEnviar,
  });

  @override
  Widget build(BuildContext context) {
    final p = paletaOscura;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controlador,
          obscureText: esContrasena,
          autocorrect: false,
          textInputAction:
              alEnviar != null ? TextInputAction.done : TextInputAction.next,
          onSubmitted: alEnviar == null ? null : (_) => alEnviar!(),
          style: TextStyle(color: p.text),
          decoration: InputDecoration(
            labelText: etiqueta,
            errorText: error,
            errorStyle: TextStyle(color: p.danger, fontSize: 12),
            filled: true,
            fillColor: p.cardLight,
            prefixIcon: Icon(icono, color: p.textSecondary),
            contentPadding: const EdgeInsets.symmetric(
                vertical: spacingMd - 2, horizontal: spacingMd),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radiusMd),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radiusMd),
              borderSide: BorderSide(color: p.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radiusMd),
              borderSide: BorderSide(color: p.gold, width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radiusMd),
              borderSide: BorderSide(color: p.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radiusMd),
              borderSide: BorderSide(color: p.danger, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}