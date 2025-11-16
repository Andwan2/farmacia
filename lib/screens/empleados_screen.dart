import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmpleadosScreen extends StatefulWidget {
  const EmpleadosScreen({super.key});

  @override
  State<EmpleadosScreen> createState() => _EmpleadosScreenState();
}

class _EmpleadosScreenState extends State<EmpleadosScreen> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();

  List<Map<String, dynamic>> empleados = [];
  List<Map<String, dynamic>> empleadosFiltrados = [];
  List<Map<String, dynamic>> cargos = [];

  @override
  void initState() {
    super.initState();
    cargarEmpleados();
    cargarCargos();
    searchController.addListener(() {
      filtrarEmpleados(searchController.text);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> cargarEmpleados() async {
    try {
      final data = await supabase
          .from('empleados')
          .select('id_empleado, nombre_empleado, apellido_empleado, numero_telefono, id_cargo_empleado, cargos_empleado(cargo)');
      setState(() {
        empleados = List<Map<String, dynamic>>.from(data as List);
        empleadosFiltrados = empleados;
      });
    } catch (e) {
      debugPrint('Error cargar empleados: $e');
    }
  }

  Future<void> cargarCargos() async {
    try {
      final data = await supabase
          .from('cargos_empleado')
          .select('id_cargo_empleado, cargo')
          .order('cargo');
      setState(() {
        cargos = List<Map<String, dynamic>>.from(data as List);
      });
    } catch (e) {
      debugPrint('Error cargar cargos: $e');
    }
  }

  void filtrarEmpleados(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) {
      setState(() => empleadosFiltrados = empleados);
      return;
    }
    final filtrados = empleados.where((e) {
      final nombre = (e['nombre_empleado'] ?? '').toString().toLowerCase();
      final apellido = (e['apellido_empleado'] ?? '').toString().toLowerCase();
      final telefono = (e['numero_telefono'] ?? '').toString().toLowerCase();
      return nombre.contains(q) || apellido.contains(q) || telefono.contains(q);
    }).toList();
    setState(() => empleadosFiltrados = filtrados);
  }

  Future<void> registrarEmpleadoConUsuario({
    required String nombre,
    required String apellido,
    required String telefono,
    required String idCargo,
    String? email,
    String? password,
    String? rol,
  }) async {
    try {
      // Insertar empleado y obtener id
      final empleadoRes = await supabase
          .from('empleados')
          .insert({
            'nombre_empleado': nombre,
            'apellido_empleado': apellido,
            'numero_telefono': telefono,
            'id_cargo_empleado': idCargo,
          })
          .select();
      final idEmpleado = (empleadoRes as List).first['id_empleado'];

      // Crear usuario opcionalmente
      if (email != null && email.isNotEmpty && password != null && password.isNotEmpty && rol != null && rol.isNotEmpty) {
        await supabase.from('usuarios').insert({
          'email': email,
          'password': password, // considera hashear/gestionar credenciales en tu flujo real
          'rol': rol,
          'id_empleado': idEmpleado,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Empleado registrado correctamente')),
        );
      }
      await cargarEmpleados();
      filtrarEmpleados(searchController.text);
    } catch (e) {
      debugPrint('Error al registrar empleado: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al registrar empleado')),
        );
      }
    }
  }

  Future<void> editarEmpleado(
    String id,
    String nombre,
    String apellido,
    String telefono,
    String idCargo,
  ) async {
    try {
      await supabase
          .from('empleados')
          .update({
            'nombre_empleado': nombre,
            'apellido_empleado': apellido,
            'numero_telefono': telefono,
            'id_cargo_empleado': idCargo,
          })
          .eq('id_empleado', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Empleado actualizado')),
        );
      }
      await cargarEmpleados();
      filtrarEmpleados(searchController.text);
    } catch (e) {
      debugPrint('Error al editar empleado: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al editar empleado')),
        );
      }
    }
  }

  void mostrarModalRegistro() {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final apellidoCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final rolCtrl = TextEditingController();
    String? cargoSeleccionado;

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Registrar nuevo empleado', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => v == null || v.isEmpty ? 'Ingrese el nombre' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: apellidoCtrl,
                  decoration: const InputDecoration(labelText: 'Apellido'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: telefonoCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: cargoSeleccionado,
                  decoration: const InputDecoration(labelText: 'Cargo'),
                  items: cargos.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['id_cargo_empleado'],
                      child: Text(c['cargo']),
                    );
                  }).toList(),
                  onChanged: (value) => cargoSeleccionado = value,
                  validator: (v) => v == null ? 'Seleccione un cargo' : null,
                ),
                const Divider(height: 24),
                const Text('Datos de usuario (opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: rolCtrl,
                  decoration: const InputDecoration(labelText: 'Rol'),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Registrar'),
                  onPressed: () async {
                    final valid = formKey.currentState?.validate() ?? false;
                    if (!valid) return;

                    await registrarEmpleadoConUsuario(
                      nombre: nombreCtrl.text.trim(),
                      apellido: apellidoCtrl.text.trim(),
                      telefono: telefonoCtrl.text.trim(),
                      idCargo: cargoSeleccionado!,
                      email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                      password: passwordCtrl.text.trim().isEmpty ? null : passwordCtrl.text.trim(),
                      rol: rolCtrl.text.trim().isEmpty ? null : rolCtrl.text.trim(),
                    );
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de empleados')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo empleado'),
        onPressed: mostrarModalRegistro,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre, apellido o teléfono',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: empleadosFiltrados.isEmpty
                ? const Center(child: Text('No hay empleados registrados'))
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      columnSpacing: 24,
                      headingRowColor: WidgetStateProperty.resolveWith(
                        (states) => Colors.grey.shade200,
                      ),
                      columns: const [
                        DataColumn(label: Text('Nombre')),
                        DataColumn(label: Text('Apellido')),
                        DataColumn(label: Text('Teléfono')),
                        DataColumn(label: Text('Cargo')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: empleadosFiltrados.map((empleado) {
                        final nombreCtrl = TextEditingController(text: empleado['nombre_empleado']);
                        final apellidoCtrl = TextEditingController(text: empleado['apellido_empleado']);
                        final telefonoCtrl = TextEditingController(text: empleado['numero_telefono']);
                        String cargoActual = empleado['id_cargo_empleado'];

                        return DataRow(cells: [
                          DataCell(TextField(
                            controller: nombreCtrl,
                            decoration: const InputDecoration(border: InputBorder.none),
                          )),
                          DataCell(TextField(
                            controller: apellidoCtrl,
                            decoration: const InputDecoration(border: InputBorder.none),
                          )),
                          DataCell(TextField(
                            controller: telefonoCtrl,
                            decoration: const InputDecoration(border: InputBorder.none),
                          )),
                          DataCell(DropdownButton<String>(
                            value: cargoActual,
                            underline: const SizedBox(),
                            items: cargos.map((c) {
                              return DropdownMenuItem<String>(
                                value: c['id_cargo_empleado'],
                                child: Text(c['cargo']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => cargoActual = value);
                              }
                            },
                          )),
                          DataCell(ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Guardar'),
                            onPressed: () {
                              editarEmpleado(
                                empleado['id_empleado'],
                                nombreCtrl.text.trim(),
                                apellidoCtrl.text.trim(),
                                telefonoCtrl.text.trim(),
                                cargoActual,
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
