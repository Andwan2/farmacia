import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();

  List<Map<String, dynamic>> clientes = [];
  List<Map<String, dynamic>> clientesFiltrados = [];

  Future<void> cargarClientes() async {
    final data = await supabase
        .from('clientes')
        .select('id_cliente, nombre_cliente, numero_telefono');
    setState(() {
      clientes = List<Map<String, dynamic>>.from(data);
      clientesFiltrados = clientes;
    });
  }

  Future<void> registrarCliente(String nombre, String telefono) async {
    try {
      await supabase.from('clientes').insert({
        'nombre_cliente': nombre,
        'numero_telefono': telefono,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente registrado correctamente')),
      );

      await cargarClientes();
      filtrarClientes(searchController.text); // mantener filtro activo
    } catch (e) {
      debugPrint('Error al registrar cliente: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al registrar cliente')),
      );
    }
  }

  Future<void> editarCliente(String id, String nombre, String telefono) async {
    try {
      await supabase.from('clientes').update({
        'nombre_cliente': nombre,
        'numero_telefono': telefono,
      }).eq('id_cliente', id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente actualizado correctamente')),
      );

      await cargarClientes();
      filtrarClientes(searchController.text); // mantener filtro activo
    } catch (e) {
      debugPrint('Error al actualizar cliente: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar cliente')),
      );
    }
  }

  void filtrarClientes(String query) {
    if (query.isEmpty) {
      setState(() => clientesFiltrados = clientes);
      return;
    }

    final filtrados = clientes.where((c) {
      final nombre = c['nombre_cliente']?.toLowerCase() ?? '';
      final telefono = c['numero_telefono']?.toLowerCase() ?? '';
      return nombre.contains(query.toLowerCase()) || telefono.contains(query.toLowerCase());
    }).toList();

    setState(() => clientesFiltrados = filtrados);
  }

  void mostrarModalRegistro() {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();

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
              const Text('Registrar nuevo cliente', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del cliente'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese el nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: telefonoCtrl,
                decoration: const InputDecoration(labelText: 'Número de teléfono'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Registrar'),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  await registrarCliente(nombreCtrl.text.trim(), telefonoCtrl.text.trim());
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
    cargarClientes();
    searchController.addListener(() {
      filtrarClientes(searchController.text);
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
        title: const Text('Gestión de clientes'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo cliente'),
        onPressed: mostrarModalRegistro,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar cliente por nombre o teléfono',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: clientesFiltrados.isEmpty
                ? const Center(child: Text('No hay clientes registrados'))
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      columnSpacing: 24,
                      headingRowColor: WidgetStateProperty.resolveWith(
                        (states) => Colors.grey.shade200,
                      ),
                      columns: const [
                        DataColumn(label: Text('Nombre')),
                        DataColumn(label: Text('Teléfono')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: clientesFiltrados.map((cliente) {
                        final nombreCtrl =
                            TextEditingController(text: cliente['nombre_cliente']);
                        final telefonoCtrl =
                            TextEditingController(text: cliente['numero_telefono']);

                        return DataRow(cells: [
                          DataCell(TextField(
                            controller: nombreCtrl,
                            decoration: const InputDecoration(border: InputBorder.none),
                          )),
                          DataCell(TextField(
                            controller: telefonoCtrl,
                            decoration: const InputDecoration(border: InputBorder.none),
                          )),
                          DataCell(ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Guardar'),
                            onPressed: () {
                              editarCliente(
                                cliente['id_cliente'],
                                nombreCtrl.text.trim(),
                                telefonoCtrl.text.trim(),
                              );
                            },
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
          ),

        ],
      ),
    );
  }
}
