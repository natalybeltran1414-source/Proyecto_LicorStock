import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../services/api.dart';
import '../services/clientes.dart';
import '../theme/tokens.dart';
import '../theme/theme_provider.dart';
import '../widgets/ui.dart';

class ClienteFormScreen extends StatefulWidget {
  const ClienteFormScreen({super.key});

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final _nombre = TextEditingController();
  final _documento = TextEditingController();
  final _telefono = TextEditingController();
  final _correo = TextEditingController();
  final _direccion = TextEditingController();

  Map<String, dynamic>? _cliente;
  String _tipoDocumento = 'CEDULA';
  bool _estado = true;
  bool _guardando = false;
  Map<String, String> _errores = {};

  bool get _editando => _cliente != null;

  static const Map<String, String> _tiposDoc = {
    'CEDULA': 'Cédula',
    'RUC': 'RUC',
    'CONSUMIDOR': 'Consumidor final',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) _cliente = args;
      final c = _cliente;
      if (c != null) {
        _nombre.text = c['nombre']?.toString() ?? '';
        _documento.text = c['documento']?.toString() ?? '';
        _telefono.text = c['telefono']?.toString() ?? '';
        _correo.text = c['email']?.toString() ?? '';
        _direccion.text = c['direccion']?.toString() ?? '';
        _tipoDocumento = c['tipo_documento']?.toString() ?? 'CEDULA';
        _estado = c['estado'] == true;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nombre.dispose();
    _documento.dispose();
    _telefono.dispose();
    _correo.dispose();
    _direccion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) {
      setState(() => _errores = {'nombre': 'El nombre es obligatorio'});
      return;
    }
    setState(() {
      _guardando = true;
      _errores = {};
    });
    final datos = <String, dynamic>{
      'nombre': nombre,
      'tipo_documento': _tipoDocumento,
      'documento': _documento.text.trim(),
      'telefono': _telefono.text.trim(),
      'email': _correo.text.trim(),
      'direccion': _direccion.text.trim(),
      'estado': _estado,
    };
    try {
      if (_editando) {
        await clientesService.actualizar(_cliente!['id'] as int, datos);
      } else {
        datos.remove('estado');
        await clientesService.crear(datos);
      }
      if (!mounted) return;
      snaki(context,
          _editando ? 'Cliente actualizado' : 'Cliente creado');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      if (e is DioException) {
        final campos = camposErrores(e.response?.data);
        if (campos.isNotEmpty) {
          setState(() => _errores = campos);
          return;
        }
      }
      snaki(context, 'No se pudo guardar el cliente', ok: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: paleta.surface,
        elevation: 0,
        leading: BotonIcono(
          icono: Icons.arrow_back,
          alTocar: () => Navigator.of(context).maybePop(),
        ),
        title: Text(_editando ? 'Editar cliente' : 'Nuevo cliente',
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CampoTexto(
              etiqueta: 'Nombre completo',
              controlador: _nombre,
              error: _errores['nombre'],
              textoTeclado: TextInputType.name,
            ),
            const SizedBox(height: spacingMd),
            Text(
              'Tipo de documento',
              style: TextStyle(
                color: paleta.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: spacingSm),
            Wrap(
              spacing: spacingSm,
              children: _tiposDoc.keys.map((t) {
                final seleccionado = t == _tipoDocumento;
                return ChoiceChip(
                  label: Text(_tiposDoc[t] ?? t),
                  selected: seleccionado,
                  selectedColor: paleta.gold,
                  labelStyle: TextStyle(
                    color:
                        seleccionado ? paleta.sobreDorado : paleta.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _tipoDocumento = t),
                );
              }).toList(),
            ),
            const SizedBox(height: spacingMd),
            CampoTexto(
              etiqueta: 'Número de documento',
              controlador: _documento,
              error: _errores['documento'],
              textoTeclado: TextInputType.text,
            ),
            const SizedBox(height: spacingMd),
            CampoTexto(
              etiqueta: 'Teléfono',
              controlador: _telefono,
              error: _errores['telefono'],
              textoTeclado: TextInputType.phone,
            ),
            const SizedBox(height: spacingMd),
            CampoTexto(
              etiqueta: 'Correo electrónico',
              controlador: _correo,
              error: _errores['email'],
              textoTeclado: TextInputType.emailAddress,
            ),
            const SizedBox(height: spacingMd),
            CampoTexto(
              etiqueta: 'Dirección',
              controlador: _direccion,
              error: _errores['direccion'],
              textoTeclado: TextInputType.streetAddress,
              maxLineas: 2,
              accion: TextInputAction.newline,
            ),
            if (_editando) ...[
              const SizedBox(height: spacingMd),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Cliente activo',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                value: _estado,
                onChanged: (v) => setState(() => _estado = v),
              ),
            ],
            const SizedBox(height: spacingLg),
            BotonSolido(
              titulo: _editando ? 'Guardar cambios' : 'Crear cliente',
              icono: Icons.save_outlined,
              cargando: _guardando,
              alTocar: _guardar,
            ),
            const SizedBox(height: spacingLg),
          ],
        ),
      ),
    );
  }
}