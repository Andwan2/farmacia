import 'package:farmacia_desktop/screens/login_screen.dart';
import 'package:farmacia_desktop/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/home',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
  ],
);
