import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmacia_desktop/router.dart'; // Asegúrate de que este archivo tenga las rutas actualizadas

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://yvzshtvsmqghejyvwqrf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl2enNodHZzbXFnaGVqeXZ3cXJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxOTA0MTEsImV4cCI6MjA3Nzc2NjQxMX0.YMwqG4rlafQMKJfYmo4LYRTTHAhUQyS0ki32w4C8GBE',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router, // ← usa el GoRouter con las rutas de inventario
      supportedLocales: const [
        Locale('en'), // English
        // Locale('es'), // Puedes habilitar español si lo necesitas
      ],
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
