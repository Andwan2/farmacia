import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmacia_desktop/router.dart'; // Asegúrate de que este archivo tenga las rutas actualizadas

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://bezhfrzxsvglxcftwxsj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJlemhmcnp4c3ZnbHhjZnR3eHNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM1MjM3OTQsImV4cCI6MjA3OTA5OTc5NH0.A1O7KFRTonnbapM2zP5T_V6zfyzIv4-4C_T273v1vW0',
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
