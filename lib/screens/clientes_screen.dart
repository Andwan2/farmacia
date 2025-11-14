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

  final _formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final telefonoController = TextEditingController();
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

  Future<void> registrarCliente() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await supabase.from('clientes').insert({
        'nombre_cliente': nombreController.text.trim(),
        'numero_telefono': telefonoController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente registrado correctamente')),
      );

      nombreController.clear();
      telefonoController.clear();
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
    nombreController.dispose();
    telefonoController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de clientes'),
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
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre del cliente'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Ingrese el nombre' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: telefonoController,
                    decoration: const InputDecoration(labelText: 'Número de teléfono'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Registrar cliente'),
                    onPressed: registrarCliente,
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
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
            child: ListView.builder(
              itemCount: clientesFiltrados.length,
              itemBuilder: (context, index) {
                final cliente = clientesFiltrados[index];
                final nombreCtrl =
                    TextEditingController(text: cliente['nombre_cliente']);
                final telefonoCtrl =
                    TextEditingController(text: cliente['numero_telefono']);

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
                          controller: telefonoCtrl,
                          decoration: const InputDecoration(labelText: 'Teléfono'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar cambios'),
                          onPressed: () {
                            editarCliente(
                              cliente['id_cliente'],
                              nombreCtrl.text.trim(),
                              telefonoCtrl.text.trim(),
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
