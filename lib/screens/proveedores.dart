import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importa tus modales externos
import 'package:farmacia_desktop/modal/agregar_proveedor_modal.dart';
import 'package:farmacia_desktop/modal/editar_proveedor_modal.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  List<Map<String, dynamic>> proveedores = [];
  List<Map<String, dynamic>> filtrados = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarProveedores();
    _searchController.addListener(filtrar);
  }

  // 🔌 Cargar proveedores desde Supabase
  Future<void> cargarProveedores() async {
    final response = await Supabase.instance.client
        .from('proveedor')
        .select('id_proveedor, nombre_proveedor, numero_telefono, cargo');

    setState(() {
      proveedores = List<Map<String, dynamic>>.from(response);
      filtrados = proveedores;
    });
  }

  // 🔍 Filtrar proveedores por nombre o cargo
  void filtrar() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filtrados = proveedores.where((p) {
        final nombre = p['nombre_proveedor']?.toLowerCase() ?? '';
        final cargo = p['cargo']?.toLowerCase() ?? '';
        return nombre.contains(query) || cargo.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
        actions: [
          ElevatedButton.icon(
            onPressed: () => mostrarAgregarProveedor(context, cargarProveedores),
            icon: const Icon(Icons.person_add),
            label: const Text('Agregar'),
            style: ElevatedButton.styleFrom(  backgroundColor: Colors.lightBlue, foregroundColor: Colors.white,),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar proveedores',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3 / 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filtrados.length,
              itemBuilder: (context, index) {
                final proveedor = filtrados[index];
                return ProveedorCard(
                  nombre: proveedor['nombre_proveedor'],
                  telefono: proveedor['numero_telefono'],
                  cargo: proveedor['cargo'],
                  onEdit: () => mostrarEditarProveedor(context, proveedor, cargarProveedores),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 🧱 Tarjeta visual de proveedor
class ProveedorCard extends StatelessWidget {
  final String nombre;
  final String? telefono;
  final String? cargo;
  final VoidCallback onEdit;

  const ProveedorCard({
    super.key,
    required this.nombre,
    this.telefono,
    this.cargo,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Stack(
        children: [
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(child: Icon(Icons.business)),
                const SizedBox(height: 8),
                Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(telefono ?? 'Teléfono no disponible'),
                Text('Cargo: ${cargo ?? 'No definido'}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
