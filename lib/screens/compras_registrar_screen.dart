import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComprasRegistrarScreen extends StatefulWidget {
  const ComprasRegistrarScreen({super.key});

  @override
  State<ComprasRegistrarScreen> createState() => _ComprasRegistrarScreenState();
}

class _ComprasRegistrarScreenState extends State<ComprasRegistrarScreen> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();
  final Map<int, TextEditingController> cantidadControllers = {};
  final Map<int, TextEditingController> precioControllers = {};

  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> productosFiltrados = [];
  List<Map<String, dynamic>> proveedores = [];
  List<Map<String, dynamic>> carrito = [];

  String? proveedorSeleccionado;

  Future<void> cargarProductos() async {
    final data = await supabase
        .from('productos')
        .select('id_productos, nombre_producto, id_inventario, inventario(stock)');
    if (data != null) {
      setState(() {
        productos = List<Map<String, dynamic>>.from(data);
        productosFiltrados = productos;
        cantidadControllers.clear();
        precioControllers.clear();
      });
    }
  }

  Future<void> cargarProveedores() async {
    final data = await supabase.from('proveedores').select('id_proveedor, nombre_proveedor');
    if (data != null) {
      setState(() {
        proveedores = List<Map<String, dynamic>>.from(data);
      });
    }
  }

  void filtrarProductos(String query) {
    final filtrados = productos.where((p) {
      final nombre = p['nombre_producto']?.toLowerCase() ?? '';
      return nombre.contains(query.toLowerCase());
    }).toList();
    setState(() {
      productosFiltrados = filtrados;
    });
  }

  void agregarAlCarrito(Map<String, dynamic> producto, int cantidad, double precioUnitario) {
    final total = cantidad * precioUnitario;
    setState(() {
      carrito.add({
        'id_producto': producto['id_productos'],
        'nombre': producto['nombre_producto'],
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
        'total': total,
        'id_inventario': producto['id_inventario'],
      });
    });
    searchController.clear();
    productosFiltrados = productos;
  }

  void eliminarDelCarrito(int index) {
    setState(() {
      carrito.removeAt(index);
    });
  }

  double calcularTotalCompra() {
    return carrito.fold(0, (sum, item) => sum + item['total']);
  }

  Future<void> confirmarCompra() async {
    if (carrito.isEmpty || proveedorSeleccionado == null) return;

    final fecha = DateTime.now().toIso8601String();
    final totalCompra = calcularTotalCompra();
    final userId = Supabase.instance.client.auth.currentUser?.id;

    try {
      final empleadoRes = await supabase
          .from('empleados')
          .select('id_empleado')
          .limit(1)
          .maybeSingle();

      final idEmpleado = empleadoRes?['id_empleado'];
      if (idEmpleado == null) throw Exception('Empleado no encontrado');

      final compraRes = await supabase
          .from('compras')
          .insert({
            'fecha_compra': fecha,
            'total_compra': totalCompra,
            'id_proveedor': proveedorSeleccionado,
          })
          .select();

      final idCompra = compraRes.first['id_compras'];

      for (final item in carrito) {
        await supabase.from('detalle_compras').insert({
        'id_compras': idCompra, // ← nombre correcto del campo
        'id_productos': item['id_producto'],
        'cantidad': item['cantidad'],
        'precio_unitario': item['precio_unitario'],
        'subtotal': item['total'],
      });


        final inventarioRes = await supabase
            .from('inventario')
            .select('stock')
            .eq('id_inventario', item['id_inventario'])
            .single();

        final stockActual = inventarioRes['stock'] ?? 0;
        final nuevoStock = stockActual + item['cantidad'];

        await supabase
            .from('inventario')
            .update({'stock': nuevoStock})
            .eq('id_inventario', item['id_inventario']);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compra registrada correctamente')),
      );

      setState(() {
        carrito.clear();
        proveedorSeleccionado = null;
      });
    } catch (e) {
      debugPrint('Error al registrar compra: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al registrar la compra')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    cargarProductos();
    cargarProveedores();
    searchController.addListener(() {
      filtrarProductos(searchController.text);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    for (final controller in cantidadControllers.values) {
      controller.dispose();
    }
    for (final controller in precioControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalCompra = calcularTotalCompra();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar compra'),
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
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: proveedorSeleccionado,
              decoration: const InputDecoration(labelText: 'Seleccionar proveedor'),
              items: proveedores.map((prov) {
                return DropdownMenuItem<String>(
                  value: prov['id_proveedor'],
                  child: Text(prov['nombre_proveedor']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  proveedorSeleccionado = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar producto',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            if (productosFiltrados.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: productosFiltrados.length,
                  itemBuilder: (context, index) {
                    final producto = productosFiltrados[index];
                    cantidadControllers.putIfAbsent(index, () => TextEditingController());
                    precioControllers.putIfAbsent(index, () => TextEditingController());

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(producto['nombre_producto']),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: cantidadControllers[index],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Cantidad'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: precioControllers[index],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Precio unitario'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                final cantidad = int.tryParse(cantidadControllers[index]!.text.trim()) ?? 0;
                                final precio = double.tryParse(precioControllers[index]!.text.trim()) ?? 0;
                                if (cantidad > 0 && precio > 0) {
                                  agregarAlCarrito(producto, cantidad, precio);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const Divider(),
            const Text('Resumen de compra', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: carrito.isEmpty
                  ? const Center(child: Text('No hay productos en la compra'))
                  : ListView.builder(
                      itemCount: carrito.length,
                      itemBuilder: (context, index) {
                        final item = carrito[index];
                        return ListTile(
                          title: Text(item['nombre']),
                          subtitle: Text('Cantidad: ${item['cantidad']} | Precio: \$${item['precio_unitario']} | Subtotal: \$${item['total']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => eliminarDelCarrito(index),
                          ),
                        );
                      },
                    ),
            ),
            Text('Fecha: ${DateTime.now().toLocal().toString().split(' ')[0]}'),
            Text('Total de compra: \$${totalCompra.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
                       ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Confirmar compra'),
              onPressed: carrito.isNotEmpty && proveedorSeleccionado != null
                  ? confirmarCompra
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
