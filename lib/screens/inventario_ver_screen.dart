import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class InventarioVerScreen extends StatefulWidget {
  const InventarioVerScreen({super.key});

  @override
  State<InventarioVerScreen> createState() => _InventarioVerScreenState();
}

class _InventarioVerScreenState extends State<InventarioVerScreen> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();

  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> productosFiltrados = [];

  Future<void> cargarInventario() async {
    try {
      final data = await supabase
          .from('productos')
          .select('nombre_producto, precio_producto, inventario(presentacion, stock, fecha_vencimiento)');

      if (data != null) {
        final lista = List<Map<String, dynamic>>.from(data);
        setState(() {
          productos = lista;
          productosFiltrados = lista;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar inventario: $e');
    }
  }

  void filtrarProductos(String query) {
    final filtrados = productos.where((producto) {
      final nombre = producto['nombre_producto']?.toLowerCase() ?? '';
      return nombre.contains(query.toLowerCase());
    }).toList();

    setState(() {
      productosFiltrados = filtrados;
    });
  }

  @override
  void initState() {
    super.initState();
    cargarInventario();
    searchController.addListener(() {
      filtrarProductos(searchController.text);
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
        title: const Text('Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Volver al Home',
            onPressed: () {
              context.go('/home');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar producto',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: productosFiltrados.isEmpty
                ? const Center(child: Text('No hay productos'))
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Nombre')),
                        DataColumn(label: Text('Presentación')),
                        DataColumn(label: Text('Stock')),
                        DataColumn(label: Text('Precio')),
                        DataColumn(label: Text('Fecha de Vencimiento')),
                      ],
                      rows: productosFiltrados.map<DataRow>((producto) {
                        final inventario = producto['inventario'];
                        final presentacion = inventario?['presentacion'] ?? 'N/A';
                        final stock = inventario?['stock'] ?? 'N/A';
                        final precio = producto['precio_producto'] ?? 0;
                        final fechaVencimiento = inventario?['fecha_vencimiento'] ?? 'N/A';

                        return DataRow(cells: [
                          DataCell(Text(producto['nombre_producto'] ?? '')),
                          DataCell(Text(presentacion)),
                          DataCell(Text(stock.toString())),
                          DataCell(Text('\$${precio.toString()}')),
                          DataCell(Text(fechaVencimiento)),
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
