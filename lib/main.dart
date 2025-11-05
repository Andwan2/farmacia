import 'package:farmacia_desktop/router.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://yvzshtvsmqghejyvwqrf.supabase.co', // ← reemplaza con tu URL real
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl2enNodHZzbXFnaGVqeXZ3cXJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxOTA0MTEsImV4cCI6MjA3Nzc2NjQxMX0.YMwqG4rlafQMKJfYmo4LYRTTHAhUQyS0ki32w4C8GBE', // ← reemplaza con tu anon key real
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        
        supportedLocales: const [
          Locale('en'), // English
          // Locale('es'), // Spanish
        ],
        builder: (context, child) {
          // This is where you can set up your theme, localization, etc.
          return child ?? SizedBox.shrink();
        },
      );
     
  }
}
