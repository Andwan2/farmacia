import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InventarioActualizarScreen extends StatefulWidget {
  const InventarioActualizarScreen({super.key});

  @override
  State<InventarioActualizarScreen> createState() => _InventarioActualizarScreenState();
}

class _InventarioActualizarScreenState extends State<InventarioActualizarScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> productos = [];

  Future<void> cargarProductos() async {
    final response = await supabase
        .from('productos')
        .select('id_productos, nombre_producto, inventario(stock)')
        .execute();

    if (response != null && response.error == null && response.data != null) {
      setState(() {
        productos = List<Map<String, dynamic>>.from(response.data);
      });
    }
  }

  Future<void> actualizarStock(String idProducto, int nuevoStock) async {
    await supabase.from('inventario').update({'stock': nuevoStock}).eq('id_producto', idProducto);
    cargarProductos();
  }

  @override
  void initState() {
    super.initState();
    cargarProductos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Actualizar stock')),
      body: ListView.builder(
        itemCount: productos.length,
        itemBuilder: (context, index) {
          final producto = productos[index];
          final stockController = TextEditingController(text: producto['inventario']['stock'].toString());

          return ListTile(
            title: Text(producto['nombre_producto']),
            subtitle: TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nuevo stock'),
              onSubmitted: (value) {
                final nuevoStock = int.tryParse(value) ?? 0;
                actualizarStock(producto['id_productos'], nuevoStock);
              },
            ),
          );
        },
      ),
    );
  }
}

extension on PostgrestFilterBuilder<PostgrestList> {
  Future execute() async {}
}
