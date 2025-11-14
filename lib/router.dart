import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:farmacia_desktop/screens/login_screen.dart';
import 'package:farmacia_desktop/screens/home_screen.dart';
import 'package:farmacia_desktop/screens/inventario_screen.dart';
import 'package:farmacia_desktop/screens/ventas_registrar_screen.dart';
import 'package:farmacia_desktop/screens/compras_registrar_screen.dart'; 
import 'package:farmacia_desktop/screens/proveedores_screen.dart';
import 'package:farmacia_desktop/screens/clientes_screen.dart';
import 'package:farmacia_desktop/screens/reportes_ventas_screen.dart';
import 'package:farmacia_desktop/screens/detalle_ventas_screen.dart';
import 'package:farmacia_desktop/screens/reportes_compras_screen.dart';
import 'package:farmacia_desktop/screens/detalle_compras_screen.dart';


final GoRouter router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    if (!isLoggedIn && state.uri.toString() != '/login') {
      return '/login';
    }

    if (isLoggedIn && state.uri.toString() == '/login') {
      return '/home';
    }

    return null;
  },
  routes: <RouteBase>[
    GoRoute(path: '/login', builder: (BuildContext context, GoRouterState state) => const LoginScreen()),
    GoRoute(path: '/home', builder: (BuildContext context, GoRouterState state) => const HomeScreen()),

    // Inventario
    GoRoute(path: '/inventario/info', builder: (_, __) => const InventarioScreen()),

    // Ventas
    GoRoute(path: '/ventas/registrar', builder: (_, __) => const VentasRegistrarScreen()),

    // Compras
    GoRoute(path: '/compras/nueva', builder: (_, __) => const ComprasRegistrarScreen()),

    // Proveedores
    GoRoute(path: '/proveedores/info', builder: (_, _) => const ProveedoresScreen()),

    // Clientes
    GoRoute(path: '/clientes/info', builder: (_, __) => const ClientesScreen()),

    //reportes
    GoRoute(path: '/reportes/ventas', builder: (_, __) => const ReporteVentasScreen()),
    GoRoute(
      path: '/reportes/ventas/detalle/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        if (id == null) {
          return const Scaffold(body: Center(child: Text('ID de venta no válido')));
        }
        return DetalleVentaScreen(idVenta: id);
      },
    ),

    GoRoute(path: '/reportes/compras', builder: (context, state) => const ReporteComprasScreen()),
    GoRoute(
      path: '/reportes/compras/detalle/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        if (id == null || id == 'null') {
          return const Scaffold(body: Center(child: Text('ID de compra no válido')));
        }
        return DetalleCompraScreen(idCompra: id);
      },
    ),



  ],
);
