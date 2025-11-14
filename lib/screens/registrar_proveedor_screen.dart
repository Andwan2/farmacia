import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrarProveedorScreen extends StatefulWidget {
  const RegistrarProveedorScreen({super.key});

  @override
  State<RegistrarProveedorScreen> createState() => _RegistrarProveedorScreenState();
}

class _RegistrarProveedorScreenState extends State<RegistrarProveedorScreen> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final nombreController = TextEditingController();
  final rucController = TextEditingController();

  Future<void> registrarProveedor() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await supabase.from('proveedores').insert({
        'nombre_proveedor': nombreController.text.trim(),
        'ruc_proveedor': rucController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proveedor registrado correctamente')),
      );

      // limpiar campos
      nombreController.clear();
      rucController.clear();
    } catch (e) {
      debugPrint('Error al registrar proveedor: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al registrar proveedor')),
      );
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    rucController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar proveedor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Volver al Home',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre del proveedor'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese el nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: rucController,
                decoration: const InputDecoration(labelText: 'RUC del proveedor'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese el RUC' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar proveedor'),
                onPressed: registrarProveedor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
