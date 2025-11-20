import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importa tus modales externos
import 'package:farmacia_desktop/modal/agregar_cliente_modal.dart';
import 'package:farmacia_desktop/modal/editar_cliente_modal.dart';


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
        .select('id_cliente, nombre_cliente, numero_telefono, tipo_cliente');

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
        final tipo = c['tipo_cliente']?.toLowerCase() ?? '';
        return nombre.contains(query) || tipo.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          ElevatedButton.icon(
            onPressed: () => mostrarAgregarCliente(context, cargarClientes),
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
                hintText: 'Buscar clientes',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 3 / 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filtrados.length,
              itemBuilder: (context, index) {
                final cliente = filtrados[index];
                return ClienteCard(
                  nombre: cliente['nombre_cliente'],
                  telefono: cliente['numero_telefono'],
                  tipo: cliente['tipo_cliente'],
                  onEdit: () => mostrarEditarCliente(context, cliente, cargarClientes),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

//  Tarjeta visual de cliente
class ClienteCard extends StatelessWidget {
  final String nombre;
  final String? telefono;
  final String? tipo;
  final VoidCallback onEdit;

  const ClienteCard({
    super.key,
    required this.nombre,
    this.telefono,
    this.tipo,
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
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(height: 8),
                Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(telefono ?? 'Teléfono no disponible'),
                Text('Tipo: ${tipo ?? 'No definido'}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
