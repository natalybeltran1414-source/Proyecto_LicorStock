import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api.dart';
import '../services/inventario.dart';
import '../theme/tokens.dart';
import '../theme/theme_provider.dart';
import '../widgets/ui.dart';

class ProductoFormScreen extends StatefulWidget {
  const ProductoFormScreen({super.key});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  final _compra = TextEditingController();
  final _venta = TextEditingController();
  final _minimo = TextEditingController();
  final _stock = TextEditingController();

  Map<String, dynamic>? _producto;
  List<Map<String, dynamic>> _categorias = [];
  int? _categoriaId;
  String _unidad = 'UNIDAD';
  String? _imagenUrl;
  XFile? _imagenNueva;
  bool _estado = true;
  bool _cargando = true;
  bool _guardando = false;
  Map<String, String> _errores = {};

  bool get _editando => _producto != null;

  static const Map<String, String> _unidadesEtiqueta = {
    'UNIDAD': 'Unidad',
    'ML': 'Mililitros',
    'LT': 'Litros',
    'KG': 'Kilogramos',
    'G': 'Gramos',
    'CAJA': 'Caja',
    'PACK': 'Pack',
    'SIXPACK': 'Sixpack',
  };

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) _producto = args;
      final res = await categoriasService.listar();
      if (!mounted) return;
      _categorias = ((res.data as List).cast<Map<String, dynamic>>())
          .where((c) => c['estado'] == true)
          .toList();
      final p = _producto;
      if (p != null) {
        _nombre.text = p['nombre']?.toString() ?? '';
        _descripcion.text = p['descripcion']?.toString() ?? '';
        _compra.text = _montoATexto(p['precio_compra']);
        _venta.text = _montoATexto(p['precio_venta']);
        _minimo.text = p['stock_minimo']?.toString() ?? '';
        _stock.text = p['stock_actual']?.toString() ?? '';
        _categoriaId = p['categoria'] as int?;
        _unidad = p['unidad']?.toString() ?? 'UNIDAD';
        _imagenUrl = p['imagen']?.toString();
        _estado = p['estado'] == true;
      }
      setState(() => _cargando = false);
    });
  }

  String _montoATexto(Object? v) {
    if (v == null) return '';
    final s = v.toString();
    return s.endsWith('.0') ? s.replaceFirst('.0', '') : s;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _compra.dispose();
    _venta.dispose();
    _minimo.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _elegirImagen() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;
    setState(() => _imagenNueva = picked);
  }

  Future<void> _quitarImagen() async {
    try {
      if (_producto != null && (_imagenUrl != null || _imagenNueva != null)) {
        await productosService.quitarImagen(_producto!['id'] as int);
      }
      if (!mounted) return;
      setState(() {
        _imagenUrl = null;
        _imagenNueva = null;
      });
      snaki(context, 'Imagen eliminada');
    } catch (_) {
      if (!mounted) return;
      snaki(context, 'No se pudo eliminar la imagen', ok: false);
    }
  }

  Future<void> _guardar() async {
    final nombre = _nombre.text.trim();
    final venta = double.tryParse(_venta.text) ?? 0;
    if (nombre.isEmpty) {
      setState(() => _errores = {'nombre': 'El nombre es obligatorio'});
      return;
    }
    if (venta <= 0) {
      setState(() => _errores = {'venta': 'El precio de venta debe ser mayor a 0'});
      return;
    }
    setState(() {
      _guardando = true;
      _errores = {};
    });
    final datos = <String, dynamic>{
      'nombre': nombre,
      'categoria': _categoriaId,
      'descripcion': _descripcion.text.trim(),
      'precio_compra': (double.tryParse(_compra.text) ?? 0).toString(),
      'precio_venta': venta.toString(),
      'stock_minimo': int.tryParse(_minimo.text) ?? 0,
      'stock_actual': int.tryParse(_stock.text) ?? 0,
      'unidad': _unidad,
      'estado': _estado,
    };
    try {
      int id;
      if (_editando) {
        final res = await productosService.actualizar(_producto!['id'] as int, datos);
        id = (res.data as Map)['id'] as int;
      } else {
        datos.remove('estado');
        final res = await productosService.crear(datos);
        id = (res.data as Map)['id'] as int;
      }
      if (_imagenNueva != null) {
        await productosService.subirImagen(id, _imagenNueva!);
      }
      if (!mounted) return;
      snaki(context, _editando ? 'Producto actualizado' : 'Producto creado');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      if (e is DioException) {
        final mensaje = msgObjetoCampo(e.response?.data);
        snaki(context, mensaje, ok: false);
      } else {
        snaki(context, 'No se pudo guardar el producto', ok: false);
      }
    }
  }

  Future<void> _crearCategoria() async {
    final nombreCtrl = TextEditingController();
    Color? color;
    final nombre = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva categoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: spacingMd),
            TextButton.icon(
              onPressed: () async {
                final elegido = await dialogoColores(ctx);
                if (elegido != null) color = elegido;
              },
              icon: CircleAvatar(
                radius: 10,
                backgroundColor: color ?? Colors.transparent,
                child: color == null
                    ? const SizedBox()
                    : const SizedBox.shrink(),
              ),
              label: const Text('Elegir color'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(nombreCtrl.text.trim()),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (nombre == null || nombre.isEmpty || !mounted) return;
    final hex = color == null
        ? '#C9A227'
        : '#${(color!.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    try {
      final res = await categoriasService.crear({
        'nombre': nombre,
        'color': hex,
      });
      final creada = Map<String, dynamic>.from(res.data as Map);
      setState(() {
        _categorias.add(creada);
        _categoriaId = creada['id'] as int;
      });
    } catch (_) {
      if (!mounted) return;
      snaki(context, 'No se pudo crear la categoría', ok: false);
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
        title: Text(_editando ? 'Editar producto' : 'Nuevo producto',
            style: const TextStyle(fontWeight: FontWeight.w800)),
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
                  CampoImagen(
                    url: _imagenNueva == null ? _imagenUrl : null,
                    alElegir: _elegirImagen,
                    alQuitar: (_imagenUrl != null || _imagenNueva != null)
                        ? _quitarImagen
                        : null,
                  ),
                  const SizedBox(height: spacingMd),
                  CampoTexto(
                    etiqueta: 'Nombre',
                    controlador: _nombre,
                    error: _errores['nombre'],
                    textoTeclado: TextInputType.text,
                  ),
                  const SizedBox(height: spacingMd),
                  _SeccionUnidad(
                    unidad: _unidad,
                    etiquetas: _unidadesEtiqueta,
                    alElegir: (u) => setState(() => _unidad = u),
                  ),
                  const SizedBox(height: spacingMd),
                  Row(
                    children: [
                      Expanded(
                        child: CampoTexto(
                          etiqueta: 'Precio compra',
                          controlador: _compra,
                          esDinero: true,
                          prefijo: r'$',
                        ),
                      ),
                      const SizedBox(width: spacingSm),
                      Expanded(
                        child: CampoTexto(
                          etiqueta: 'Precio venta',
                          controlador: _venta,
                          esDinero: true,
                          prefijo: r'$',
                          error: _errores['venta'],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: spacingMd),
                  Row(
                    children: [
                      Expanded(
                        child: CampoTexto(
                          etiqueta: 'Stock mínimo',
                          controlador: _minimo,
                          esNumero: true,
                        ),
                      ),
                      const SizedBox(width: spacingSm),
                      Expanded(
                        child: CampoTexto(
                          etiqueta: _editando
                              ? 'Stock actual'
                              : 'Stock inicial',
                          controlador: _stock,
                          esNumero: true,
                          habilitado: !_editando,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: spacingMd),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Categoría',
                      style: TextStyle(
                        color: paleta.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: spacingSm),
                  Wrap(
                    spacing: spacingSm,
                    runSpacing: spacingSm,
                    children: [
                      for (final c in _categorias)
                        ChoiceChip(
                          label: Text(c['nombre']?.toString() ?? ''),
                          selected: _categoriaId == c['id'],
                          selectedColor: paleta.gold,
                          labelStyle: TextStyle(
                            color: _categoriaId == c['id']
                                ? paleta.sobreDorado
                                : paleta.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          onSelected: (_) =>
                              setState(() => _categoriaId = c['id'] as int),
                        ),
                      ActionChip(
                        avatar: Icon(Icons.add, size: 16, color: paleta.gold),
                        label: const Text('Nueva'),
                        onPressed: _crearCategoria,
                      ),
                    ],
                  ),
                  const SizedBox(height: spacingMd),
                  CampoTexto(
                    etiqueta: 'Descripción',
                    controlador: _descripcion,
                    maxLineas: 3,
                    textoTeclado: TextInputType.multiline,
                    accion: TextInputAction.newline,
                  ),
                  if (_editando) ...[
                    const SizedBox(height: spacingMd),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Producto activo',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      value: _estado,
                      onChanged: (v) => setState(() => _estado = v),
                    ),
                  ],
                  const SizedBox(height: spacingLg),
                  BotonSolido(
                    titulo: _editando ? 'Guardar cambios' : 'Crear producto',
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

class _SeccionUnidad extends StatelessWidget {
  final String unidad;
  final Map<String, String> etiquetas;
  final ValueChanged<String> alElegir;

  const _SeccionUnidad({
    required this.unidad,
    required this.etiquetas,
    required this.alElegir,
  });

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unidad de medida',
          style: TextStyle(
            color: paleta.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: spacingSm),
        Wrap(
          spacing: spacingSm,
          runSpacing: spacingSm,
          children: etiquetas.keys.map((u) {
            final seleccionada = u == unidad;
            return ChoiceChip(
              label: Text(etiquetas[u] ?? u),
              selected: seleccionada,
              selectedColor: paleta.gold,
              labelStyle: TextStyle(
                color: seleccionada ? paleta.sobreDorado : paleta.text,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              onSelected: (_) => alElegir(u),
            );
          }).toList(),
        ),
      ],
    );
  }
}