import 'dart:async';

import 'package:flutter/material.dart';

import '../navigation/app_router.dart';
import '../services/clientes.dart';
import '../services/inventario.dart';
import '../services/ventas.dart';
import '../theme/tokens.dart';
import '../theme/theme_provider.dart';
import '../utils/formato.dart';
import '../widgets/ui.dart';

class VentaNuevaScreen extends StatefulWidget {
  const VentaNuevaScreen({super.key});

  @override
  State<VentaNuevaScreen> createState() => _VentaNuevaScreenState();
}

class _VentaNuevaScreenState extends State<VentaNuevaScreen> {
  final _busqueda = TextEditingController();
  final _efectivo = TextEditingController();
  final _tarjeta = TextEditingController();
  final _transferencia = TextEditingController();
  final _busquedaCliente = TextEditingController();

  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _resultados = [];
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _clientesFiltrados = [];

  final List<_ItemVenta> _items = [];
  Map<String, dynamic>? _cliente;
  bool _mostrarClientes = false;
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
    _cargarClientes();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    _efectivo.dispose();
    _tarjeta.dispose();
    _transferencia.dispose();
    _busquedaCliente.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    try {
      final res = await productosService.listar({'estado': 'true'});
      if (!mounted) return;
      setState(() {
        _productos = (res.data as List).cast<Map<String, dynamic>>();
        _cargando = false;
      });
      _buscarProductos('');
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  Future<void> _cargarClientes() async {
    try {
      final res = await clientesService.listar({'estado': 'true'});
      if (!mounted) return;
      setState(() => _clientes = (res.data as List).cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  void _buscarProductos(String texto) {
    final q = texto.trim().toLowerCase();
    setState(() {
      _resultados = q.isEmpty
          ? _productos
          : _productos
              .where((p) =>
                  (p['nombre']?.toString() ?? '').toLowerCase().contains(q))
              .take(8)
              .toList();
    });
  }

  void _buscarClientes(String texto) {
    final q = texto.trim().toLowerCase();
    setState(() {
      _clientesFiltrados = q.isEmpty
          ? _clientes
          : _clientes
              .where((c) =>
                  (c['nombre']?.toString() ?? '')
                      .toLowerCase()
                      .contains(q) ||
                  (c['documento']?.toString() ?? '')
                      .toLowerCase()
                      .contains(q))
              .take(6)
              .toList();
    });
  }

  void _agregar(Map<String, dynamic> p) {
    final existe = _items.indexWhere((it) => it.productoId == p['id']);
    if (existe >= 0) {
      final it = _items[existe];
      final stock = numAInt(p['stock_actual']);
      if (it.cantidad >= stock) {
        snaki(context, 'Stock máximo alcanzado', ok: false);
        return;
      }
      setState(() => it.cantidad += 1);
    } else {
      setState(() => _items.add(_ItemVenta(producto: p)));
    }
  }

  void _quitar(_ItemVenta it) {
    setState(() => _items.remove(it));
  }

  bool _cambiarCantidad(_ItemVenta it, int delta) {
    final stock = numAInt(it.producto['stock_actual']);
    final nuevo = it.cantidad + delta;
    if (nuevo < 1) return false;
    if (nuevo > stock) {
      snaki(context, 'Stock máximo: $stock', ok: false);
      return false;
    }
    setState(() => it.cantidad = nuevo);
    return true;
  }

  double get _total => _items.fold(
      0.0, (sum, it) => sum + numADouble(it.producto['precio_venta']) * it.cantidad);

  double _campo(TextEditingController c) => double.tryParse(c.text) ?? 0;
  double get _pagado =>
      _campo(_efectivo) + _campo(_tarjeta) + _campo(_transferencia);
  double get _saldo => (_total - _pagado).clamp(0, double.infinity);

  void _pagarTodoEfectivo() {
    setState(() {
      _efectivo.text = _total == _total.truncateToDouble()
          ? _total.truncate().toString()
          : _total.toStringAsFixed(2);
      _tarjeta.clear();
      _transferencia.clear();
    });
  }

  void _limpiarPagos() {
    _efectivo.clear();
    _tarjeta.clear();
    _transferencia.clear();
    setState(() {});
  }

  Future<void> _crear() async {
    if (_items.isEmpty) {
      snaki(context, 'Agrega al menos un producto', ok: false);
      return;
    }
    if (_pagado > _total + 0.01) {
      snaki(context, 'Los pagos superan el total', ok: false);
      return;
    }
    if (_saldo > 0.01 && _cliente == null) {
      snaki(context,
          'Para crédito o pago parcial debes elegir un cliente',
          ok: false);
      setState(() => _mostrarClientes = true);
      return;
    }
    final items = <Map<String, dynamic>>[];
    for (final it in _items) {
      items.add({
        'producto': it.productoId,
        'cantidad': it.cantidad,
      });
    }
    final pagos = <Map<String, dynamic>>[];
    void agg(String metodo, TextEditingController c) {
      final monto = _campo(c);
      if (monto > 0) {
        pagos.add({'metodo': metodo, 'monto': monto.toStringAsFixed(2)});
      }
    }

    agg('EFECTIVO', _efectivo);
    agg('TARJETA', _tarjeta);
    agg('TRANSFERENCIA', _transferencia);

    setState(() => _guardando = true);
    try {
      final res = await ventasService.crear({
        if (_cliente != null) 'cliente': _cliente!['id'],
        'items': items,
        'pagos': pagos,
      });
      if (!mounted) return;
      final data = Map<String, dynamic>.from(res.data as Map);
      final huboDeuda = data['deuda'] is Map;
      final conSaldo = numADouble(data['saldo']) > 0;
      snaki(
        context,
        huboDeuda
            ? 'Venta creada. Se registró la deuda del cliente.'
            : 'Venta registrada',
      );
      Navigator.of(context).pop(true);
      if (huboDeuda || conSaldo) {
        await Navigator.of(context).pushNamed(Routes.cuentas);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      snaki(context,
          e.toString().contains('stock')
              ? 'Stock insuficiente para algún producto'
              : 'No se pudo registrar la venta',
          ok: false);
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
        title: const Text('Nueva venta',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _cargando
          ? const Padding(
              padding: EdgeInsets.all(spacingMd),
              child: EsqueletoTarjeta(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CampoBuscar(
                    etiqueta: 'Buscar producto…',
                    alCambiar: (t) {
                      _busqueda.text = t;
                      _buscarProductos(t);
                    },
                  ),
                  const SizedBox(height: spacingMd),
                  if (_resultados.isNotEmpty)
                    _CuadroProductos(
                      resultados: _resultados,
                      alAgregar: _agregar,
                    ),
                  const SizedBox(height: spacingLg),
                  Row(
                    children: [
                      const Text('Productos',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Text('${_items.length}',
                          style: TextStyle(
                              color: paleta.gold,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: spacingMd),
                  if (_items.isEmpty)
                    _CuadroVacio(
                      texto: 'Agrega productos desde arriba.',
                      icono: Icons.shopping_cart_outlined,
                    )
                  else
                    ..._items.map((it) => Padding(
                          padding: const EdgeInsets.only(bottom: spacingSm),
                          child: _FilaItem(
                            item: it,
                            alSumar: () => _cambiarCantidad(it, 1),
                            alRestar: () => _cambiarCantidad(it, -1),
                            alQuitar: () => _quitar(it),
                          ),
                        )),
                  const SizedBox(height: spacingMd),
                  _PanelTotal(
                    total: _total,
                    alPagarTodo: _pagarTodoEfectivo,
                    alLimpiar: _limpiarPagos,
                    efectivo: _efectivo,
                    tarjeta: _tarjeta,
                    transferencia: _transferencia,
                    saldo: _saldo,
                    pagado: _pagado,
                    onPagoCambio: () => setState(() {}),
                  ),
                  const SizedBox(height: spacingLg),
                  _SeccionCliente(
                    mostrando: _mostrarClientes,
                    cliente: _cliente,
                    busqueda: _busquedaCliente,
                    listado: _clientesFiltrados,
                    alBuscar: (t) {
                      _busquedaCliente.text = t;
                      _buscarClientes(t);
                    },
                    alAlternar: () {
                      setState(() => _mostrarClientes = !_mostrarClientes);
                      if (_clientesFiltrados.isEmpty) _buscarClientes('');
                    },
                    alElegir: (c) {
                      setState(() {
                        _cliente = c;
                        _mostrarClientes = false;
                      });
                    },
                    alQuitar: () => setState(() => _cliente = null),
                  ),
                  const SizedBox(height: spacingLg),
                  BotonSolido(
                    titulo:
                        _saldo > 0.01 ? 'Crear venta con deuda' : 'Cobrar y crear venta',
                    icono: Icons.check_circle_outline,
                    cargando: _guardando,
                    alTocar: _crear,
                  ),
                  const SizedBox(height: spacingLg),
                ],
              ),
            ),
    );
  }
}

class _ItemVenta {
  final Map<String, dynamic> producto;
  int cantidad = 1;

  _ItemVenta({required this.producto});

  int get productoId => producto['id'] as int;
}

class _CuadroProductos extends StatelessWidget {
  final List<Map<String, dynamic>> resultados;
  final ValueChanged<Map<String, dynamic>> alAgregar;

  const _CuadroProductos({required this.resultados, required this.alAgregar});

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return Container(
      decoration: BoxDecoration(
        color: paleta.card,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: paleta.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: resultados
            .map((p) => ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: spacingMd),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: paleta.goldSoft,
                      borderRadius: BorderRadius.circular(radiusSm),
                    ),
                    child: Icon(Icons.local_bar,
                        size: 18, color: paleta.gold),
                  ),
                  title: Text(p['nombre']?.toString() ?? '',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(fmtMoney(p['precio_venta']),
                      style: TextStyle(color: paleta.gold)),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle),
                    color: paleta.success,
                    onPressed: () => alAgregar(p),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _CuadroVacio extends StatelessWidget {
  final String texto;
  final IconData icono;

  const _CuadroVacio({required this.texto, required this.icono});

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return Container(
      padding: const EdgeInsets.all(spacingLg),
      decoration: BoxDecoration(
        color: paleta.cardLight,
        borderRadius: BorderRadius.circular(radiusLg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, color: paleta.textMuted, size: 20),
          const SizedBox(width: spacingSm),
          Text(texto,
              style: TextStyle(color: paleta.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

class _FilaItem extends StatelessWidget {
  final _ItemVenta item;
  final VoidCallback alSumar;
  final VoidCallback alRestar;
  final VoidCallback alQuitar;

  const _FilaItem({
    required this.item,
    required this.alSumar,
    required this.alRestar,
    required this.alQuitar,
  });

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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.producto['nombre']?.toString() ?? '',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(fmtMoney(numADouble(item.producto['precio_venta']) *
                    item.cantidad),
                    style: TextStyle(color: paleta.gold)),
              ],
            ),
          ),
          IconButton(
            onPressed: alRestar,
            icon: const Icon(Icons.remove_circle_outline),
            color: paleta.textMuted,
          ),
          Text('${item.cantidad}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          IconButton(
            onPressed: alSumar,
            icon: const Icon(Icons.add_circle_outline),
            color: paleta.success,
          ),
          IconButton(
            onPressed: alQuitar,
            icon: const Icon(Icons.close),
            color: paleta.textMuted,
          ),
        ],
      ),
    );
  }
}

class _PanelTotal extends StatelessWidget {
  final double total;
  final VoidCallback alPagarTodo;
  final VoidCallback alLimpiar;
  final TextEditingController efectivo;
  final TextEditingController tarjeta;
  final TextEditingController transferencia;
  final double saldo;
  final double pagado;
  final VoidCallback onPagoCambio;

  const _PanelTotal({
    required this.total,
    required this.alPagarTodo,
    required this.alLimpiar,
    required this.efectivo,
    required this.tarjeta,
    required this.transferencia,
    required this.saldo,
    required this.pagado,
    required this.onPagoCambio,
  });

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return Container(
      padding: const EdgeInsets.all(spacingMd),
      decoration: BoxDecoration(
        color: paleta.card,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: paleta.border),
        boxShadow: paleta.sombraCard(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Total a cobrar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(fmtMoney(total),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: spacingMd),
          Row(
            children: [
              const Text('Formas de pago',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton(onPressed: alPagarTodo, child: const Text('Todo en efectivo')),
              TextButton(onPressed: alLimpiar, child: const Text('Limpiar')),
            ],
          ),
          CampoTexto(
            etiqueta: 'Efectivo',
            controlador: efectivo,
            esDinero: true,
            alCambiar: (_) => onPagoCambio(),
          ),
          const SizedBox(height: spacingSm),
          CampoTexto(
            etiqueta: 'Tarjeta',
            controlador: tarjeta,
            esDinero: true,
            alCambiar: (_) => onPagoCambio(),
          ),
          const SizedBox(height: spacingSm),
          CampoTexto(
            etiqueta: 'Transferencia',
            controlador: transferencia,
            esDinero: true,
            alCambiar: (_) => onPagoCambio(),
          ),
          const SizedBox(height: spacingMd),
          Row(
            children: [
              Text('Pagado: ${fmtMoney(pagado)}',
                  style: TextStyle(color: paleta.success, fontSize: 13)),
              const Spacer(),
              if (saldo > 0.01)
                Text('Saldo: ${fmtMoney(saldo)}',
                    style: TextStyle(color: paleta.warning, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeccionCliente extends StatelessWidget {
  final bool mostrando;
  final Map<String, dynamic>? cliente;
  final TextEditingController busqueda;
  final List<Map<String, dynamic>> listado;
  final ValueChanged<String> alBuscar;
  final VoidCallback alAlternar;
  final ValueChanged<Map<String, dynamic>> alElegir;
  final VoidCallback alQuitar;

  const _SeccionCliente({
    required this.mostrando,
    required this.cliente,
    required this.busqueda,
    required this.listado,
    required this.alBuscar,
    required this.alAlternar,
    required this.alElegir,
    required this.alQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Cliente',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const Spacer(),
            if (cliente != null)
              TextButton.icon(
                onPressed: alQuitar,
                icon: const Icon(Icons.close),
                label: const Text('Quitar'),
              )
            else
              TextButton(
                onPressed: alAlternar,
                child: Text(mostrando ? 'Ocultar' : 'Elegir'),
              ),
          ],
        ),
        if (cliente != null)
          Container(
            padding: const EdgeInsets.all(spacingMd),
            decoration: BoxDecoration(
              color: paleta.cardLight,
              borderRadius: BorderRadius.circular(radiusMd),
            ),
            child: Row(
              children: [
                Chat(nombre: cliente!['nombre']?.toString(), tamanho: 40),
                const SizedBox(width: spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cliente!['nombre']?.toString() ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800)),
                      if (cliente!['telefono']?.toString().isNotEmpty ?? false)
                        Text(cliente!['telefono'].toString(),
                            style: TextStyle(
                                color: paleta.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.check_circle, color: paleta.success),
              ],
            ),
          )
        else if (mostrando)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CampoBuscar(
                etiqueta: 'Buscar cliente…',
                valorInicial: busqueda.text,
                alCambiar: alBuscar,
              ),
              const SizedBox(height: spacingMd),
              if (listado.isEmpty)
                const _CuadroVacio(
                  texto: 'Sin clientes. Créalos en la pestaña Clientes.',
                  icono: Icons.people_outline,
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: paleta.card,
                    borderRadius: BorderRadius.circular(radiusLg),
                    border: Border.all(color: paleta.borderSubtle),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: listado
                        .map((c) => ListTile(
                              dense: true,
                              leading: Chat(
                                  nombre: c['nombre']?.toString(),
                                  tamanho: 36),
                              title: Text(c['nombre']?.toString() ?? ''),
                              subtitle: Text(
                                  c['documento']?.toString() ?? ''),
                              onTap: () => alElegir(c),
                            ))
                        .toList(),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}