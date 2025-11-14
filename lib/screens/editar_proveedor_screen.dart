import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditarProveedorScreen extends StatefulWidget {
  const EditarProveedorScreen({super.key});

  @override
  State<EditarProveedorScreen> createState() => _EditarProveedorScreenState();
}

class _EditarProveedorScreenState extends State<EditarProveedorScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> proveedores = [];
  List<Map<String, dynamic>> proveedoresFiltrados = [];
  final searchController = TextEditingController();

  Future<void> cargarProveedores() async {
    try {
      final data = await supabase
          .from('proveedores')
          .select('id_proveedor, nombre_proveedor, ruc_proveedor');

      setState(() {
        proveedores = List<Map<String, dynamic>>.from(data);
        proveedoresFiltrados = proveedores; // inicializamos con todos
      });
    } catch (e) {
      debugPrint('Error al cargar proveedores: $e');
    }
  }

  void filtrarProveedores(String query) {
    if (query.isEmpty) {
      // si no hay texto, mostramos todos
      setState(() {
        proveedoresFiltrados = proveedores;
      });
      return;
    }

    final filtrados = proveedores.where((prov) {
      final nombre = prov['nombre_proveedor']?.toLowerCase() ?? '';
      final ruc = prov['ruc_proveedor']?.toLowerCase() ?? '';
      return nombre.contains(query.toLowerCase()) || ruc.contains(query.toLowerCase());
    }).toList();

    setState(() {
      proveedoresFiltrados = filtrados;
    });
  }

  Future<void> editarProveedor(String idProveedor, String nombre, String ruc) async {
    try {
      await supabase.from('proveedores').update({
        'nombre_proveedor': nombre,
        'ruc_proveedor': ruc,
      }).eq('id_proveedor', idProveedor);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proveedor actualizado correctamente')),
      );

      cargarProveedores(); // refrescar lista
    } catch (e) {
      debugPrint('Error al actualizar proveedor: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar proveedor')),
      );
    }
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
        title: const Text('Editar proveedor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Volver al Home',
            onPressed: () => context.go('/home'),
          ),
        ],
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
                final nombreController =
                    TextEditingController(text: proveedor['nombre_proveedor']);
                final rucController =
                    TextEditingController(text: proveedor['ruc_proveedor']);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: nombreController,
                          decoration: const InputDecoration(labelText: 'Nombre'),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: rucController,
                          decoration: const InputDecoration(labelText: 'RUC'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar cambios'),
                          onPressed: () {
                            editarProveedor(
                              proveedor['id_proveedor'],
                              nombreController.text.trim(),
                              rucController.text.trim(),
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
