import 'package:flutter/material.dart';

import '../navigation/app_router.dart';
import '../services/acceso.dart';
import '../services/api.dart';
import '../services/biometria.dart' as bio;
import '../theme/paleta.dart';
import '../theme/tokens.dart';
import '../widgets/pin_pad.dart';
import '../widgets/ui.dart';

class BloqueoScreen extends StatefulWidget {
  const BloqueoScreen({super.key});

  @override
  State<BloqueoScreen> createState() => _BloqueoScreenState();
}

class _BloqueoScreenState extends State<BloqueoScreen>
    with WidgetsBindingObserver {
  static const Paleta p = paletaOscura;

  String _estado = 'cargando'; // cargando | esperando | error | sin-soporte
  String _tipoBio = 'Biometría';
  bool _bioActiva = false;

  @override
  void initState() {
    super.initState();
    _preparar();
  }

  Future<void> _preparar() async {
    setState(() {
      _estado = 'cargando';
    });
    final disponible = await bio.tipoBiometria();
    final activa = await bio.estaActivada();
    final hardware = await bio.hardwareDisponible();
    if (!mounted) return;
    setState(() {
      _tipoBio = disponible.label;
      _bioActiva = activa && hardware;
      _estado = _bioActiva ? 'esperando' : 'esperando';
    });
    if (activa && hardware) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _desbloquearBio();
      });
    }
  }

  Future<void> _desbloquearBio() async {
    final ok = await bio.verificar('Desbloquea LicorStock');
    if (!mounted) return;
    if (ok) {
      await Navigator.of(context).pushNamedAndRemoveUntil(
        Routes.main,
        (ruta) => false,
      );
    } else {
      setState(() {});
    }
  }

  Future<void> _desbloquearPin() async {
    final pin = await pedirPin(
      context,
      titulo: 'Ingresa tu PIN',
      validar: (candidato) async {
        final ok = await verificarPin(candidato);
        return ok ? null : 'PIN incorrecto';
      },
    );
    if (!mounted || pin == null) return;
    await Navigator.of(context).pushNamedAndRemoveUntil(
      Routes.main,
      (ruta) => false,
    );
  }

  Future<void> _cerrarSesion() async {
    await authService.logout();
    if (!mounted) return;
    await Navigator.of(context).pushNamedAndRemoveUntil(
      Routes.login,
      (ruta) => false,
    );
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
                padding: const EdgeInsets.all(spacingXl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: p.cardLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: p.border),
                      ),
                      child: Icon(
                        Icons.lock,
                        size: 44,
                        color: p.gold,
                      ),
                    ),
                    const SizedBox(height: spacingLg),
                    Text(
                      'Sesión bloqueada',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: p.text,
                      ),
                    ),
                    const SizedBox(height: spacingSm),
                    Text(
                      'Desbloquea para continuar',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.textSecondary, fontSize: 15),
                    ),
                    const SizedBox(height: spacingXl),
                    if (_estado == 'cargando') ...[
                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(),
                      ),
                    ] else if (_estado == 'esperando') ...[
                      _FilaBio(
                        bioActiva: _bioActiva,
                        tipoBio: _tipoBio,
                        alBio: _desbloquearBio,
                        alPin: _desbloquearPin,
                      ),
                    ],
                    const SizedBox(height: spacingXl),
                    TextButton.icon(
                      onPressed: _cerrarSesion,
                      style: TextButton.styleFrom(
                        foregroundColor: p.textSecondary,
                      ),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Cambiar de cuenta'),
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

class _FilaBio extends StatelessWidget {
  final bool bioActiva;
  final String tipoBio;
  final VoidCallback alBio;
  final VoidCallback alPin;

  const _FilaBio({
    required this.bioActiva,
    required this.tipoBio,
    required this.alBio,
    required this.alPin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (bioActiva) ...[
          BotonSolido(
            titulo: 'Desbloquear con $tipoBio',
            icono: Icons.fingerprint,
            alTocar: alBio,
          ),
          const SizedBox(height: spacingMd),
          Text(
            'o',
            style: TextStyle(color: paletaOscura.textMuted),
          ),
          const SizedBox(height: spacingMd),
        ],
        BotonFantasma(
          titulo: 'Ingresar PIN',
          icono: Icons.pin,
          alTocar: alPin,
        ),
      ],
    );
  }
}