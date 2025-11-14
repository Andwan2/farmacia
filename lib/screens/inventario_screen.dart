import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();

  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> productosFiltrados = [];

  Future<void> cargarInventario() async {
    try {
      final data = await supabase
          .from('productos')
          .select('id_productos, nombre_producto, precio_producto, inventario(id_inventario, presentacion, stock, fecha_vencimiento)');

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

  Future<void> actualizarProducto(String idProducto, String nombre, double precio) async {
    try {
      await supabase.from('productos').update({
        'nombre_producto': nombre,
        'precio_producto': precio,
      }).eq('id_productos', idProducto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto actualizado correctamente')),
        );
      }
      await cargarInventario();
    } catch (e) {
      debugPrint('Error al actualizar producto: $e');
    }
  }

  Future<void> actualizarStock(String idInventario, int nuevoStock) async {
    try {
      await supabase.from('inventario').update({
        'stock': nuevoStock,
      }).eq('id_inventario', idInventario);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock actualizado correctamente')),
        );
      }
      await cargarInventario();
    } catch (e) {
      debugPrint('Error al actualizar stock: $e');
    }
  }

  void mostrarModalEditar(Map<String, dynamic> producto) {
    final nombreCtrl = TextEditingController(text: producto['nombre_producto']);
    final precioCtrl = TextEditingController(text: producto['precio_producto'].toString());
    final stockCtrl = TextEditingController(text: producto['inventario']?['stock']?.toString() ?? '');

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Editar producto', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: precioCtrl,
              decoration: const InputDecoration(labelText: 'Precio'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stockCtrl,
              decoration: const InputDecoration(labelText: 'Stock'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Guardar cambios'),
              onPressed: () async {
                await actualizarProducto(
                  producto['id_productos'],
                  nombreCtrl.text.trim(),
                  double.tryParse(precioCtrl.text.trim()) ?? 0,
                );
                final idInv = producto['inventario']?['id_inventario'];
                if (idInv != null) {
                  await actualizarStock(
                    idInv,
                    int.tryParse(stockCtrl.text.trim()) ?? 0,
                  );
                }
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void mostrarModalAgregarProducto() {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    final presentacionCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    DateTime? fechaVenc;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
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
                  const Text('Agregar producto', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre del producto'),
                    validator: (v) => v == null || v.isEmpty ? 'Ingrese el nombre' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: precioCtrl,
                    decoration: const InputDecoration(labelText: 'Precio'),
                    keyboardType: TextInputType.number,
                    validator: (v) => (double.tryParse(v ?? '') == null) ? 'Precio inválido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: presentacionCtrl,
                    decoration: const InputDecoration(labelText: 'Presentación'),
                    validator: (v) => v == null || v.isEmpty ? 'Ingrese la presentación' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: stockCtrl,
                    decoration: const InputDecoration(labelText: 'Stock inicial'),
                    keyboardType: TextInputType.number,
                    validator: (v) => (int.tryParse(v ?? '') == null) ? 'Stock inválido' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fechaVenc == null
                              ? 'Fecha de vencimiento: sin seleccionar'
                              : 'Fecha de vencimiento: ${fechaVenc!.toIso8601String().split('T').first}',
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: const Text('Seleccionar'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setModalState(() => fechaVenc = picked);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      try {
                        // 1) Insertar inventario y obtener id_inventario
                        final invInsert = await supabase
                            .from('inventario')
                            .insert({
                              'presentacion': presentacionCtrl.text.trim(),
                              'stock': int.parse(stockCtrl.text.trim()),
                              'fecha_vencimiento': fechaVenc?.toIso8601String().split('T').first,
                            })
                            .select('id_inventario')
                            .single();

                        final idInventario = invInsert['id_inventario'];

                        // 2) Insertar producto con referencia al inventario
                        await supabase.from('productos').insert({
                          'nombre_producto': nombreCtrl.text.trim(),
                          'precio_producto': double.parse(precioCtrl.text.trim()),
                          'id_inventario': idInventario,
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Producto agregado correctamente')),
                          );
                        }
                        await cargarInventario();
                        Navigator.pop(context);
                      } catch (e) {
                        debugPrint('Error al agregar producto: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error al agregar producto')),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Agregar producto'),
        onPressed: mostrarModalAgregarProducto,
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
                        DataColumn(label: Text('Acciones')),
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
                          DataCell(Text(fechaVencimiento.toString())),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                tooltip: 'Editar',
                                onPressed: () => mostrarModalEditar(producto),
                              ),
                              IconButton(
                                icon: const Icon(Icons.save, color: Colors.green),
                                tooltip: 'Guardar cambios',
                                onPressed: () async {
                                  await actualizarProducto(
                                    producto['id_productos'],
                                    producto['nombre_producto'],
                                    (producto['precio_producto'] is num)
                                        ? (producto['precio_producto'] as num).toDouble()
                                        : double.tryParse(producto['precio_producto'].toString()) ?? 0,
                                  );
                                  final idInv = inventario?['id_inventario'];
                                  final stockVal = inventario?['stock'];
                                  if (idInv != null && stockVal != null) {
                                    await actualizarStock(idInv, (stockVal as num).toInt());
                                  }
                                },
                              ),
                            ],
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
