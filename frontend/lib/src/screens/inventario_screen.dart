import 'package:flutter/material.dart';

import '../navigation/main_shell.dart';
import '../services/inventario.dart';
import '../theme/tokens.dart';
import '../theme/theme_provider.dart';
import '../utils/formato.dart';
import '../widgets/ui.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen>
    with RefrescaAlFoco<InventarioScreen> {
  bool _cargando = true;
  bool _error = false;
  String _busqueda = '';

  List<Map<String, dynamic>> _productos = [];

  @override
  void initState() {
    super.initState();
    suscribirAlFoco(2);
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
      final res = await productosService.listar({
        if (_busqueda.isNotEmpty) 'search': _busqueda,
      });
      if (!mounted) return;
      setState(() {
        _productos = (res.data as List).cast<Map<String, dynamic>>();
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

  Future<void> _ajustar(Map<String, dynamic> p) async {
    final cambio = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DialogoAjuste(producto: p),
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
                        child: Text('Inventario',
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w800)),
                      ),
                      Text(
                        '${_productos.length}',
                        style: TextStyle(
                            color: paleta.gold,
                            fontSize: 16,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: spacingMd),
                  CampoBuscar(
                    alCambiar: (t) {
                      _busqueda = t;
                      _cargar();
                    },
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
                          mensaje: 'No se pudo cargar el inventario.',
                          textoAccion: 'Reintentar',
                          alTocar: _cargar,
                        )
                      : _productos.isEmpty
                          ? const EstadoVacio(
                              icono: Icons.inventory_2_outlined,
                              titulo: 'Sin stock',
                              mensaje: 'No hay productos registrados.',
                            )
                          : RefreshIndicator(
                              onRefresh: _cargar,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    spacingMd, spacingMd, spacingMd, spacingLg),
                                itemCount: _productos.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: spacingSm),
                                itemBuilder: (context, i) => _TarjetaStock(
                                  producto: _productos[i],
                                  alAjustar: () => _ajustar(_productos[i]),
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

class _TarjetaStock extends StatelessWidget {
  final Map<String, dynamic> producto;
  final VoidCallback alAjustar;

  const _TarjetaStock({required this.producto, required this.alAjustar});

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    final stock = numAInt(producto['stock_actual']);
    final minimo = numAInt(producto['stock_minimo']);
    final bajo = stock <= minimo;
    return Container(
      padding: const EdgeInsets.all(spacingMd),
      decoration: BoxDecoration(
        color: paleta.card,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: paleta.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(producto['nombre']?.toString() ?? '',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('Stock mínimo: $minimo',
                    style:
                        TextStyle(fontSize: 11, color: paleta.textMuted)),
                const SizedBox(height: spacingSm),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: spacingSm, vertical: 4),
                      decoration: BoxDecoration(
                        color: bajo
                            ? paleta.danger.withValues(alpha: 0.12)
                            : paleta.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(radiusPill),
                      ),
                      child: Text(
                        '$stock un.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: bajo ? paleta.danger : paleta.gold,
                        ),
                      ),
                    ),
                    if (bajo) ...[
                      const SizedBox(width: spacingSm),
                      Text('bajo',
                          style: TextStyle(
                              fontSize: 11,
                              color: paleta.danger,
                              fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: alAjustar,
            borderRadius: BorderRadius.circular(radiusXl),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: spacingMd, vertical: spacingSm),
              decoration: BoxDecoration(
                color: paleta.gold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(radiusXl),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, size: 16, color: paleta.gold),
                  const SizedBox(width: 6),
                  Text(
                    'Ajustar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: paleta.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogoAjuste extends StatefulWidget {
  final Map<String, dynamic> producto;

  const _DialogoAjuste({required this.producto});

  @override
  State<_DialogoAjuste> createState() => _DialogoAjusteState();
}

class _DialogoAjusteState extends State<_DialogoAjuste> {
  final _cantidad = TextEditingController();
  final _motivo = TextEditingController();
  String _tipo = 'ENTRADA';
  bool _guardando = false;

  static const Map<String, String> _tipos = {
    'ENTRADA': 'Entrada',
    'SALIDA': 'Salida',
    'AJUSTE': 'Fijar a',
  };

  int get _stockActual => numAInt(widget.producto['stock_actual']);

  @override
  void dispose() {
    _cantidad.dispose();
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_tipo != 'AJUSTE') {
      final cant = int.tryParse(_cantidad.text);
      if (cant == null || cant <= 0) {
        snaki(context, 'Ingresa una cantidad válida', ok: false);
        return;
      }
      if (_tipo == 'SALIDA' && cant > _stockActual) {
        snaki(context, 'No hay suficiente stock', ok: false);
        return;
      }
    } else {
      final cant = int.tryParse(_cantidad.text);
      if (cant == null || cant < 0) {
        snaki(context, 'Ingresa el stock exacto', ok: false);
        return;
      }
    }
    setState(() => _guardando = true);
    try {
      final payload = _tipo == 'AJUSTE'
          ? {
              'producto': widget.producto['id'],
              'tipo_movimiento': 'AJUSTE',
              'cantidad': int.parse(_cantidad.text),
              if (_motivo.text.trim().isNotEmpty) 'motivo': _motivo.text.trim(),
            }
          : {
              'producto': widget.producto['id'],
              'tipo_movimiento': _tipo,
              'cantidad': int.parse(_cantidad.text),
              if (_motivo.text.trim().isNotEmpty) 'motivo': _motivo.text.trim(),
            };
      final res = await movimientosService.ajustar(payload);
      if (!mounted) return;
      final stockNuevo = (res.data as Map)['stock_actual'];
      snaki(context, 'Stock actualizado a $stockNuevo');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      snaki(context, 'No se pudo ajustar el stock', ok: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return AlertDialog(
      title: Text('Ajustar: ${widget.producto['nombre']}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stock actual: $_stockActual',
              style: TextStyle(color: paleta.textMuted, fontSize: 13)),
          const SizedBox(height: spacingMd),
          Wrap(
            spacing: spacingSm,
            children: _tipos.keys.map((t) {
              final seleccionado = t == _tipo;
              return ChoiceChip(
                label: Text(_tipos[t] ?? t),
                selected: seleccionado,
                selectedColor: paleta.gold,
                labelStyle: TextStyle(
                  color: seleccionado ? paleta.sobreDorado : paleta.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                onSelected: (_) => setState(() => _tipo = t),
              );
            }).toList(),
          ),
          const SizedBox(height: spacingMd),
          CampoTexto(
            etiqueta: _tipo == 'AJUSTE'
                ? 'Nuevo stock exacto'
                : 'Cantidad',
            controlador: _cantidad,
            esNumero: true,
            centrar: true,
          ),
          const SizedBox(height: spacingSm),
          CampoTexto(
            etiqueta: 'Motivo (opcional)',
            controlador: _motivo,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _guardando
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}