import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Badge;

import '../navigation/app_router.dart';
import '../navigation/main_shell.dart';
import '../services/api.dart';
import '../services/inventario.dart';
import '../services/ventas.dart';
import '../theme/paleta.dart';
import '../theme/tokens.dart';
import '../theme/theme_provider.dart';
import '../utils/formato.dart';
import '../widgets/ui.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with RefrescaAlFoco<DashboardScreen> {
  bool _cargando = true;
  bool _error = false;

  int _ventasHoy = 0;
  double _totalHoy = 0;
  int _bajoStock = 0;
  int _unidadesTotales = 0;
  double _porCobrar = 0;

  List<Map<String, dynamic>> _semana = [];
  List<Map<String, dynamic>> _recientes = [];
  List<Map<String, dynamic>> _bajos = [];

  String _nombre = '';
  @override
  void initState() {
    super.initState();
    suscribirAlFoco(0);
    _cargar();
  }

  void _ponerNombre(Map<String, dynamic>? me) {
    final completo =
        (me?['first_name']?.toString() ?? '').trim();
    if (completo.isNotEmpty) {
      _nombre = completo;
    } else {
      _nombre = me?['username']?.toString() ?? '';
    }
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = false;
    });
    try {
      final me = await authService.me();
      _ponerNombre(me);
      final resultados = await Future.wait<dynamic>([
        ventasService.resumen(),
        ventasService.semanal(),
        ventasService.topProductos({'dias': 7}),
        productosService.resumen(),
        productosService.bajoStock(),
        ventasService.listar({'estado': 'COMPLETADA'}),
        deudasService.resumen(),
      ]);
      if (!mounted) return;
      final dv = Map<String, dynamic>.from(resultados[0].data as Map);
      final dp = Map<String, dynamic>.from(resultados[3].data as Map);
      final dResumen = Map<String, dynamic>.from(resultados[6].data as Map);
      setState(() {
        _ventasHoy = numAInt(dv['ventas_hoy']);
        _totalHoy = numADouble(dv['total_hoy']);
        _bajoStock = numAInt(dp['bajo_stock']);
        _semana =
            (resultados[1].data as List).cast<Map<String, dynamic>>();
        _bajos = (resultados[4].data as List).cast<Map<String, dynamic>>();
        _recientes = (resultados[5].data as List)
            .cast<Map<String, dynamic>>()
            .take(3)
            .toList(growable: false);
        _porCobrar = numADouble(dResumen['total_por_cobrar']);
        _unidadesTotales = numAInt(dp['unidades_totales']);
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = true;
      });
    }
  }

  @override
  void alRecobrarFoco() {
    if (!_cargando) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    final hora = DateTime.now().hour;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(spacingMd, spacingMd, spacingMd, 0),
                sliver: SliverToBoxAdapter(
                  child: _Cabecera(
                    saludo: '${saludo(hora)}${_nombre.isEmpty ? '' : ', $_nombre'}',
                    fecha: capitalizar(fechaLarga(DateTime.now())),
                    alPerfil: () => Navigator.of(context)
                        .pushNamed(Routes.perfil)
                        .then((_) => _cargar()),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(spacingMd, spacingLg, spacingMd, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: BotonSolido(
                          titulo: 'Nueva venta',
                          icono: Icons.add_shopping_cart,
                          compacto: true,
                          alTocar: () => Navigator.of(context)
                              .pushNamed(Routes.ventaNueva)
                              .then((_) => _cargar()),
                        ),
                      ),
                      const SizedBox(width: spacingSm),
                      Expanded(
                        child: BotonFantasma(
                          titulo: 'Agregar producto',
                          icono: Icons.add,
                          alTocar: () => Navigator.of(context)
                              .pushNamed(Routes.producto),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_cargando)
                const SliverPadding(
                  padding: EdgeInsets.all(spacingMd),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        EsqueletoTarjeta(),
                        SizedBox(height: spacingMd),
                        EsqueletoTarjeta(),
                      ],
                    ),
                  ),
                )
              else if (_error)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EstadoVacio(
                    icono: Icons.cloud_off,
                    titulo: 'Sin conexión',
                    mensaje: 'No se pudieron cargar los datos.',
                    textoAccion: 'Reintentar',
                    alTocar: _cargar,
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.all(spacingMd),
                  sliver: SliverToBoxAdapter(
                    child: Wrap(
                      spacing: spacingMd,
                      runSpacing: spacingMd,
                      children: [
                        TarjetaInfo(
                          icono: Icons.receipt_long,
                          etiqueta: 'Ventas de hoy',
                          valor: '$_ventasHoy ventas',
                          color: paleta.success,
                          alTocar: () => MainShellScope.of(
                              context, (cambiar) => cambiar(4)),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: TarjetaInfo(
                            icono: Icons.payments_outlined,
                            etiqueta: 'Ingresos de hoy',
                            valor: fmtMoney(_totalHoy),
                            color: paleta.gold,
                            alTocar: () => MainShellScope.of(
                                context, (cambiar) => cambiar(4)),
                          ),
                        ),
                        TarjetaInfo(
                          icono: Icons.inventory_2_outlined,
                          etiqueta: 'En inventario',
                          valor: '$_unidadesTotales unidades',
                          color: paleta.info,
                          alTocar: () => MainShellScope.of(
                              context,
                              (i) => Navigator.of(context)
                                  .pushNamed(Routes.inventario)),
                        ),
                        TarjetaInfo(
                          icono: Icons.account_balance_wallet_outlined,
                          etiqueta: 'Cuentas por cobrar',
                          valor: fmtMoney(_porCobrar),
                          color: paleta.warning,
                          alTocar: () => MainShellScope.of(
                              context,
                              (i) =>
                                  Navigator.of(context).pushNamed(Routes.cuentas)),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: TarjetaInfo(
                            icono: Icons.warning_amber,
                            etiqueta: 'Bajo stock',
                            valor: '$_bajoStock productos',
                            color: paleta.danger,
                            alTocar: () => MainShellScope.of(
                                context,
                                (i) => Navigator.of(context)
                                    .pushNamed(Routes.productos)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_semana.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: spacingMd),
                    sliver: SliverToBoxAdapter(
                      child: _TarjetaSemana(datos: _semana, paleta: paleta),
                    ),
                  ),
                if (_recientes.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.all(spacingMd),
                    sliver: SliverToBoxAdapter(
                      child: _BloqueRecientes(
                        recientes: _recientes,
                        alVerTodos: () => MainShellScope.of(
                            context,
                            (i) => Navigator.of(context)
                                .pushNamed(Routes.ventas)),
                      ),
                    ),
                  ),
                if (_bajos.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(spacingMd, 0, spacingMd, spacingLg),
                    sliver: SliverToBoxAdapter(
                      child: _BloqueBajos(bajos: _bajos, paleta: paleta),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  final String saludo;
  final String fecha;
  final VoidCallback alPerfil;

  const _Cabecera({
    required this.saludo,
    required this.fecha,
    required this.alPerfil,
  });

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LicorStock',
                  style: TextStyle(
                    color: paleta.gold,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontSize: 14,
                  )),
              const SizedBox(height: 6),
              Text(saludo, style: tipoH1),
              const SizedBox(height: 2),
              Text(fecha,
                  style: TextStyle(color: paleta.textMuted, fontSize: 13)),
            ],
          ),
        ),
        BotonIcono(icono: Icons.person_outline, alTocar: alPerfil),
      ],
    );
  }
}

class _TarjetaSemana extends StatelessWidget {
  final List<Map<String, dynamic>> datos;
  final Paleta paleta;

  const _TarjetaSemana({required this.datos, required this.paleta});

  @override
  Widget build(BuildContext context) {
    final maximo = datos
        .map((d) => numADouble(d['total']))
        .fold(0.0, (a, b) => math.max(a, b));
    return Container(
      padding: const EdgeInsets.all(spacingMd),
      decoration: BoxDecoration(
        color: paleta.card,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: paleta.borderSubtle),
        boxShadow: paleta.sombraCard(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Últimos 7 días',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(fmtCorto(datos.fold<double>(
                  0, (a, b) => a + numADouble(b['total']))),
                  style: TextStyle(
                      color: paleta.gold, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: spacingMd),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(datos.length, (i) {
                final d = datos[i];
                final total = numADouble(d['total']);
                final proporcion =
                    maximo <= 0 ? 0.0 : (total / maximo).clamp(0.02, 1.0);
                final diaHoy = i == datos.length - 1;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (total > 0)
                        Text(
                          total == total.truncateToDouble()
                              ? total.toInt().toString()
                              : total.toStringAsFixed(1),
                          style: TextStyle(
                              fontSize: 9,
                              color: paleta.textMuted,
                              fontWeight: FontWeight.w600),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        height: (108 * proporcion).toDouble(),
                        width: 18,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: diaHoy
                                ? paleta.gradientGold
                                : [
                                    paleta.gold.withValues(alpha: 0.28),
                                    paleta.gold.withValues(alpha: 0.55),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(radiusSm),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(d['nombre']?.toString() ?? '',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  diaHoy ? FontWeight.w800 : FontWeight.w500,
                              color: diaHoy
                                  ? paleta.gold
                                  : paleta.textMuted)),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _BloqueRecientes extends StatelessWidget {
  final List<Map<String, dynamic>> recientes;
  final VoidCallback alVerTodos;

  const _BloqueRecientes({required this.recientes, required this.alVerTodos});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      titulo: 'Ventas recientes',
      complemento: TextButton(
        onPressed: alVerTodos,
        child: const Text('Ver todas'),
      ),
      child: Column(
        children: recientes.map(__build).toList(),
      ),
    );
  }

  Widget __build(Map<String, dynamic> v) {
    return Builder(builder: (context) {
      final paleta = useTema(context).paleta;
      final fecha = parseandoFecha(v['fecha']);
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: paleta.goldSoft,
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          child: Icon(Icons.receipt_long, color: paleta.gold, size: 20),
        ),
        title: Text(v['numero']?.toString() ?? '',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(
            fecha == null ? '' : etiquetaFechaMov(fecha.toLocal()),
            style: const TextStyle(fontSize: 12)),
        trailing: Text(
          fmtMoney(v['total']),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      );
    });
  }
}

class _BloqueBajos extends StatelessWidget {
  final List<Map<String, dynamic>> bajos;
  final Paleta paleta;

  const _BloqueBajos({required this.bajos, required this.paleta});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      titulo: 'Productos con bajo stock',
      child: Column(
        children: bajos.map(__chip).toList(),
      ),
    );
  }

  Widget __chip(Map<String, dynamic> p) {
    return Builder(builder: (context) {
      final paleta = useTema(context).paleta;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(p['nombre']?.toString() ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Badge(
              texto: 'Stock: ${p['stock_actual']}',
              color: paleta.danger,
              icono: Icons.inventory_2_outlined,
            ),
          ],
        ),
      );
    });
  }
}

class _Panel extends StatelessWidget {
  final String titulo;
  final Widget? complemento;
  final Widget child;

  const _Panel({required this.titulo, this.complemento, required this.child});

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return Container(
      padding: const EdgeInsets.fromLTRB(spacingMd, spacingMd, spacingMd, spacingSm),
      decoration: BoxDecoration(
        color: paleta.card,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: paleta.borderSubtle),
        boxShadow: paleta.sombraCard(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(titulo,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              ?complemento,
            ],
          ),
          const SizedBox(height: spacingSm),
          child,
        ],
      ),
    );
  }
}