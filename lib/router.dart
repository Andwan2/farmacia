import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:farmacia_desktop/screens/login_screen.dart';
import 'package:farmacia_desktop/screens/home_screen.dart';
import 'package:farmacia_desktop/screens/inventario_ver_screen.dart';
import 'package:farmacia_desktop/screens/inventario_agregar_screen.dart';
import 'package:farmacia_desktop/screens/inventario_actualizar_screen.dart';
import 'package:farmacia_desktop/screens/ventas_registrar_screen.dart';
import 'package:farmacia_desktop/screens/compras_registrar_screen.dart'; 
import 'package:farmacia_desktop/screens/registrar_proveedor_screen.dart';
import 'package:farmacia_desktop/screens/editar_proveedor_screen.dart';
import 'package:farmacia_desktop/screens/clientes_screen.dart';


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
    GoRoute(path: '/inventario/ver', builder: (_, __) => const InventarioVerScreen()),
    GoRoute(path: '/inventario/agregar', builder: (_, __) => const InventarioAgregarScreen()),
    GoRoute(path: '/inventario/actualizar', builder: (_, __) => const InventarioActualizarScreen()),

    // Ventas
    GoRoute(path: '/ventas/registrar', builder: (_, __) => const VentasRegistrarScreen()),

    // Compras
    GoRoute(path: '/compras/nueva', builder: (_, __) => const ComprasRegistrarScreen()),

    // Proveedores
    GoRoute(path: '/proveedores/registrar_proveedor', builder: (_, _) => const RegistrarProveedorScreen()),
    GoRoute(path: '/proveedores/editar_proveedor', builder: (_, _) => const EditarProveedorScreen()),

    // Clientes
     GoRoute(path: '/clientes/info', builder: (_, __) => const ClientesScreen()),
    

  ],
);
