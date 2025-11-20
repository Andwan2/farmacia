import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Pantalla principal que muestra la lista de clientes
class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClienteScreenState();
}

class _ClienteScreenState extends State<ClientesScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Lista completa de clientes obtenidos desde Supabase
  List<Map<String, dynamic>> clientes = [];

  // Lista filtrada según la búsqueda
  List<Map<String, dynamic>> filtrados = [];

  @override
  void initState() {
    super.initState();
    cargarClientes(); // Carga inicial de datos
    _searchController.addListener(filtrar); // Escucha cambios en el campo de búsqueda
  }

  // Consulta a Supabase para obtener los clientes
  Future<void> cargarClientes() async {
    final response = await Supabase.instance.client
        .from('cliente')
        .select('id_cliente, nombre_cliente, numero_telefono, tipo_cliente');

    setState(() {
      clientes = List<Map<String, dynamic>>.from(response);
      filtrados = clientes; // Inicialmente muestra todos
    });
  }

  // Filtra la lista según el texto ingresado
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
      // AppBar con botón atrás y botón "Agregar"
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton.icon(
              onPressed: () {
                // Acción para agregar cliente (puedes abrir un modal o navegar)
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                foregroundColor: Colors.white, // ← color del texto e ícono
              ),

            ),
          ),
        ],
      ),

      // Cuerpo de la pantalla
      body: Column(
        children: [
          // Campo de búsqueda
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o tipo',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),

          // Grid de tarjetas de cliente
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // Dos columnas
                childAspectRatio: 3 / 2, // Proporción de cada tarjeta
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filtrados.length,
              itemBuilder: (context, index) {
                final cliente = filtrados[index];
                return ClienteCard(
                  nombre: cliente['nombre_cliente'],
                  telefono: cliente['numero_telefono'] ?? 'No registrado',
                  tipo: cliente['tipo_cliente'],
                  onEdit: () {
                    // Acción para editar cliente (puedes abrir un modal o navegar)
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

// Tarjeta visual para mostrar datos de un cliente
class ClienteCard extends StatelessWidget {
  final String nombre;
  final String telefono;
  final String tipo;
  final VoidCallback onEdit;

  const ClienteCard({
    super.key,
    required this.nombre,
    required this.telefono,
    required this.tipo,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3, // Sombra
      child: Stack(
        children: [
          // Botón de edición en la esquina superior derecha
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
            ),
          ),

          // Contenido central de la tarjeta
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(child: Icon(Icons.person)), // Ícono de cliente
                const SizedBox(height: 8),
                Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(telefono),
                Text('Tipo: $tipo', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
