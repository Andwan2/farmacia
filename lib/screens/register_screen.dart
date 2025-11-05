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
  final rolController = TextEditingController();
  final supabase = Supabase.instance.client;

  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  Future<void> register() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final rol = rolController.text.trim();

    try {
      await supabase.from('usuarios').insert({
        'email': email,
        'password': password, // ⚠️ En producción, usa bcrypt
        'rol': rol,
      });

      setState(() {
        successMessage = 'Usuario registrado correctamente';
      });
    } catch (error) {
      setState(() {
        errorMessage = 'Error al registrar usuario: $error';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar usuario')),
      body: Center(
        child: SizedBox(
          width: 350,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Correo electrónico'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rolController,
                decoration: const InputDecoration(labelText: 'Rol (admin, farmaceutico, cajero)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : register,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Registrar'),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              if (successMessage != null) ...[
                const SizedBox(height: 10),
                Text(successMessage!, style: const TextStyle(color: Colors.green)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
