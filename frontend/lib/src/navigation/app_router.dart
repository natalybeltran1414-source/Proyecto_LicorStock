import 'package:flutter/material.dart';

import '../screens/bloqueo_screen.dart';
import '../screens/cliente_form_screen.dart';
import '../screens/clientes_screen.dart';
import '../screens/cuentas_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/inventario_screen.dart';
import '../screens/login_screen.dart';
import '../screens/movimientos_screen.dart';
import '../screens/perfil_screen.dart';
import '../screens/producto_form_screen.dart';
import '../screens/productos_screen.dart';
import '../screens/registro_screen.dart';
import '../screens/venta_nueva_screen.dart';
import '../screens/ventas_screen.dart';
import 'main_shell.dart';

class Routes {
  static const String login = 'login';
  static const String registro = 'registro';
  static const String bloqueo = 'bloqueo';
  static const String main = 'main';
  static const String dashboard = 'dashboard';
  static const String productos = 'productos';
  static const String producto = 'producto';
  static const String inventario = 'inventario';
  static const String movimientos = 'movimientos';
  static const String ventas = 'ventas';
  static const String ventaNueva = 'ventaNueva';
  static const String clientes = 'clientes';
  static const String cliente = 'cliente';
  static const String cuentas = 'cuentas';
  static const String perfil = 'perfil';
}

/// Llave global de navegación: permite remontar todo desde sesión expirada.
final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

/// Lleva al usuario al Login descartando el resto de la pila.
Future<void> remontarAlLogin() async {
  await navKey.currentState?.pushNamedAndRemoveUntil(
    Routes.login,
    (ruta) => false,
  );
}

Map<String, WidgetBuilder> rutas() => <String, WidgetBuilder>{
      Routes.login: (_) => const LoginScreen(),
      Routes.registro: (_) => const RegistroScreen(),
      Routes.bloqueo: (_) => const BloqueoScreen(),
      Routes.main: (_) => const MainShell(),
      Routes.dashboard: (_) => const DashboardScreen(),
      Routes.productos: (_) => const ProductosScreen(),
      Routes.producto: (_) => const ProductoFormScreen(),
      Routes.inventario: (_) => const InventarioScreen(),
      Routes.movimientos: (_) => const MovimientosScreen(),
      Routes.ventas: (_) => const VentasScreen(),
      Routes.ventaNueva: (_) => const VentaNuevaScreen(),
      Routes.clientes: (_) => const ClientesScreen(),
      Routes.cliente: (_) => const ClienteFormScreen(),
      Routes.cuentas: (_) => const CuentasScreen(),
      Routes.perfil: (_) => const PerfilScreen(),
    };