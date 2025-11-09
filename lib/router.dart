import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:farmacia_desktop/screens/login_screen.dart';
import 'package:farmacia_desktop/screens/home_screen.dart';
import 'package:farmacia_desktop/screens/inventario_ver_screen.dart';
import 'package:farmacia_desktop/screens/inventario_agregar_screen.dart';
import 'package:farmacia_desktop/screens/inventario_actualizar_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    // Si no está logueado y no está en /login, redirige a /login
    if (!isLoggedIn && state.uri.toString() != '/login') {
      return '/login';
    }

    // Si está logueado y visita /login, redirige a /home
    if (isLoggedIn && state.uri.toString() == '/login') {
      return '/home';
    }

    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),

    // 📦 Rutas del módulo Inventario
    GoRoute(
      path: '/inventario/ver',
      name: 'inventario-ver',
      builder: (BuildContext context, GoRouterState state) {
        return const InventarioVerScreen();
      },
    ),
    GoRoute(
      path: '/inventario/agregar',
      name: 'inventario-agregar',
      builder: (BuildContext context, GoRouterState state) {
        return const InventarioAgregarScreen();
      },
    ),
    GoRoute(
      path: '/inventario/actualizar',
      name: 'inventario-actualizar',
      builder: (BuildContext context, GoRouterState state) {
        return const InventarioActualizarScreen();
      },
    ),
  ],
);
