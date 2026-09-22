import 'package:flutter/material.dart' hide Badge;
import 'package:url_launcher/url_launcher.dart';

import '../services/ventas.dart';
import '../theme/tokens.dart';
import '../theme/theme_provider.dart';
import '../utils/formato.dart';
import '../widgets/iconos.dart';
import '../widgets/ui.dart';

class CuentasScreen extends StatefulWidget {
  const CuentasScreen({super.key});

  @override
  State<CuentasScreen> createState() => _CuentasScreenState();
}

class _CuentasScreenState extends State<CuentasScreen> {
  bool _cargando = true;
  bool _error = false;
  String _estado = 'PENDIENTE';

  List<Map<String, dynamic>> _deudas = [];

  static const Map<String, String> _filtros = {
    'PENDIENTE': 'Pendientes',
    'PAGADA': 'Pagadas',
    'ANULADA': 'Anuladas',
  };

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = false;
    });
    try {
      final res = await deudasService.listar({
        'estado': _estado,
      });
      if (!mounted) return;
      setState(() {
        _deudas = (res.data as List).cast<Map<String, dynamic>>();
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

  Future<void> _abrirDetalle(Map<String, dynamic> d) async {
    final cambio = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DialogoDeuda(deuda: d, alRecargar: _cargar),
    );
    if (cambio == true) _cargar();
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
                      const Expanded(
                        child: Text('Cuentas por cobrar',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w800)),
                      ),
                      Text(
                        '${_deudas.length}',
                        style: TextStyle(
                            color: paleta.gold,
                            fontSize: 16,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: spacingMd),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _filtros.entries.map((e) {
                        final activo = _estado == e.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: spacingSm),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(radiusPill),
                            onTap: () {
                              _estado = e.key;
                              _cargar();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: spacingMd, vertical: spacingSm),
                              decoration: BoxDecoration(
                                color:
                                    activo ? paleta.gold : paleta.cardLight,
                                borderRadius:
                                    BorderRadius.circular(radiusPill),
                                border: Border.all(
                                  color: activo
                                      ? paleta.gold
                                      : paleta.borderSubtle,
                                ),
                              ),
                              child: Text(
                                e.value,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: activo
                                      ? paleta.sobreDorado
                                      : paleta.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
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
                          mensaje: 'No se pudieron cargar las deudas.',
                          textoAccion: 'Reintentar',
                          alTocar: _cargar,
                        )
                      : _deudas.isEmpty
                          ? const EstadoVacio(
                              icono: Icons.receipt_long_outlined,
                              titulo: 'Sin deudas',
                              mensaje:
                                  'Las cuentas por cobrar aparecerán aquí.',
                            )
                          : RefreshIndicator(
                              onRefresh: _cargar,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    spacingMd, spacingMd, spacingMd, spacingLg),
                                itemCount: _deudas.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: spacingSm),
                                itemBuilder: (context, i) =>
                                    _TarjetaDeuda(
                                  deuda: _deudas[i],
                                  alTocar: () => _abrirDetalle(_deudas[i]),
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaDeuda extends StatelessWidget {
  final Map<String, dynamic> deuda;
  final VoidCallback alTocar;

  const _TarjetaDeuda({required this.deuda, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    final pendiente = deuda['estado'] == 'PENDIENTE';
    final fecha = parseandoFecha(deuda['fecha_inicio']);
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
            border: Border.all(color: paleta.borderSubtle),
            boxShadow: paleta.sombraCard(),
          ),
          child: Row(
            children: [
              Chat(nombre: deuda['cliente_nombre']?.toString(), tamanho: 46),
              const SizedBox(width: spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            deuda['cliente_nombre']?.toString() ?? '',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        '${deuda['venta_numero']}',
                        if (fecha != null) fechaCorta(fecha.toLocal()),
                      ].join(' · '),
                      style:
                          TextStyle(color: paleta.textMuted, fontSize: 11.5),
                    ),
                    const SizedBox(height: spacingSm),
                    Row(
                      children: [
                        Badge(
                          texto: texti(deuda['estado']?.toString(), {
                            'PENDIENTE': 'Pendiente',
                            'PAGADA': 'Pagada',
                            'ANULADA': 'Anulada',
                          }),
                          color: pendiente
                              ? paleta.warning
                              : (deuda['estado'] == 'PAGADA'
                                  ? paleta.success
                                  : paleta.danger),
                        ),
                        const Spacer(),
                        Text(
                          fmtMoney(deuda['saldo_pendiente']),
                          style: TextStyle(
                            color:
                                pendiente ? paleta.warning : paleta.success,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogoDeuda extends StatefulWidget {
  final Map<String, dynamic> deuda;
  final VoidCallback alRecargar;

  const _DialogoDeuda({required this.deuda, required this.alRecargar});

  @override
  State<_DialogoDeuda> createState() => _DialogoDeudaState();
}

class _DialogoDeudaState extends State<_DialogoDeuda> {
  final _monto = TextEditingController();
  String _metodo = 'EFECTIVO';
  bool _abonando = false;

  Map<String, dynamic> get _d => widget.deuda;

  bool get _pendiente => _d['estado'] == 'PENDIENTE';

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _abonar() async {
    final monto = double.tryParse(_monto.text);
    if (monto == null || monto <= 0) {
      snaki(context, 'Ingresa un monto válido', ok: false);
      return;
    }
    final saldo = numADouble(_d['saldo_pendiente']);
    if (monto > saldo + 0.01) {
      snaki(context, 'El abono supera el saldo pendiente', ok: false);
      return;
    }
    setState(() => _abonando = true);
    try {
      final res = await deudasService.abonar(_d['id'] as int, {
        'monto': monto.toStringAsFixed(2),
        'metodo': _metodo,
      });
      if (!mounted) return;
      snaki(context, 'Abono registrado');
      widget.alRecargar();
      final nuevoSaldo = numADouble((res.data as Map)['saldo_pendiente']);
      if (nuevoSaldo <= 0) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _abonando = false);
      snaki(context, 'No se pudo registrar el abono', ok: false);
    }
  }

  Future<void> _whatsapp() async {
    final telefono = normalizarTelefono(_d['cliente_telefono']);
    if (telefono.isEmpty) return;
    final uri = Uri.parse('https://wa.me/$telefono');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) snaki(context, 'No se pudo abrir WhatsApp', ok: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    final abonos = (_d['abonos'] as List? ?? []).cast<Map<String, dynamic>>();
    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text(
              _d['cliente_nombre']?.toString() ?? 'Deuda',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Badge(
            texto: _pendiente ? 'Pendiente' : 'Cancelada',
            color: _pendiente ? paleta.warning : paleta.success,
          ),
          IconButton(
            onPressed: _whatsapp,
            tooltip: 'WhatsApp',
            icon: const IconoWhatsApp(tamanho: 20, color: Color(0xFF25D366)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [_d['venta_numero']?.toString() ?? '',
                  if (_d['fecha_inicio'] != null)
                    fechaCorta(parseandoFecha(_d['fecha_inicio'])!.toLocal())]
                  .join(' · '),
              style: TextStyle(color: paleta.textMuted, fontSize: 12.5),
            ),
            const SizedBox(height: spacingMd),
            Row(
              children: [
                Text('Original: ${fmtMoney(_d['monto_original'])}',
                    style: const TextStyle(fontSize: 12.5)),
                const Spacer(),
                Text('Saldo: ',
                    style: TextStyle(
                        color: paleta.textMuted, fontSize: 12.5)),
                Text(fmtMoney(_d['saldo_pendiente']),
                    style: TextStyle(
                        color: _pendiente
                            ? paleta.warning
                            : paleta.success,
                        fontWeight: FontWeight.w800)),
              ],
            ),
            if (abonos.isNotEmpty) ...[
              const Divider(height: spacingLg),
              Text('Abonos',
                  style: TextStyle(
                      color: paleta.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: spacingSm),
              for (final a in abonos)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          texti(a['metodo'], {
                            'EFECTIVO': 'Efectivo',
                            'TARJETA': 'Tarjeta',
                            'TRANSFERENCIA': 'Transferencia',
                          }),
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                      Text('${a['usuario_nombre']} ',
                          style: TextStyle(
                              color: paleta.textMuted, fontSize: 11)),
                      Text(fmtMoney(a['monto']),
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
            if (_pendiente) ...[
              const Divider(height: spacingLg),
              Row(
                children: [
                  Expanded(
                    child: CampoTexto(
                      etiqueta: 'Monto abono',
                      controlador: _monto,
                      esDinero: true,
                    ),
                  ),
                  const SizedBox(width: spacingSm),
                  Choizon(metodo: _metodo, alCambiar: (m) {
                    setState(() => _metodo = m);
                  }),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_pendiente) ...[
          TextButton(
            onPressed: _abonando ? null : _abonar,
            child: _abonando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Abonar'),
          ),
        ],
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class Choizon extends StatelessWidget {
  final String metodo;
  final ValueChanged<String> alCambiar;

  const Choizon({required this.metodo, required this.alCambiar});

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return PopupMenuButton<String>(
      initialValue: metodo,
      onSelected: alCambiar,
      itemBuilder: (_) => const [
        PopupMenuItem<String>(
          value: 'EFECTIVO',
          child: Text('Efectivo'),
        ),
        PopupMenuItem<String>(
          value: 'TARJETA',
          child: Text('Tarjeta'),
        ),
        PopupMenuItem<String>(
          value: 'TRANSFERENCIA',
          child: Text('Transferencia'),
        ),
      ],
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingMd),
        decoration: BoxDecoration(
          color: paleta.cardLight,
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              texti(metodo, {
                'EFECTIVO': 'Efectivo',
                'TARJETA': 'Tarjeta',
                'TRANSFERENCIA': 'Transferencia',
              }),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: spacingSm),
            Icon(Icons.arrow_drop_down, color: paleta.textMuted),
          ],
        ),
      ),
    );
  }
}