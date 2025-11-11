import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VentasRegistrarScreen extends StatefulWidget {
  const VentasRegistrarScreen({super.key});

  @override
  State<VentasRegistrarScreen> createState() => _VentasRegistrarScreenState();
}

class _VentasRegistrarScreenState extends State<VentasRegistrarScreen> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();
  final Map<int, TextEditingController> cantidadControllers = {};

  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> productosFiltrados = [];
  List<Map<String, dynamic>> clientes = [];
  List<Map<String, dynamic>> carrito = [];

  String? clienteSeleccionado;

  Future<void> cargarProductos() async {
    final data = await supabase
        .from('productos')
        .select('id_productos, nombre_producto, precio_producto, id_inventario, inventario(stock)');

    if (data != null) {
      setState(() {
        productos = List<Map<String, dynamic>>.from(data);
        productosFiltrados = productos;
        cantidadControllers.clear();
      });
    }
  }

  Future<void> cargarClientes() async {
    final data = await supabase.from('clientes').select('id_cliente, nombre_cliente');
    if (data != null) {
      setState(() {
        clientes = List<Map<String, dynamic>>.from(data);
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

  void agregarAlCarrito(Map<String, dynamic> producto, int cantidad) {
    final precio = producto['precio_producto'] ?? 0;
    final total = precio * cantidad;

    setState(() {
      carrito.add({
        'id_producto': producto['id_productos'],
        'nombre': producto['nombre_producto'],
        'cantidad': cantidad,
        'precio_unitario': precio,
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

  void actualizarCantidadEnCarrito(int index, int nuevaCantidad) {
    final item = carrito[index];
    final nuevoTotal = item['precio_unitario'] * nuevaCantidad;

    setState(() {
      carrito[index]['cantidad'] = nuevaCantidad;
      carrito[index]['total'] = nuevoTotal;
    });
  }

  double calcularTotalVenta() {
    return carrito.fold(0, (sum, item) => sum + item['total']);
  }

  Future<void> confirmarVenta() async {
    if (carrito.isEmpty || clienteSeleccionado == null) return;

    final fecha = DateTime.now().toIso8601String();
    final totalVenta = calcularTotalVenta();

    try {
      final email = Supabase.instance.client.auth.currentUser?.email;

      final empleadoRes = await supabase
          .from('empleados')
          .select('id_empleado')
          .limit(1)
          .maybeSingle(); 

      final idEmpleado = empleadoRes?['id_empleado'];

      final ventaRes = await supabase
          .from('venta')
          .insert({
            'fecha_hora': fecha,
            'total_pago': totalVenta,
            'id_cliente': clienteSeleccionado,
            'metodo_pago': 'efectivo',
            'id_empleado': idEmpleado,
          })
          .select();


      final idVenta = ventaRes.first['id_venta'];

      for (final item in carrito) {
        await supabase.from('detalle_ventas').insert({
          'id_venta': idVenta,
          'id_productos': item['id_producto'],
          'cantidad': item['cantidad'].toString(),
          'precio_unitario': item['precio_unitario'],
          'subtotal': item['total'],
        });

        final inventarioRes = await supabase
            .from('inventario')
            .select('stock')
            .eq('id_inventario', item['id_inventario'])
            .single();

        final stockActual = inventarioRes['stock'] ?? 0;
        final nuevoStock = stockActual - item['cantidad'];

        await supabase
            .from('inventario')
            .update({'stock': nuevoStock})
            .eq('id_inventario', item['id_inventario']);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta registrada correctamente')),
      );

      setState(() {
        carrito.clear();
        clienteSeleccionado = null;
      });
    } catch (e) {
      debugPrint('Error al registrar venta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al registrar la venta')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    cargarProductos();
    cargarClientes();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalVenta = calcularTotalVenta();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar venta'),
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
              value: clienteSeleccionado,
              decoration: const InputDecoration(labelText: 'Seleccionar cliente'),
              items: clientes.map((cliente) {
                return DropdownMenuItem<String>(
                  value: cliente['id_cliente'],
                  child: Text(cliente['nombre_cliente']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  clienteSeleccionado = value;
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
                    final stock = producto['inventario']?['stock'] ?? 0;

                    cantidadControllers.putIfAbsent(index, () => TextEditingController());

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(producto['nombre_producto']),
                        subtitle: Text('Precio: \$${producto['precio_producto']} | Stock: $stock'),
                        trailing: SizedBox(
                          width: 120,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: cantidadControllers[index],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: 'Cant'),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  final cantidad = int.tryParse(cantidadControllers[index]!.text.trim()) ?? 0;
                                  if (cantidad > 0 && cantidad <= stock) {
                                    agregarAlCarrito(producto, cantidad);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const Divider(),
            const Text('Factura', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: carrito.isEmpty
                  ? const Center(child: Text('No hay productos en la factura'))
                  : SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 16,
                        columns: const [
                          DataColumn(label: Text('Producto')),
                          DataColumn(label: Text('Cant')),
                          DataColumn(label: Text('Precio')),
                          DataColumn(label: Text('Subtotal')),
                          DataColumn(label: Text('')),
                        ],
                        rows: carrito.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final cantidadController = TextEditingController(text: item['cantidad'].toString());

                       return DataRow(cells: [
  DataCell(Text(item['nombre'])),
  DataCell(SizedBox(
    width: 60,
    child: TextField(
      controller: cantidadController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      onSubmitted: (value) {
        final nuevaCantidad = int.tryParse(value.trim()) ?? item['cantidad'];
        if (nuevaCantidad > 0) {
          actualizarCantidadEnCarrito(index, nuevaCantidad);
        }
      },
    ),
  )),
  DataCell(Text('\$${item['precio_unitario']}')),
  DataCell(Text('\$${item['total'].toStringAsFixed(2)}')),
  DataCell(IconButton(
    icon: const Icon(Icons.delete, color: Colors.red),
    onPressed: () => eliminarDelCarrito(index),
  )),
]);
}).toList(),
),
),
),
Text('Fecha: ${DateTime.now().toLocal().toString().split(' ')[0]}'),
Text('Total a pagar: \$${totalVenta.toStringAsFixed(2)}',
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
const SizedBox(height: 12),
ElevatedButton.icon(
  icon: const Icon(Icons.check),
  label: const Text('Confirmar venta'),
  style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  ),
  onPressed: carrito.isNotEmpty && clienteSeleccionado != null
      ? confirmarVenta
      : null,
),
],
),
),
);
  }
}