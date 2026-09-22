import 'dart:async';

import 'package:flutter/material.dart' hide Badge;

import '../navigation/app_router.dart';
import '../navigation/main_shell.dart';
import '../services/clientes.dart';
import '../theme/tokens.dart';
import '../theme/theme_provider.dart';
import '../widgets/ui.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen>
    with RefrescaAlFoco<ClientesScreen> {
  bool _cargando = true;
  bool _error = false;
  String _busqueda = '';
  Timer? _debounce;

  List<Map<String, dynamic>> _clientes = [];

  @override
  void initState() {
    super.initState();
    suscribirAlFoco(5);
    _cargar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void alRecobrarFoco() {
    if (!_cargando) _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = false;
    });
    try {
      final res = await clientesService.listar({
        if (_busqueda.isNotEmpty) 'search': _busqueda,
      });
      if (!mounted) return;
      setState(() {
        _clientes = (res.data as List).cast<Map<String, dynamic>>();
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = true;
      });
    }
  }

  void _alBuscar(String texto) {
    _busqueda = texto;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _cargar);
  }

  Future<void> _nuevoCliente() async {
    final cambio = await Navigator.of(context)
        .pushNamed<bool>(Routes.cliente);
    if (cambio == true) _cargar();
  }

  Future<void> _editar(Map<String, dynamic> c) async {
    final cambio = await Navigator.of(context)
        .pushNamed<bool>(Routes.cliente, arguments: c);
    if (cambio == true) _cargar();
  }

  Future<void> _toggleEstado(Map<String, dynamic> c) async {
    final activo = c['estado'] == true;
    try {
      await clientesService.toggleEstado(c['id'] as int);
      if (!mounted) return;
      snaki(context, activo ? 'Cliente desactivado' : 'Cliente activado');
      _cargar();
    } catch (_) {
      if (!mounted) return;
      snaki(context, 'No se pudo actualizar el cliente', ok: false);
    }
  }

  Future<void> _eliminar(Map<String, dynamic> c) async {
    final ok = await dialogConfirmar(
      context,
      titulo: 'Eliminar cliente',
      mensaje: '¿Eliminar a "${c['nombre']}"?',
      textoOk: 'Eliminar',
      peligro: true,
    );
    if (!ok || !mounted) return;
    try {
      await clientesService.eliminar(c['id'] as int);
      if (!mounted) return;
      snaki(context, 'Cliente eliminado');
      _cargar();
    } catch (_) {
      if (!mounted) return;
      snaki(context, 'No se pudo eliminar el cliente', ok: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(spacingMd, spacingMd, spacingMd, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Clientes',
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w800)),
                      ),
                      Text(
                        '${_clientes.length}',
                        style: TextStyle(
                            color: paleta.gold,
                            fontSize: 16,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: spacingMd),
                  CampoBuscar(alCambiar: _alBuscar),
                ],
              ),
            ),
            const SizedBox(height: spacingSm),
            Expanded(
              child: _cargando
                  ? ListView.separated(
                      padding: const EdgeInsets.all(spacingMd),
                      itemCount: 5,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: spacingMd),
                      itemBuilder: (_, __) => const EsqueletoTarjeta(),
                    )
                  : _error
                      ? EstadoVacio(
                          icono: Icons.cloud_off,
                          titulo: 'Sin conexión',
                          mensaje: 'No se pudieron cargar los clientes.',
                          textoAccion: 'Reintentar',
                          alTocar: _cargar,
                        )
                      : _clientes.isEmpty
                          ? EstadoVacio(
                              icono: Icons.people_outline,
                              titulo: 'Sin clientes',
                              mensaje: 'Agrega tu primer cliente.',
                              textoAccion: 'Nuevo cliente',
                              alTocar: _nuevoCliente,
                            )
                          : RefreshIndicator(
                              onRefresh: _cargar,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    spacingMd, spacingMd, spacingMd, spacingLg),
                                itemCount: _clientes.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: spacingSm),
                                itemBuilder: (context, i) => _TarjetaCliente(
                                  cliente: _clientes[i],
                                  alTocar: () => _editar(_clientes[i]),
                                  alToggle: () => _toggleEstado(_clientes[i]),
                                  alEliminar: () => _eliminar(_clientes[i]),
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FabExtendido(
        titulo: 'Nuevo',
        icono: Icons.person_add,
        alTocar: _nuevoCliente,
      ),
    );
  }
}

class _TarjetaCliente extends StatelessWidget {
  final Map<String, dynamic> cliente;
  final VoidCallback alTocar;
  final VoidCallback alToggle;
  final VoidCallback alEliminar;

  const _TarjetaCliente({
    required this.cliente,
    required this.alTocar,
    required this.alToggle,
    required this.alEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    final activo = cliente['estado'] == true;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radiusLg),
        onTap: alTocar,
        child: Ink(
          padding: const EdgeInsets.all(spacingMd),
          decoration: BoxDecoration(
            color: paleta.card,
            borderRadius: BorderRadius.circular(radiusLg),
            border: Border.all(
              color: activo ? paleta.borderSubtle : paleta.border,
            ),
            boxShadow: paleta.sombraCard(),
          ),
          child: Row(
            children: [
              Chat(nombre: cliente['nombre']?.toString(), tamanho: 46),
              const SizedBox(width: spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            cliente['nombre']?.toString() ?? '',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!activo) ...[
                          const SizedBox(width: spacingSm),
                          Badge(
                            texto: 'Inactivo',
                            color: paleta.textMuted,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (cliente['telefono']
                                ?.toString()
                                .isNotEmpty ??
                            false)
                          cliente['telefono'].toString(),
                        if (cliente['documento']
                                ?.toString()
                                .isNotEmpty ??
                            false)
                          cliente['documento'].toString(),
                      ].join(' · '),
                      style:
                          TextStyle(color: paleta.textMuted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(activo ? 'Desactivar' : 'Activar'),
                  ),
                  const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                ],
                onSelected: (v) {
                  if (v == 'editar') alTocar();
                  if (v == 'toggle') alToggle();
                  if (v == 'eliminar') alEliminar();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}