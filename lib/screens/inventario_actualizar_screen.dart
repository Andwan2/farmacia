import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class InventarioActualizarScreen extends StatefulWidget {
  const InventarioActualizarScreen({super.key});

  @override
  State<InventarioActualizarScreen> createState() => _InventarioActualizarScreenState();
}

class _InventarioActualizarScreenState extends State<InventarioActualizarScreen> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();
  final Map<int, TextEditingController> stockControllers = {};
  final Map<int, bool> stockModificado = {};

  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> productosFiltrados = [];

  Future<void> cargarProductos() async {
    try {
      final data = await supabase
          .from('productos')
          .select('id_productos, nombre_producto, id_inventario, inventario(stock)');

      setState(() {
        productos = List<Map<String, dynamic>>.from(data);
        productosFiltrados = productos;
        stockControllers.clear();
        stockModificado.clear();
      });
        } catch (e) {
      debugPrint('Error al cargar productos: $e');
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

  Future<void> actualizarStock(String idInventario, int nuevoStock, int index) async {
    try {
      await supabase
          .from('inventario')
          .update({'stock': nuevoStock})
          .eq('id_inventario', idInventario);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock actualizado')),
      );

      setState(() {
        stockModificado[index] = false;
      });

      cargarProductos();
    } catch (e) {
      debugPrint('Error al actualizar stock: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar stock: ${e.toString()}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    cargarProductos();
    searchController.addListener(() {
      filtrarProductos(searchController.text);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    for (final controller in stockControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualizar stock'),
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
                : ListView.builder(
                    itemCount: productosFiltrados.length,
                    itemBuilder: (context, index) {
                      final producto = productosFiltrados[index];
                      final inventario = producto['inventario'];
                      final stockActual = (inventario != null && inventario['stock'] != null)
                          ? inventario['stock'] as int
                          : 0;

                      final idInventario = producto['id_inventario'];

                      stockControllers.putIfAbsent(index, () => TextEditingController(text: stockActual.toString()));
                      stockModificado.putIfAbsent(index, () => false);

                      final controller = stockControllers[index]!;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Card(
                          child: ListTile(
                            title: Text(producto['nombre_producto']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Nuevo stock'),
                                  onChanged: (value) {
                                    final nuevo = int.tryParse(value.trim()) ?? stockActual;
                                    setState(() {
                                      stockModificado[index] = nuevo != stockActual;
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: stockModificado[index] == true
                                      ? () {
                                          final nuevoStock = int.tryParse(controller.text.trim()) ?? stockActual;
                                          actualizarStock(idInventario, nuevoStock, index);
                                        }
                                      : null,
                                  child: const Text('Guardar'),
                                ),
                              ],
                            ),
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
