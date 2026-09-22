import 'dart:async';

import 'package:flutter/material.dart' hide Badge;

import '../navigation/app_router.dart';
import '../navigation/main_shell.dart';
import '../services/ventas.dart';
import '../theme/tokens.dart';
import '../theme/theme_provider.dart';
import '../utils/formato.dart';
import '../widgets/ui.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen>
    with RefrescaAlFoco<VentasScreen> {
  bool _cargando = true;
  bool _error = false;
  String _busqueda = '';
  String _estado = '';
  Timer? _debounce;

  List<Map<String, dynamic>> _ventas = [];

  static const Map<String, String> _filtros = {
    '': 'Todas',
    'COMPLETADA': 'Activas',
    'ANULADA': 'Anuladas',
  };

  @override
  void initState() {
    super.initState();
    suscribirAlFoco(4);
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
      final res = await ventasService.listar({
        if (_busqueda.isNotEmpty) 'search': _busqueda,
        if (_estado.isNotEmpty) 'estado': _estado,
      });
      if (!mounted) return;
      setState(() {
        _ventas = (res.data as List).cast<Map<String, dynamic>>();
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

  Future<void> _nuevaVenta() async {
    await Navigator.of(context).pushNamed(Routes.ventaNueva);
    _cargar();
  }

  Future<void> _abrirDetalle(Map<String, dynamic> v) async {
    final cambio = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DialogoVenta(venta: v, alRecargar: _cargar),
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
                      Expanded(
                        child: Text('Ventas',
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w800)),
                      ),
                      Text(
                        '${_ventas.length}',
                        style: TextStyle(
                            color: paleta.gold,
                            fontSize: 16,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: spacingMd),
                  CampoBuscar(alCambiar: _alBuscar),
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
                          mensaje: 'No se pudieron cargar las ventas.',
                          textoAccion: 'Reintentar',
                          alTocar: _cargar,
                        )
                      : _ventas.isEmpty
                          ? EstadoVacio(
                              icono: Icons.receipt_long_outlined,
                              titulo: 'Sin ventas',
                              mensaje: 'Registra tu primera venta.',
                              textoAccion: 'Nueva venta',
                              alTocar: _nuevaVenta,
                            )
                          : RefreshIndicator(
                              onRefresh: _cargar,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    spacingMd, spacingMd, spacingMd, spacingLg),
                                itemCount: _ventas.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: spacingSm),
                                itemBuilder: (context, i) => _TarjetaVenta(
                                  venta: _ventas[i],
                                  alTocar: () => _abrirDetalle(_ventas[i]),
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FabExtendido(
        titulo: 'Nueva venta',
        icono: Icons.add_shopping_cart,
        alTocar: _nuevaVenta,
      ),
    );
  }
}

class _TarjetaVenta extends StatelessWidget {
  final Map<String, dynamic> venta;
  final VoidCallback alTocar;

  const _TarjetaVenta({required this.venta, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    final activa = venta['estado'] == 'COMPLETADA';
    final cliente = venta['cliente_nombre']?.toString();
    final saldo = numADouble(venta['saldo']);
    final fecha = parseandoFecha(venta['fecha']);
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: paleta.goldSoft,
                  borderRadius: BorderRadius.circular(radiusMd),
                ),
                child:
                    Icon(Icons.receipt_long, color: paleta.gold, size: 20),
              ),
              const SizedBox(width: spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            venta['numero']?.toString() ?? '',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: spacingSm),
                        BadgeEstado(activa: activa, paleta: paleta),
                        if (saldo > 0 && activa) ...[
                          const SizedBox(width: spacingSm),
                          Badge(
                            texto: 'Saldo',
                            color: paleta.warning,
                            icono: Icons.account_balance_wallet_outlined,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        cliente?.isNotEmpty == true ? cliente : 'Consumidor final',
                        if (fecha != null) fechaHora(fecha.toLocal()),
                      ].join(' · '),
                      style: TextStyle(color: paleta.textMuted, fontSize: 11.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: spacingSm),
              Text(
                fmtMoney(venta['total']),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogoVenta extends StatefulWidget {
  final Map<String, dynamic> venta;
  final VoidCallback alRecargar;

  const _DialogoVenta({required this.venta, required this.alRecargar});

  @override
  State<_DialogoVenta> createState() => _DialogoVentaState();
}

class _DialogoVentaState extends State<_DialogoVenta> {
  bool _anulando = false;

  Map<String, dynamic> get _v => widget.venta;

  Future<void> _anular() async {
    final ok = await dialogConfirmar(
      context,
      titulo: 'Anular venta',
      mensaje:
          '¿Anular la venta ${_v['numero']}? El stock se devolverá.',
      textoOk: 'Anular',
      peligro: true,
    );
    if (!ok || !mounted) return;
    setState(() => _anulando = true);
    try {
      await ventasService.anular(_v['id'] as int);
      if (!mounted) return;
      snaki(context, 'Venta anulada');
      widget.alRecargar();
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _anulando = false);
      snaki(context, 'No se pudo anular la venta', ok: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    final activa = _v['estado'] == 'COMPLETADA';
    final detalles = (_v['detalles'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final pagos = (_v['pagos'] as List? ?? []).cast<Map<String, dynamic>>();
    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text(_v['numero']?.toString() ?? 'Venta'),
          ),
          BadgeEstado(activa: activa, paleta: paleta),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                _v['cliente_nombre']?.toString().isNotEmpty == true
                    ? _v['cliente_nombre'].toString()
                    : 'Consumidor final',
                if (_v['fecha'] != null)
                  fechaHora(parseandoFecha(_v['fecha'])!.toLocal()),
              ].join(' · '),
              style: TextStyle(color: paleta.textMuted, fontSize: 12.5),
            ),
            const SizedBox(height: spacingMd),
            for (final d in detalles)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${d['cantidad']} × ${d['nombre_producto']}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(fmtMoney(d['subtotal']),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            const Divider(height: spacingLg),
            if (pagos.isNotEmpty) ...[
              Text('Pagos',
                  style: TextStyle(
                      color: paleta.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: spacingSm),
              for (final pg in pagos)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          texti(pg['metodo'], {
                            'EFECTIVO': 'Efectivo',
                            'TARJETA': 'Tarjeta',
                            'TRANSFERENCIA': 'Transferencia',
                            'CREDITO': 'Crédito',
                          }),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(fmtMoney(pg['monto']),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              const SizedBox(height: spacingSm),
            ],
            Row(
              children: [
                const Spacer(),
                Text('Total',
                    style: TextStyle(
                        color: paleta.textMuted, fontSize: 12.5)),
                const SizedBox(width: spacingMd),
                Text(fmtMoney(_v['total']),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            if (numADouble(_v['saldo']) > 0 && activa) ...[
              const SizedBox(height: spacingSm),
              Row(
                children: [
                  const Spacer(),
                  Text('Saldo pendiente',
                      style: TextStyle(
                          color: paleta.warning, fontSize: 12.5)),
                  const SizedBox(width: spacingMd),
                  Text(fmtMoney(_v['saldo']),
                      style: TextStyle(
                          color: paleta.warning,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (activa)
          TextButton.icon(
            onPressed: _anulando ? null : _anular,
            icon: const Icon(Icons.block),
            label: Text(_anulando ? 'Anulando…' : 'Anular',
                style: TextStyle(color: paleta.danger)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}