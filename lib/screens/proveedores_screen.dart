import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();

  List<Map<String, dynamic>> proveedores = [];
  List<Map<String, dynamic>> proveedoresFiltrados = [];

  Future<void> cargarProveedores() async {
    final data = await supabase
        .from('proveedores')
        .select('id_proveedor, nombre_proveedor, ruc_proveedor');
    setState(() {
      proveedores = List<Map<String, dynamic>>.from(data);
      proveedoresFiltrados = proveedores;
    });
  }

  Future<void> registrarProveedor(String nombre, String ruc) async {
    try {
      await supabase.from('proveedores').insert({
        'nombre_proveedor': nombre,
        'ruc_proveedor': ruc,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proveedor registrado correctamente')),
      );

      await cargarProveedores();
      filtrarProveedores(searchController.text);
    } catch (e) {
      debugPrint('Error al registrar proveedor: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al registrar proveedor')),
      );
    }
  }

  Future<void> editarProveedor(String id, String nombre, String ruc) async {
    try {
      await supabase.from('proveedores').update({
        'nombre_proveedor': nombre,
        'ruc_proveedor': ruc,
      }).eq('id_proveedor', id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proveedor actualizado correctamente')),
      );

      await cargarProveedores();
      filtrarProveedores(searchController.text);
    } catch (e) {
      debugPrint('Error al actualizar proveedor: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar proveedor')),
      );
    }
  }

  void filtrarProveedores(String query) {
    if (query.isEmpty) {
      setState(() => proveedoresFiltrados = proveedores);
      return;
    }

    final filtrados = proveedores.where((p) {
      final nombre = p['nombre_proveedor']?.toLowerCase() ?? '';
      final ruc = p['ruc_proveedor']?.toLowerCase() ?? '';
      return nombre.contains(query.toLowerCase()) || ruc.contains(query.toLowerCase());
    }).toList();

    setState(() => proveedoresFiltrados = filtrados);
  }

  void mostrarModalRegistro() {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final rucCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Registrar proveedor', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del proveedor'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese el nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: rucCtrl,
                decoration: const InputDecoration(labelText: 'RUC del proveedor'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese el RUC' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar proveedor'),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  await registrarProveedor(
                    nombreCtrl.text.trim(),
                    rucCtrl.text.trim(),
                  );
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    cargarProveedores();
    searchController.addListener(() {
      filtrarProveedores(searchController.text);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de proveedores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Volver al Home',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo proveedor'),
        onPressed: mostrarModalRegistro,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar proveedor por nombre o RUC',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: proveedoresFiltrados.length,
              itemBuilder: (context, index) {
                final proveedor = proveedoresFiltrados[index];
                final nombreCtrl =
                    TextEditingController(text: proveedor['nombre_proveedor']);
                final rucCtrl =
                    TextEditingController(text: proveedor['ruc_proveedor']);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: nombreCtrl,
                          decoration: const InputDecoration(labelText: 'Nombre'),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: rucCtrl,
                          decoration: const InputDecoration(labelText: 'RUC'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar cambios'),
                          onPressed: () {
                            editarProveedor(
                              proveedor['id_proveedor'],
                              nombreCtrl.text.trim(),
                              rucCtrl.text.trim(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
