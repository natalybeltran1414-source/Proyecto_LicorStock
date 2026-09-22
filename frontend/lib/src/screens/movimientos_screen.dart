import 'package:flutter/material.dart' hide Badge;

import '../navigation/main_shell.dart';
import '../services/inventario.dart';
import '../theme/tokens.dart';
import '../theme/theme_provider.dart';
import '../utils/formato.dart';
import '../widgets/ui.dart';

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen>
    with RefrescaAlFoco<MovimientosScreen> {
  bool _cargando = true;
  bool _error = false;
  String _tipo = '';

  List<Map<String, dynamic>> _movimientos = [];

  static const Map<String, String> _filtros = {
    '': 'Todos',
    'ENTRADA': 'Entradas',
    'SALIDA': 'Salidas',
    'AJUSTE': 'Ajustes',
  };

  @override
  void initState() {
    super.initState();
    suscribirAlFoco(3);
    _cargar();
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
      final res = await movimientosService.listar({
        if (_tipo.isNotEmpty) 'tipo': _tipo,
      });
      if (!mounted) return;
      setState(() {
        _movimientos = (res.data as List).cast<Map<String, dynamic>>();
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
                        child: Text('Movimientos',
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w800)),
                      ),
                      Text(
                        '${_movimientos.length}',
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
                        final activo = _tipo == e.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: spacingSm),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(radiusPill),
                            onTap: () {
                              _tipo = e.key;
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
                          mensaje: 'No se pudieron cargar los movimientos.',
                          textoAccion: 'Reintentar',
                          alTocar: _cargar,
                        )
                      : _movimientos.isEmpty
                          ? const EstadoVacio(
                              icono: Icons.swap_horiz,
                              titulo: 'Sin movimientos',
                              mensaje:
                                  'Los cambios de stock aparecerán aquí.',
                            )
                          : RefreshIndicator(
                              onRefresh: _cargar,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    spacingMd, spacingMd, spacingMd, spacingLg),
                                itemCount: _movimientos.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: spacingSm),
                                itemBuilder: (context, i) =>
                                    _TarjetaMovimiento(
                                  m: _movimientos[i],
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

class _TarjetaMovimiento extends StatelessWidget {
  final Map<String, dynamic> m;

  const _TarjetaMovimiento({required this.m});

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    final tipo = m['tipo_movimiento']?.toString() ?? '';
    final cantidad = numAInt(m['cantidad']);
    final esEntrada = tipo == 'ENTRADA';
    final esSalida = tipo == 'SALIDA';
    final color = esEntrada
        ? paleta.success
        : (esSalida ? paleta.danger : paleta.warning);
    final icono = esEntrada
        ? Icons.arrow_downward
        : (esSalida ? Icons.arrow_upward : Icons.tune);
    final fecha = parseandoFecha(m['fecha']);
    return Container(
      padding: const EdgeInsets.all(spacingMd),
      decoration: BoxDecoration(
        color: paleta.card,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: paleta.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(radiusMd),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(width: spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m['producto_nombre']?.toString() ?? '',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  [
                    if (m['motivo']?.toString().isNotEmpty ?? false)
                      m['motivo'].toString(),
                    if (fecha != null) etiquetaFechaMov(fecha.toLocal()),
                  ].join(' · '),
                  style: TextStyle(color: paleta.textMuted, fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: spacingSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Badge(
                texto: texti(tipo, {
                  'ENTRADA': 'Entrada',
                  'SALIDA': 'Salida',
                  'AJUSTE': 'Ajuste',
                }),
                color: color,
                icono: icono,
              ),
              const SizedBox(height: 4),
              Text(
                esEntrada ? '+$cantidad' : (esSalida ? '-$cantidad' : '$cantidad'),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}