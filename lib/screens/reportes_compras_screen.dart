import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReporteComprasScreen extends StatefulWidget {
  const ReporteComprasScreen({super.key});

  @override
  State<ReporteComprasScreen> createState() => _ReporteComprasScreenState();
}

class _ReporteComprasScreenState extends State<ReporteComprasScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> compras = [];
  List<Map<String, dynamic>> comprasFiltradas = [];

  List<Map<String, dynamic>> todosLosProveedores = [];
  List<Map<String, dynamic>> proveedoresFiltrados = [];

  DateTime? fechaInicio;
  DateTime? fechaFin;
  String? proveedorSeleccionado;
  final searchController = TextEditingController();

  Future<void> cargarProveedores() async {
    final data = await supabase.from('proveedores').select('id_proveedor, nombre_proveedor');
    setState(() {
      todosLosProveedores = List<Map<String, dynamic>>.from(data);
      proveedoresFiltrados = todosLosProveedores;
    });
  }

  Future<void> cargarCompras() async {
    final data = await supabase
        .from('compras')
        .select('id_compras, fecha_compra, total_compra,  proveedores(nombre_proveedor)')
        .order('fecha_compra', ascending: false);

    setState(() {
      compras = List<Map<String, dynamic>>.from(data);
      comprasFiltradas = compras;
    });
  }

  void aplicarFiltros() {
    var filtradas = compras;

    if (proveedorSeleccionado != null) {
      filtradas = filtradas.where((c) =>
          c['proveedores']['nombre_proveedor'] == proveedorSeleccionado).toList();
    }

    if (fechaInicio != null && fechaFin != null) {
      filtradas = filtradas.where((c) {
        final fecha = DateTime.parse(c['fecha_compra']);
        return fecha.isAfter(fechaInicio!.subtract(const Duration(days: 1))) &&
               fecha.isBefore(fechaFin!.add(const Duration(days: 1)));
      }).toList();
    }

    setState(() {
      comprasFiltradas = filtradas;
    });
  }

  void filtrarProveedores(String query) {
    if (query.isEmpty) {
      setState(() => proveedoresFiltrados = todosLosProveedores);
      return;
    }

    final filtrados = todosLosProveedores.where((p) {
      final nombre = p['nombre_proveedor']?.toLowerCase() ?? '';
      return nombre.contains(query.toLowerCase());
    }).toList();

    setState(() => proveedoresFiltrados = filtrados);
  }

  void limpiarFiltroProveedor() {
    setState(() {
      proveedorSeleccionado = null;
      proveedoresFiltrados = todosLosProveedores;
      comprasFiltradas = compras;
      searchController.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    cargarProveedores();
    cargarCompras();
    searchController.addListener(() {
      filtrarProveedores(searchController.text);
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
        title: const Text('Reporte de compras'),
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
                    labelText: 'Buscar proveedor por nombre',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: proveedorSeleccionado != null || searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Limpiar filtro',
                            onPressed: limpiarFiltroProveedor,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: proveedoresFiltrados.length,
                    itemBuilder: (context, index) {
                      final proveedor = proveedoresFiltrados[index];
                      return ListTile(
                        title: Text(proveedor['nombre_proveedor']),
                        onTap: () {
                          setState(() {
                            proveedorSeleccionado = proveedor['nombre_proveedor'];
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
            child: comprasFiltradas.isEmpty
                ? const Center(child: Text('No hay compras registradas'))
                : ListView.builder(
                    itemCount: comprasFiltradas.length,
                    itemBuilder: (context, index) {
                      final compra = comprasFiltradas[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text('Proveedor: ${compra['proveedores']['nombre_proveedor']}'),
                          subtitle: Text(
                              'Fecha: ${compra['fecha_compra'].split('T')[0]} | Total: \$${compra['total_compra'] }'),
                          onTap: () => {
                            context.push('/detalleCompra${compra['id_compras']}')
                          },
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
