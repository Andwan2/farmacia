import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComprasRegistrarScreen extends StatefulWidget {
  const ComprasRegistrarScreen({super.key});

  @override
  State<ComprasRegistrarScreen> createState() => _ComprasRegistrarScreenState();
}

class _ComprasRegistrarScreenState extends State<ComprasRegistrarScreen> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();

  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> productosFiltrados = [];
  List<Map<String, dynamic>> proveedores = [];
  List<Map<String, dynamic>> carrito = [];

  String? proveedorSeleccionado;

  @override
  void initState() {
    super.initState();
    cargarProductos();
    cargarProveedores();
    searchController.addListener(() {
      filtrarProductos(searchController.text);
      setState(() {}); // para actualizar la visibilidad condicional
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> cargarProductos() async {
    try {
      final data = await supabase
          .from('productos')
          .select('id_productos, nombre_producto, id_inventario, inventario(stock)');
      setState(() {
        productos = List<Map<String, dynamic>>.from(data as List);
        productosFiltrados = productos;
      });
    } catch (e) {
      debugPrint('Error cargar productos: $e');
    }
  }

  Future<void> cargarProveedores() async {
    try {
      final data = await supabase
          .from('proveedores')
          .select('id_proveedor, nombre_proveedor');
      setState(() {
        proveedores = List<Map<String, dynamic>>.from(data as List);
      });
    } catch (e) {
      debugPrint('Error cargar proveedores: $e');
    }
  }

  void filtrarProductos(String query) {
    if (query.trim().isEmpty) {
      setState(() => productosFiltrados = []);
      return;
    }
    final filtrados = productos.where((p) {
      final nombre = (p['nombre_producto'] ?? '').toString().toLowerCase();
      return nombre.contains(query.toLowerCase());
    }).toList();
    setState(() {
      productosFiltrados = filtrados;
    });
  }

  void agregarAlCarrito(
    Map<String, dynamic> producto,
    int cantidad,
    double precioUnitario,
    DateTime? fechaVenc,
  ) {
    final total = cantidad * precioUnitario;
    setState(() {
      carrito.add({
        'id_producto': producto['id_productos'],
        'nombre': producto['nombre_producto'],
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
        'total': total,
        'id_inventario': producto['id_inventario'],
        'fecha_vencimiento': fechaVenc, // DateTime? en carrito
      });
    });
  }

  void eliminarDelCarrito(int index) {
    setState(() {
      carrito.removeAt(index);
    });
  }

  double calcularTotalCompra() {
    return carrito.fold<double>(
      0,
      (sum, item) => sum + (item['total'] as num).toDouble(),
    );
  }

  String _nombreProveedor() {
    if (proveedorSeleccionado == null) return 'N/A';
    final prov = proveedores.firstWhere(
      (p) => p['id_proveedor'] == proveedorSeleccionado,
      orElse: () => {},
    );
    return (prov['nombre_proveedor'] ?? 'N/A').toString();
  }

  Future<void> confirmarCompra() async {
    if (carrito.isEmpty || proveedorSeleccionado == null) return;

    final fecha = DateTime.now().toIso8601String();
    final totalCompra = calcularTotalCompra();

    try {
      // Insertar compra
      final compraRes = await supabase
          .from('compras')
          .insert({
            'fecha_compra': fecha,
            'total_compra': totalCompra,
            'id_proveedor': proveedorSeleccionado,
          })
          .select();
      final idCompra = (compraRes as List).first['id_compras'];

      // Por cada ítem del carrito: insertar detalle y actualizar inventario
      for (final item in carrito) {
        await supabase.from('detalle_compras').insert({
          'id_compras': idCompra,
          'id_productos': item['id_producto'],
          'cantidad': item['cantidad'],
          'precio_unitario': item['precio_unitario'],
          'subtotal': item['total'],
        });

        // stock actual
        final invRes = await supabase
            .from('inventario')
            .select('stock')
            .eq('id_inventario', item['id_inventario'])
            .single();

        final stockActual =
            (invRes['stock'] == null) ? 0 : (invRes['stock'] as num).toInt();
        final nuevoStock = stockActual + (item['cantidad'] as int);

        // actualizar inventario: stock y fecha_vencimiento (si existe)
        await supabase
            .from('inventario')
            .update({
              'stock': nuevoStock,
              'fecha_vencimiento': item['fecha_vencimiento'] == null
                  ? null
                  : (item['fecha_vencimiento'] as DateTime)
                      .toIso8601String()
                      .split('T')
                      .first,
            })
            .eq('id_inventario', item['id_inventario']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compra registrada correctamente')),
        );
      }
      setState(() {
        carrito.clear();
        proveedorSeleccionado = null;
        searchController.clear();
        productosFiltrados = [];
      });
    } catch (e) {
      debugPrint('Error al registrar compra: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al registrar la compra')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCompra = calcularTotalCompra();

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar compra')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Encabezado: proveedor + resumen
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: proveedorSeleccionado,
                    decoration:
                        const InputDecoration(labelText: 'Seleccionar proveedor'),
                    items: proveedores.map((prov) {
                      return DropdownMenuItem<String>(
                        value: prov['id_proveedor'],
                        child: Text(prov['nombre_proveedor']),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => proveedorSeleccionado = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Proveedor: ${_nombreProveedor()}'),
                          Text(
                            'Fecha: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Total: \$${totalCompra.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Búsqueda
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar producto',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            // Tabla productos disponibles (solo si hay búsqueda activa)
            if (searchController.text.trim().isNotEmpty)
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        columnSpacing: 20,
                        headingRowColor: WidgetStateProperty.resolveWith(
                          (states) => Colors.grey.shade200,
                        ),
                        columns: const [
                          DataColumn(label: Text('Producto')),
                          DataColumn(label: Text('Cantidad')),
                          DataColumn(label: Text('Precio unitario')),
                          DataColumn(label: Text('Fecha venc.')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: productosFiltrados.map((producto) {
                          final cantidadCtrl = TextEditingController();
                          final precioCtrl = TextEditingController();
                          final fechaVencCtrl = TextEditingController();

                          return DataRow(cells: [
                            DataCell(Text(producto['nombre_producto'] ?? '')),
                            DataCell(TextField(
                              controller: cantidadCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '0',
                              ),
                            )),
                            DataCell(TextField(
                              controller: precioCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '0.00',
                              ),
                            )),
                            DataCell(TextField(
                              controller: fechaVencCtrl,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'YYYY-MM-DD',
                              ),
                            )),
                            DataCell(ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Añadir'),
                              onPressed: () {
                                final cantidad =
                                    int.tryParse(cantidadCtrl.text.trim()) ?? 0;
                                final precio =
                                    double.tryParse(precioCtrl.text.trim()) ?? 0;
                                final fechaTexto = fechaVencCtrl.text.trim();

                                final fechaRegex =
                                    RegExp(r'^\d{4}-\d{2}-\d{2}$');
                                DateTime? fechaFinal;

                                if (cantidad <= 0 || precio <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Cantidad y precio deben ser mayores a cero')),
                                  );
                                  return;
                                }

                                if (fechaTexto.isNotEmpty) {
                                  if (!fechaRegex.hasMatch(fechaTexto)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Formato inválido. Usa YYYY-MM-DD')),
                                    );
                                    return;
                                  }
                                  try {
                                    fechaFinal = DateTime.parse(fechaTexto);
                                    if (fechaFinal.isBefore(DateTime.now())) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'La fecha no puede ser anterior a hoy')),
                                      );
                                      return;
                                    }
                                  } catch (_) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Fecha inválida')),
                                    );
                                    return;
                                  }
                                }

                                agregarAlCarrito(
                                  producto,
                                  cantidad,
                                  precio,
                                  fechaFinal,
                                );
                              },
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Busca un producto para añadirlo a la factura',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),

            const SizedBox(height: 12),

            // Factura
            const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                'Factura de compra',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ), 
            Expanded(
              child: Card(
                elevation: 3,
                margin: const EdgeInsets.only(top: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: carrito.isEmpty
                      ? const Center(child: Text('No hay productos en la factura'))
                      : SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            columnSpacing: 24,
                            headingRowHeight: 40,
                            dataRowHeight: 48,
                            headingRowColor: WidgetStateProperty.resolveWith(
                              (states) => Colors.grey.shade200,
                            ),
                            columns: const [
                              DataColumn(label: Text('Producto')),
                              DataColumn(label: Text('Cantidad')),
                              DataColumn(label: Text('Precio')),
                              DataColumn(label: Text('Subtotal')),
                              DataColumn(label: Text('Fecha venc.')),
                              DataColumn(label: Text('Acciones')),
                            ],
                            rows: carrito.map((item) {
                              final idx = carrito.indexOf(item);
                              final precio = (item['precio_unitario'] as num).toStringAsFixed(2);
                              final subtotal = (item['total'] as num).toStringAsFixed(2);
                              final fechaStr = item['fecha_vencimiento'] == null
                                  ? 'N/A'
                                  : (item['fecha_vencimiento'] as DateTime)
                                      .toIso8601String()
                                      .split('T')
                                      .first;

                              return DataRow(cells: [
                                DataCell(Text(item['nombre'].toString())),
                                DataCell(Text(item['cantidad'].toString())),
                                DataCell(Text('\$$precio')),
                                DataCell(Text('\$$subtotal')),
                                DataCell(Text(fechaStr)),
                                DataCell(IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => eliminarDelCarrito(idx),
                                )),
                              ]);
                            }).toList(),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Confirmar compra
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Agregar compra', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: carrito.isNotEmpty && proveedorSeleccionado != null
                    ? confirmarCompra
                    : null,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
