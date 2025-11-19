import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmacia_desktop/screens/login_screen.dart';
import 'package:farmacia_desktop/screens/home_screen.dart';

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
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) =>
          const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (BuildContext context, GoRouterState state) =>
          const HomeScreen(),
    ),
   ],
  //ESTO HACE COSAS QUE SOLO GPT SABE
  errorBuilder: (context, state) {
    // Mostrar SnackBar de manera segura
    Future.microtask(() {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Ruta inválida: ${state.error}'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => context.go('/home'),
              icon: Icon(Icons.home),
              tooltip: "Inicio",
            ),
            Text('Ha ocurrido un error, parece que la ruta no existe. Presiona el boton para volver al inicio.'),
          ]
        ),
      ),
    );
  },
);
