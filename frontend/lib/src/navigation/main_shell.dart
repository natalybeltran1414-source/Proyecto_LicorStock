import 'package:flutter/material.dart';

import '../screens/clientes_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/inventario_screen.dart';
import '../screens/movimientos_screen.dart';
import '../screens/productos_screen.dart';
import '../screens/ventas_screen.dart';
import '../theme/paleta.dart';
import '../theme/tokens.dart';
import '../theme/theme_provider.dart';

class _DatoTab {
  final String nombre;
  final IconData icono;
  final IconData iconoActivo;

  const _DatoTab(this.nombre, this.icono, this.iconoActivo);
}

const List<_DatoTab> _tabs = <_DatoTab>[
  _DatoTab('Inicio', Icons.home_outlined, Icons.home),
  _DatoTab('Productos', Icons.inventory_2_outlined, Icons.inventory_2),
  _DatoTab('Inventario', Icons.layers_outlined, Icons.layers),
  _DatoTab('Movimientos', Icons.swap_horiz, Icons.sync),
  _DatoTab('Ventas', Icons.shopping_cart_outlined, Icons.shopping_cart),
  _DatoTab('Clientes', Icons.people_outline, Icons.people),
];

/// Alcance para que las pestañas puedan pedir cambiar de pestaña activa
/// y saber cuándo vuelven a ser la visible (refresco por foco).
class MainShellScope extends InheritedWidget {
  final ValueNotifier<int> tabActiva;
  final void Function(int) cambiarTab;

  const MainShellScope({
    super.key,
    required this.tabActiva,
    required this.cambiarTab,
    required super.child,
  });

  static MainShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MainShellScope>();

  /// Pasa la función [cambiarTab] al callback para saltar de pestaña
  /// sin conocer el índice desde aquí: `of(ctx, (cambiar) => cambiar(4))`.
  static void of(
      BuildContext context, void Function(void Function(int) cambiar) usar) {
    final scope = mainShellOf(context);
    if (scope != null) usar(scope.cambiarTab);
  }

  static MainShellScope? mainShellOf(BuildContext context) =>
      context.findAncestorWidgetOfExactType<MainShellScope>();

  @override
  bool updateShouldNotify(MainShellScope oldWidget) =>
      oldWidget.cambiarTab != cambiarTab ||
      oldWidget.tabActiva != tabActiva;
}

/// Mezcla para recargar datos cuando la pestaña [tab] vuelve a ser la activa.
mixin RefrescaAlFoco<T extends StatefulWidget> on State<T> {
  int? _tab;
  ValueNotifier<int>? _activa;

  void suscribirAlFoco(int tab) {
    _tab = tab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scope = MainShellScope.mainShellOf(context);
      _activa = scope?.tabActiva;
      _activa?.addListener(_revisar);
      if (_activa?.value == tab) alRecobrarFoco();
    });
  }

  void _revisar() {
    if (_activa?.value == _tab) alRecobrarFoco();
  }

  /// Se invoca al volver a ser la pestaña activa. Implementar en el State.
  void alRecobrarFoco();

  @override
  void dispose() {
    _activa?.removeListener(_revisar);
    super.dispose();
  }
}

/// App principal con pestañas (Dashboard, Productos, Inventario,
/// Movimientos, Ventas, Clientes). Es el contenedor del flujo logueado.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _activa = 0;
  final ValueNotifier<int> _tabActiva = ValueNotifier<int>(0);

  static const List<Widget> _paginas = <Widget>[
    DashboardScreen(),
    ProductosScreen(),
    InventarioScreen(),
    MovimientosScreen(),
    VentasScreen(),
    ClientesScreen(),
  ];

  void _irA(int index) {
    if (index < 0 || index >= _paginas.length) return;
    if (_activa == index) return;
    setState(() => _activa = index);
    _tabActiva.value = index;
  }

  @override
  void dispose() {
    _tabActiva.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paleta = useTema(context).paleta;
    return MainShellScope(
      tabActiva: _tabActiva,
      cambiarTab: _irA,
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _activa,
          children: _paginas,
        ),
        bottomNavigationBar: _BaseNavegacion(
          activa: _activa,
          alTocar: _irA,
          paleta: paleta,
        ),
      ),
    );
  }
}

class _BaseNavegacion extends StatelessWidget {
  final int activa;
  final ValueChanged<int> alTocar;
  final Paleta paleta;

  const _BaseNavegacion({
    required this.activa,
    required this.alTocar,
    required this.paleta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(spacingMd, 0, spacingMd, spacingMd),
      decoration: BoxDecoration(
        color: paleta.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(radiusXl),
        border: Border.all(color: paleta.border),
        boxShadow: paleta.sombraCard(),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: spacingSm, vertical: spacingSm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final seleccionado = i == activa;
              return _ItemTab(
                name: tab.nombre,
                icono: seleccionado ? tab.iconoActivo : tab.icono,
                activo: seleccionado,
                alTocar: () => alTocar(i),
                color: paleta.gold,
                colorInactivo: paleta.textMuted,
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _ItemTab extends StatelessWidget {
  final String name;
  final IconData icono;
  final bool activo;
  final VoidCallback alTocar;
  final Color color;
  final Color colorInactivo;

  const _ItemTab({
    required this.name,
    required this.icono,
    required this.activo,
    required this.alTocar,
    required this.color,
    required this.colorInactivo,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alTocar,
      borderRadius: BorderRadius.circular(radiusXl),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingSm),
        decoration: BoxDecoration(
          color: activo ? color.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(radiusPill),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 22, color: activo ? color : colorInactivo),
            const SizedBox(height: 2),
            Text(
              name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: activo ? FontWeight.w800 : FontWeight.w600,
                color: activo ? color : colorInactivo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}