import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final supabase = Supabase.instance.client;

  Future<void> registrarUsuario() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    final response = await supabase.auth.signUp(email: email, password: password);
    final userId = response.user?.id;

    if (userId != null) {
      await supabase.from('usuarios').insert({
        'id_usuario': userId,
        'email': email,
        'rol': 'farmaceutico', // ajusta según el caso
        'id_empleado': 'tu-id-empleado-aqui', // debe venir de selección o creación previa
      });
      // Redirige al login o home
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Correo')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: registrarUsuario, child: const Text('Registrarse')),
          ],
        ),
      ),
    );
  }
}
