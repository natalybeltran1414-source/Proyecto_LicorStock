import 'package:flutter/material.dart' hide Badge;

import '../navigation/app_router.dart';
import '../services/acceso.dart';
import '../services/api.dart';
import '../services/biometria.dart' as bio;
import '../theme/tokens.dart';
import '../theme/theme_provider.dart';
import '../widgets/pin_pad.dart';
import '../widgets/ui.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic> _user = {};
  bool _cargando = true;
  bool _hayPin = false;

  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _correo = TextEditingController();

  final _passActual = TextEditingController();
  final _passNueva = TextEditingController();
  final _passConfirmar = TextEditingController();

  bool _guardandoDatos = false;
  bool _guardandoPass = false;

  bool _bioActivada = false;
  String _tipoBio = 'Biometría';
  bool _bioDisponible = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _correo.dispose();
    _passActual.dispose();
    _passNueva.dispose();
    _passConfirmar.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final b = await Future.wait<dynamic>([
        authService.me(),
        bio.hardwareDisponible(),
        bio.tipoBiometria(),
        bio.estaActivada(),
        tienePin(),
      ]);
      if (!mounted) return;
      final t = b[2] as bio.TipoBiometria;
      setState(() {
        _user = Map<String, dynamic>.from(b[0] as Map);
        _bioDisponible = b[1] as bool;
        _tipoBio = t.label;
        _bioActivada = (b[3] as bool) && (b[1] as bool);
        _hayPin = b[4] as bool;
        _cargando = false;
      });
      _nombre.text = _user['first_name']?.toString() ?? '';
      _apellido.text = _user['last_name']?.toString() ?? '';
      _correo.text = _user['email']?.toString() ?? '';
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  String get _nombreCompleto {
    final parts = [
      _user['first_name']?.toString() ?? '',
      _user['last_name']?.toString() ?? '',
    ].where((s) => s.isNotEmpty).join(' ');
    return parts.isEmpty ? (_user['username']?.toString() ?? '') : parts;
  }

  Future<void> _guardarDatos() async {
    setState(() => _guardandoDatos = true);
    try {
      await authService.updatePerfil({
        'first_name': _nombre.text.trim(),
        'last_name': _apellido.text.trim(),
        'email': _correo.text.trim(),
      });
      if (!mounted) return;
      snaki(context, 'Perfil actualizado');
      setState(() => _guardandoDatos = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardandoDatos = false);
      snaki(context, 'No se pudo actualizar el perfil', ok: false);
    }
  }

  Future<void> _cambiarPass() async {
    if (_passNueva.text != _passConfirmar.text) {
      snaki(context, 'Las contraseñas no coinciden', ok: false);
      return;
    }
    if (_passNueva.text.length < 8) {
      snaki(context, 'La contraseña debe tener al menos 8 caracteres', ok: false);
      return;
    }
    setState(() => _guardandoPass = true);
    try {
      await authService.cambiarPassword({
        'password_actual': _passActual.text,
        'nueva_password': _passNueva.text,
        'confirmar_password': _passConfirmar.text,
      });
      if (!mounted) return;
      setState(() {
        _guardandoPass = false;
        _passActual.clear();
        _passNueva.clear();
        _passConfirmar.clear();
      });
      snaki(context, 'Contraseña actualizada correctamente');
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardandoPass = false);
      snaki(context, 'No se pudo cambiar la contraseña', ok: false);
    }
  }

  Future<void> _configurarPin() async {
    final nuevo = await pedirPin(context,
        titulo: 'Configura tu PIN',
        mensaje: 'Será 4 dígitos. Úsalo para desbloquear la app.');
    if (nuevo == null || !mounted) return;
    final confirma = await pedirPin(
      context,
      titulo: 'Repite tu PIN',
      validar: (c) async =>
          c == nuevo ? null : 'Los PIN no coinciden',
    );
    if (confirma == null || !mounted) return;
    await guardarPin(nuevo);
    if (!mounted) return;
    setState(() => _hayPin = true);
    snaki(context, 'PIN configurado');
  }

  Future<void> _cambiarPin() async {
    final actual = await pedirPin(
      context,
      titulo: 'PIN actual',
      validar: (c) async {
        final ok = await verificarPin(c);
        return ok ? null : 'PIN incorrecto';
      },
    );
    if (actual == null || !mounted) return;
    final nuevo = await pedirPin(context,
        titulo: 'Nuevo PIN',
        mensaje: 'Elige otro PIN de 4 dígitos.');
    if (nuevo == null || !mounted) return;
    await guardarPin(nuevo);
    if (!mounted) return;
    snaki(context, 'PIN actualizado');
  }

  Future<void> _quitarPin() async {
    final actual = await pedirPin(
      context,
      titulo: 'Ingresa tu PIN',
      validar: (c) async {
        final ok = await verificarPin(c);
        return ok ? null : 'PIN incorrecto';
      },
    );
    if (actual == null || !mounted) return;
    await quitarPin();
    await bio.desactivar();
    if (!mounted) return;
    setState(() {
      _bioActivada = false;
      _hayPin = false;
    });
    snaki(context, 'PIN eliminado');
  }

  Future<void> _alternarBio(bool on) async {
    if (on) {
      final hayPin = await tienePin();
      if (!hayPin) {
        snaki(context, 'Configura primero un PIN', ok: false);
        setState(() => _bioActivada = false);
        return;
      }
      final confirmado = await pedirPin(
        context,
        titulo: 'Confirma con tu PIN',
        mensaje: 'Para activar $_tipoBio',
        validar: (c) async {
          final ok = await verificarPin(c);
          return ok ? null : 'PIN incorrecto';
        },
      );
      if (confirmado == null) {
        setState(() => _bioActivada = false);
        return;
      }
      await bio.activar();
      if (!mounted) return;
      snaki(context, '$_tipoBio activado');
    } else {
      await bio.desactivar();
      if (!mounted) return;
      snaki(context, '$_tipoBio desactivado');
    }
  }

  Future<void> _cerrarSesion() async {
    await authService.logout();
    if (!mounted) return;
    await remontarAlLogin();
  }

  @override
  Widget build(BuildContext context) {
    final tema = useTema(context);
    final paleta = tema.paleta;
    if (_cargando) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(spacingMd),
            child: Column(
              children: const [
                EsqueletoTarjeta(),
                SizedBox(height: spacingMd),
                EsqueletoTarjeta(),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: paleta.surface,
              floating: true,
              leading: BotonIcono(
                icono: Icons.arrow_back,
                alTocar: () => Navigator.of(context).maybePop(),
              ),
              title: const Text('Perfil',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(spacingMd),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    _TarjetaIdentidad(
                      nombre: _nombreCompleto,
                      usuario: _user['username']?.toString() ?? '',
                      rol: _user['rol']?.toString() ?? '',
                    ),
                    const SizedBox(height: spacingMd),
                    _Seccion(
                      titulo: 'Datos personales',
                      child: Column(
                        children: [
                          CampoTexto(
                            etiqueta: 'Nombre',
                            controlador: _nombre,
                            textoTeclado: TextInputType.name,
                          ),
                          const SizedBox(height: spacingSm),
                          CampoTexto(
                            etiqueta: 'Apellido',
                            controlador: _apellido,
                            textoTeclado: TextInputType.name,
                          ),
                          const SizedBox(height: spacingSm),
                          CampoTexto(
                            etiqueta: 'Correo',
                            controlador: _correo,
                            textoTeclado: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: spacingMd),
                          Align(
                            alignment: Alignment.centerRight,
                            child: BotonFantasma(
                              titulo: 'Guardar',
                              icono: Icons.save_outlined,
                              cargando: _guardandoDatos,
                              alTocar: _guardarDatos,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: spacingMd),
                    _Seccion(
                      titulo: 'Cambiar contraseña',
                      child: Column(
                        children: [
                          CampoTexto(
                            etiqueta: 'Contraseña actual',
                            controlador: _passActual,
                            esContrasena: true,
                          ),
                          const SizedBox(height: spacingSm),
                          CampoTexto(
                            etiqueta: 'Nueva contraseña',
                            controlador: _passNueva,
                            esContrasena: true,
                          ),
                          const SizedBox(height: spacingSm),
                          CampoTexto(
                            etiqueta: 'Repite la nueva',
                            controlador: _passConfirmar,
                            esContrasena: true,
                          ),
                          const SizedBox(height: spacingMd),
                          Align(
                            alignment: Alignment.centerRight,
                            child: BotonFantasma(
                              titulo: 'Cambiar contraseña',
                              icono: Icons.lock_reset,
                              cargando: _guardandoPass,
                              alTocar: _cambiarPass,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: spacingMd),
                    _Seccion(
                      titulo: 'Apariencia',
                      child: Column(
                        children: [
                          _FilaModo(
                            etiqueta: 'Modo claro',
                            icono: Icons.light_mode_outlined,
                            seleccionado: tema.modo == 'claro',
                            alTocar: () => tema.setModo('claro'),
                          ),
                          _Divisoria(),
                          _FilaModo(
                            etiqueta: 'Modo oscuro',
                            icono: Icons.dark_mode_outlined,
                            seleccionado: tema.modo == 'oscuro',
                            alTocar: () => tema.setModo('oscuro'),
                          ),
                          _Divisoria(),
                          _FilaModo(
                            etiqueta: 'Según sistema',
                            icono: Icons.brightness_auto_outlined,
                            seleccionado: tema.modo == 'sistema',
                            alTocar: () => tema.setModo('sistema'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: spacingMd),
                    _Seccion(
                      titulo: 'Seguridad',
                      child: Column(
                        children: [
                          _FilaPin(
                            existePin: _hayPin,
                            alConfigurar: _configurarPin,
                            alCambiar: _cambiarPin,
                            alQuitar: _quitarPin,
                          ),
                          if (_bioDisponible) ...[
                            _Divisoria(),
                            SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: spacingSm),
                              dense: true,
                              title: Text('$_tipoBio',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              subtitle: const Text(
                                  'Desbloquear con huella o rostro',
                                  style: TextStyle(fontSize: 12)),
                              value: _bioActivada,
                              onChanged: _cargando ? null : _alternarBio,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: spacingMd),
                    BotonSolido(
                      titulo: 'Cerrar sesión',
                      icono: Icons.logout,
                      alTocar: _cerrarSesion,
                    ),
                    const SizedBox(height: spacingLg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaIdentidad extends StatefulWidget {
  final String nombre;
  final String usuario;
  final String rol;

  const _TarjetaIdentidad({
    required this.nombre,
    required this.usuario,
    required this.rol,
  });

  @override
  State<_TarjetaIdentidad> createState() => _TarjetaIdentidadState();
}

class _TarjetaIdentidadState extends State<_TarjetaIdentidad> {
  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: paleta.gradientCard),
        borderRadius: BorderRadius.circular(radiusXl),
        border: Border.all(color: paleta.border),
      ),
      child: Column(
        children: [
          Chat(nombre: widget.nombre, tamanho: 84),
          const SizedBox(height: spacingMd),
          Text(widget.nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text('@${widget.usuario}',
              style: TextStyle(color: paleta.textMuted, fontSize: 13)),
          const SizedBox(height: spacingMd),
          Badge(
            texto: widget.rol == 'ADMIN' ? 'Administrador' : 'Vendedor',
            color: paleta.gold,
            icono: Icons.badge_outlined,
          ),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _Seccion({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return Container(
      padding: const EdgeInsets.all(spacingMd),
      decoration: BoxDecoration(
        color: paleta.card,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: paleta.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: spacingSm),
          child,
        ],
      ),
    );
  }
}

class _FilaModo extends StatelessWidget {
  final String etiqueta;
  final IconData icono;
  final bool seleccionado;
  final VoidCallback alTocar;

  const _FilaModo({
    required this.etiqueta,
    required this.icono,
    required this.seleccionado,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return InkWell(
      onTap: alTocar,
      borderRadius: BorderRadius.circular(radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: spacingSm, vertical: spacingSm),
        child: Row(
          children: [
            Icon(icono, size: 20, color: paleta.textSecondary),
            const SizedBox(width: spacingMd),
            Expanded(
              child: Text(etiqueta,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            Icon(
              seleccionado
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: seleccionado ? paleta.gold : paleta.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaPin extends StatelessWidget {
  final bool existePin;
  final VoidCallback alConfigurar;
  final VoidCallback alCambiar;
  final VoidCallback alQuitar;

  const _FilaPin({
    required this.existePin,
    required this.alConfigurar,
    required this.alCambiar,
    required this.alQuitar,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: spacingSm),
      dense: true,
      leading: const Icon(Icons.pin, size: 22),
      title: const Text('PIN de seguridad',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(
        existePin ? 'Configurado' : 'No configurado',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: existePin
          ? PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'cambiar') alCambiar();
                if (v == 'quitar') alQuitar();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'cambiar', child: Text('Cambiar PIN')),
                PopupMenuItem(value: 'quitar', child: Text('Quitar PIN')),
              ],
            )
          : TextButton(onPressed: alConfigurar, child: const Text('Configurar')),
    );
  }
}

class _Divisoria extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return Divider(height: 1, color: paleta.borderSubtle);
  }
}