import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmacia_desktop/modal/agregar_empleado_modal.dart';
import 'package:farmacia_desktop/modal/editar_empleado_modal.dart';

class EmpleadosScreen extends StatefulWidget {
  const EmpleadosScreen({super.key});

  @override
  State<EmpleadosScreen> createState() => _EmpleadosScreenState();
}

class _EmpleadosScreenState extends State<EmpleadosScreen> {
  List<Map<String, dynamic>> empleados = [];
  List<Map<String, dynamic>> filtrados = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarEmpleados();
    _searchController.addListener(filtrar);
  }

  Future<void> cargarEmpleados() async {
    final response = await Supabase.instance.client
        .from('empleado')
        .select('id_empleado, nombre_empleado, telefono, cargo_empleado(cargo)');

    setState(() {
      empleados = List<Map<String, dynamic>>.from(response);
      filtrados = empleados;
    });
  }

  void filtrar() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filtrados = empleados.where((e) {
        final nombre = e['nombre_empleado']?.toLowerCase() ?? '';
        final cargo = e['cargo_empleado']?['cargo']?.toLowerCase() ?? '';
        return nombre.contains(query) || cargo.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Empleados'),
        actions: [
          ElevatedButton.icon(
            onPressed: () => mostrarAgregarEmpleado(context, cargarEmpleados),
            icon: const Icon(Icons.person_add),
            label: const Text('Agregar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
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
                hintText: 'Buscar empleado',
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
                final empleado = filtrados[index];
                return EmpleadoCard(
                  nombre: empleado['nombre_empleado'],
                  telefono: empleado['telefono'],
                  cargo: empleado['cargo_empleado']?['cargo'],
                  onEdit: () => mostrarEditarEmpleado(context, empleado, cargarEmpleados),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EmpleadoCard extends StatelessWidget {
  final String nombre;
  final String? telefono;
  final String? cargo;
  final VoidCallback onEdit;

  const EmpleadoCard({
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
              icon: const Icon(Icons.edit),
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
                Text('Cargo: ${cargo ?? 'No definido'}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
