import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:abari/modal/agregar_proveedor_modal.dart';
import 'package:abari/modal/editar_proveedor_modal.dart';
import 'package:abari/core/widgets/entity_card.dart';

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

  Future<void> cargarProveedores() async {
    final response = await Supabase.instance.client
        .from('proveedor')
        .select(
          'id_proveedor, nombre_proveedor, ruc_proveedor, numero_telefono',
        );

    setState(() {
      proveedores = List<Map<String, dynamic>>.from(response);
      filtrados = proveedores;
    });
  }

  void filtrar() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filtrados = proveedores.where((p) {
        final nombre = p['nombre_proveedor']?.toLowerCase() ?? '';
        final ruc = p['ruc_proveedor']?.toLowerCase() ?? '';
        return nombre.contains(query) || ruc.contains(query);
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
            onPressed: () =>
                mostrarAgregarProveedor(context, cargarProveedores),
            icon: const Icon(Icons.add),
            label: const Text('Agregar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue,
              foregroundColor: Colors.white,
            ),
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
                hintText: 'Buscar proveedor',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Mobile: 2 cards por fila, Tablet+: 4 cards por fila
                final crossAxisCount = constraints.maxWidth < 600 ? 2 : 4;
                
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    // childAspectRatio: 3 / 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final proveedor = filtrados[index];
                    return EntityCard(
                      nombre: proveedor['nombre_proveedor'],
                      icon: Icons.business,
                      subtitulos: [
                        'RUC: ${proveedor['ruc_proveedor'] ?? 'No disponible'}',
                        'Cel: ${proveedor['numero_telefono'] ?? 'No disponible'}',
                      ],
                      onEdit: () => mostrarEditarProveedor(
                        context,
                        proveedor,
                        cargarProveedores,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

