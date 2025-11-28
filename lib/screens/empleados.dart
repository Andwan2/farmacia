import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:abari/modal/agregar_empleado_modal.dart';
import 'package:abari/modal/editar_empleado_modal.dart';
import 'package:abari/core/widgets/entity_card.dart';

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
        .select(
          'id_empleado, nombre_empleado, telefono, cargo_empleado(cargo)',
        );

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar empleado',
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
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final empleado = filtrados[index];
                    return EntityCard(
                      nombre: empleado['nombre_empleado'],
                      icon: Icons.person,
                      subtitulos: [
                        empleado['telefono'] ?? 'Teléfono no disponible',
                        'Cargo: ${empleado['cargo_empleado']?['cargo'] ?? 'No definido'}',
                      ],
                      onEdit: () => mostrarEditarEmpleado(
                        context,
                        empleado,
                        cargarEmpleados,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => mostrarAgregarEmpleado(context, cargarEmpleados),
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar Empleado'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
