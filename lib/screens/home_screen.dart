import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<Map<String, String>> fetchEmpleadoInfo() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return {'nombre': 'Empleado', 'cargo': 'Desconocido'};

    // Paso 1: obtener id_empleado desde Usuario
    final usuario = await Supabase.instance.client
        .from('Usuario')
        .select('id_empleado')
        .eq('id_usuario', userId)
        .single();

    final idEmpleado = usuario['id_empleado'];
    if (idEmpleado == null) return {'nombre': 'Empleado', 'cargo': 'Desconocido'};

    // Paso 2: obtener nombre y cargo desde Empleado
    final empleado = await Supabase.instance.client
        .from('Empleado')
        .select('Nombre_Empleado, id_cargo_empleado')
        .eq('id_empleado', idEmpleado)
        .single();

    final nombre = empleado['Nombre_Empleado'] ?? 'Empleado';
    final idCargo = empleado['id_cargo_empleado'];

    // Paso 3: obtener nombre del cargo
    final cargoData = await Supabase.instance.client
        .from('Cargo_Empleado')
        .select('Cargo')
        .eq('id_cargo_empleado', idCargo)
        .single();

    final cargo = cargoData['Cargo'] ?? 'Desconocido';

    return {'nombre': nombre, 'cargo': cargo};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantalla Principal'),
        actions: [
          FutureBuilder<Map<String, String>>(
            future: fetchEmpleadoInfo(),
            builder: (context, snapshot) {
              final nombre = snapshot.data?['nombre'] ?? 'Empleado';
              final cargo = snapshot.data?['cargo'] ?? 'Desconocido';

              return Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('$nombre ($cargo)', style: const TextStyle(fontSize: 16)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Cerrar sesión',
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      context.go('/login');
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Bienvenido al sistema de farmacia'),
      ),
    );
  }
}
