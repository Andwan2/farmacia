import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReporteVentasScreen extends StatefulWidget {
  const ReporteVentasScreen({super.key});

  @override
  State<ReporteVentasScreen> createState() => _ReporteVentasScreenState();
}

class _ReporteVentasScreenState extends State<ReporteVentasScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> ventas = [];
  List<Map<String, dynamic>> ventasFiltradas = [];

  List<Map<String, dynamic>> todosLosClientes = [];
  List<Map<String, dynamic>> clientesFiltrados = [];

  DateTime? fechaInicio;
  DateTime? fechaFin;
  String? clienteSeleccionado;
  final searchController = TextEditingController();

  Future<void> cargarClientes() async {
    final data = await supabase.from('clientes').select('id_cliente, nombre_cliente');
    setState(() {
      todosLosClientes = List<Map<String, dynamic>>.from(data);
      clientesFiltrados = todosLosClientes;
    });
  }

  Future<void> cargarVentas() async {
    final data = await supabase
        .from('venta')
        .select('id_venta, fecha_hora, total_pago, metodo_pago, clientes(nombre_cliente)')
        .order('fecha_hora', ascending: false);

    setState(() {
      ventas = List<Map<String, dynamic>>.from(data);
      ventasFiltradas = ventas;
    });
  }

  void aplicarFiltros() {
    var filtradas = ventas;

    if (clienteSeleccionado != null) {
      filtradas = filtradas.where((v) =>
          v['clientes']['nombre_cliente'] == clienteSeleccionado).toList();
    }

    if (fechaInicio != null && fechaFin != null) {
      filtradas = filtradas.where((v) {
        final fecha = DateTime.parse(v['fecha_hora']);
        return fecha.isAfter(fechaInicio!.subtract(const Duration(days: 1))) &&
               fecha.isBefore(fechaFin!.add(const Duration(days: 1)));
      }).toList();
    }

    setState(() {
      ventasFiltradas = filtradas;
    });
  }

  void filtrarClientes(String query) {
    if (query.isEmpty) {
      setState(() => clientesFiltrados = todosLosClientes);
      return;
    }

    final filtrados = todosLosClientes.where((c) {
      final nombre = c['nombre_cliente']?.toLowerCase() ?? '';
      return nombre.contains(query.toLowerCase());
    }).toList();

    setState(() => clientesFiltrados = filtrados);
  }

  void limpiarFiltroCliente() {
    setState(() {
      clienteSeleccionado = null;
      clientesFiltrados = todosLosClientes;
      ventasFiltradas = ventas;
      searchController.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    cargarClientes();
    cargarVentas();
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
        title: const Text('Reporte de ventas'),
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar cliente por nombre',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: clienteSeleccionado != null || searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Limpiar filtro',
                            onPressed: limpiarFiltroCliente,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: clientesFiltrados.length,
                    itemBuilder: (context, index) {
                      final cliente = clientesFiltrados[index];
                      return ListTile(
                        title: Text(cliente['nombre_cliente']),
                        onTap: () {
                          setState(() {
                            clienteSeleccionado = cliente['nombre_cliente'];
                          });
                          aplicarFiltros();
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: const Text('Rango de fechas'),
                  onPressed: () async {
                    final rango = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (rango != null) {
                      setState(() {
                        fechaInicio = rango.start;
                        fechaFin = rango.end;
                      });
                      aplicarFiltros();
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ventasFiltradas.isEmpty
                ? const Center(child: Text('No hay ventas registradas'))
                : ListView.builder(
                    itemCount: ventasFiltradas.length,
                    itemBuilder: (context, index) {
                      final venta = ventasFiltradas[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text('Cliente: ${venta['clientes']['nombre_cliente']}'),
                          subtitle: Text(
                              'Fecha: ${venta['fecha_hora'].split('T')[0]} | Total: \$${venta['total_pago']} | Pago: ${venta['metodo_pago']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.info_outline),
                            tooltip: 'Ver detalles',
                            onPressed: () {
                              context.go('/reportes/ventas/detalle/${venta['id_venta']}');
                            },
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
