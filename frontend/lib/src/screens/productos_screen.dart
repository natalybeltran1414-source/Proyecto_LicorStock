import 'dart:async';

import 'package:flutter/material.dart' hide Badge;

import '../navigation/app_router.dart';
import '../navigation/main_shell.dart';
import '../services/inventario.dart';
import '../theme/paleta.dart';
import '../theme/tokens.dart';
import '../theme/theme_provider.dart';
import '../utils/formato.dart';
import '../widgets/ui.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen>
    with RefrescaAlFoco<ProductosScreen> {
  bool _cargando = true;
  bool _error = false;
  String _busqueda = '';
  int? _categoriaId;

  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _categorias = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    suscribirAlFoco(1);
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
      final resCat = await categoriasService.listar();
      final params = <String, dynamic>{
        if (_busqueda.isNotEmpty) 'search': _busqueda,
        if (_categoriaId != null) 'categoria': _categoriaId,
      };
      final resPro = await productosService.listar(params);
      if (!mounted) return;
      setState(() {
        _categorias = (resCat.data as List).cast<Map<String, dynamic>>();
        _productos = (resPro.data as List).cast<Map<String, dynamic>>();
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

  void _filtrarCategoria(int? id) {
    setState(() => _categoriaId = id);
    _cargar();
  }

  Future<void> _crear() async {
    final creadoNuevo = await Navigator.of(context)
        .pushNamed<bool>(Routes.producto);
    if (creadoNuevo == true) _cargar();
  }

  Future<void> _editar(Map<String, dynamic> p) async {
    final cambio = await Navigator.of(context)
        .pushNamed<bool>(Routes.producto, arguments: p);
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
                        child: Text('Productos',
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
                  CampoBuscar(alCambiar: _alBuscar),
                  const SizedBox(height: spacingMd),
                  if (!_cargando && _categorias.isNotEmpty)
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _ChipCategoria(
                            nombre: 'Todos',
                            activo: _categoriaId == null,
                            alTocar: () => _filtrarCategoria(null),
                          ),
                          for (final c in _categorias)
                            _ChipCategoria(
                              nombre: c['nombre']?.toString() ?? '',
                              color: colorDeHex(c['color']),
                              activo: _categoriaId == c['id'],
                              alTocar: () => _filtrarCategoria(c['id'] as int),
                            ),
                        ],
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
                          mensaje: 'No se pudieron cargar los productos.',
                          textoAccion: 'Reintentar',
                          alTocar: _cargar,
                        )
                      : _productos.isEmpty
                          ? EstadoVacio(
                              icono: Icons.inventory_2_outlined,
                              titulo: 'Sin productos',
                              mensaje: 'Agrega tu primer producto.',
                              textoAccion: 'Nuevo producto',
                              alTocar: _crear,
                            )
                          : RefreshIndicator(
                              onRefresh: _cargar,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    spacingMd, spacingMd, spacingMd, spacingLg),
                                itemCount: _productos.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: spacingSm),
                                itemBuilder: (context, i) {
                                  final p = _productos[i];
                                  return _TarjetaProducto(
                                    producto: p,
                                    alTocar: () => _editar(p),
                                    alEliminar: () => _eliminar(p),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: _cargando
          ? null
          : FabExtendido(
              titulo: 'Nuevo',
              icono: Icons.add,
              alTocar: _crear,
            ),
    );
  }

  Future<void> _eliminar(Map<String, dynamic> p) async {
    final ok = await dialogConfirmar(
      context,
      titulo: 'Eliminar producto',
      mensaje:
          '¿Eliminar "${p['nombre']}"? Esta acción no se puede deshacer.',
      textoOk: 'Eliminar',
      peligro: true,
    );
    if (!ok || !mounted) return;
    try {
      await productosService.eliminar(p['id'] as int);
      if (!mounted) return;
      snaki(context, 'Producto eliminado');
      _cargar();
    } catch (_) {
      if (!mounted) return;
      snaki(context, 'No se pudo eliminar el producto', ok: false);
    }
  }
}

class _ChipCategoria extends StatelessWidget {
  final String nombre;
  final Color? color;
  final bool activo;
  final VoidCallback alTocar;

  const _ChipCategoria({
    required this.nombre,
    this.color,
    required this.activo,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return Padding(
      padding: const EdgeInsets.only(right: spacingSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(radiusPill),
        onTap: alTocar,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingSm),
          decoration: BoxDecoration(
            color: activo ? paleta.gold : paleta.cardLight,
            borderRadius: BorderRadius.circular(radiusPill),
            border: Border.all(
              color: activo ? paleta.gold : paleta.borderSubtle,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                nombre,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: activo ? paleta.sobreDorado : paleta.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaProducto extends StatelessWidget {
  final Map<String, dynamic> producto;
  final VoidCallback alTocar;
  final VoidCallback alEliminar;

  const _TarjetaProducto({
    required this.producto,
    required this.alTocar,
    required this.alEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    final bajo = numAInt(producto['stock_actual']) <=
        numAInt(producto['stock_minimo']);
    final activo = producto['estado'] == true;
    final nombre = producto['nombre']?.toString() ?? '';
    final categoria = producto['categoria_nombre']?.toString() ?? '';
    final colorCat = colorDeHex(producto['categoria_color']);
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
              _FotoProducto(producto: producto, tamanho: 60),
              const SizedBox(width: spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (colorCat != null) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorCat,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Flexible(
                          child: Text(
                            categoria.isEmpty ? 'Sin categoría' : categoria,
                            style: TextStyle(
                                fontSize: 12, color: paleta.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: spacingSm),
                    Row(
                      children: [
                        Text(
                          fmtMoney(producto['precio_venta']),
                          style: TextStyle(
                              color: paleta.gold,
                              fontWeight: FontWeight.w800,
                              fontSize: 14),
                        ),
                        if (margenPct(
                                producto['precio_compra'],
                                producto['precio_venta']) !=
                            null) ...[
                          const SizedBox(width: spacingSm),
                          Badge(
                            texto:
                                '${margenPct(producto['precio_compra'], producto['precio_venta'])}%',
                            color: paleta.success,
                          ),
                        ],
                        const Spacer(),
                        Badge(
                          texto: activo ? 'Stock: ${producto['stock_actual']}' : 'Inactivo',
                          color: bajo
                              ? paleta.danger
                              : (activo ? paleta.info : paleta.textMuted),
                          icono: bajo
                              ? Icons.warning_amber
                              : Icons.inventory_2_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'editar', child: Text('Editar')),
                  const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                ],
                onSelected: (v) {
                  if (v == 'editar') alTocar();
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

class _FotoProducto extends StatelessWidget {
  final Map<String, dynamic> producto;
  final double tamanho;

  const _FotoProducto({required this.producto, required this.tamanho});

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    final url = producto['imagen']?.toString();
    final esUrl = url != null && url.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radiusMd),
      child: SizedBox(
        width: tamanho,
        height: tamanho,
        child: esUrl
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _SinFoto(paleta: paleta),
              )
            : _SinFoto(paleta: paleta),
      ),
    );
  }
}

class _SinFoto extends StatelessWidget {
  final Paleta paleta;
  const _SinFoto({required this.paleta});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: paleta.cardLight,
      child: Icon(Icons.local_bar_outlined, color: paleta.textMuted),
    );
  }
}