import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importa tus modales externos
import 'package:abari/modal/agregar_cliente_modal.dart';
import 'package:abari/modal/editar_cliente_modal.dart';
import 'package:abari/core/widgets/entity_card.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  List<Map<String, dynamic>> clientes = [];
  List<Map<String, dynamic>> filtrados = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarClientes();
    _searchController.addListener(filtrar);
  }

  // 🔌 Cargar clientes desde Supabase
  Future<void> cargarClientes() async {
    final response = await Supabase.instance.client
        .from('cliente')
        .select('id_cliente, nombre_cliente, numero_telefono');

    setState(() {
      clientes = List<Map<String, dynamic>>.from(response);
      filtrados = clientes;
    });
  }

  // 🔍 Filtrar clientes por nombre o tipo
  void filtrar() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filtrados = clientes.where((c) {
        final nombre = c['nombre_cliente']?.toLowerCase() ?? '';
        return nombre.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar clientes',
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
                    childAspectRatio: 3 / 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final cliente = filtrados[index];
                    return EntityCard(
                      nombre: cliente['nombre_cliente'],
                      icon: Icons.person,
                      subtitulos: [
                        'Cel: ${cliente['numero_telefono'] ?? 'Teléfono no disponible'}',
                      ],
                      onEdit: () =>
                          mostrarEditarCliente(context, cliente, cargarClientes),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => mostrarAgregarCliente(context, cargarClientes),
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar Cliente'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
    );
  }
}

