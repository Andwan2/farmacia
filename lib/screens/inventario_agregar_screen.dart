import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InventarioAgregarScreen extends StatefulWidget {
  const InventarioAgregarScreen({super.key});

  @override
  State<InventarioAgregarScreen> createState() => _InventarioAgregarScreenState();
}

class _InventarioAgregarScreenState extends State<InventarioAgregarScreen> {
  final nombreController = TextEditingController();
  final presentacionController = TextEditingController();
  final precioController = TextEditingController();
  final stockController = TextEditingController();
  final supabase = Supabase.instance.client;

  Future<void> agregarProducto() async {
    final nombre = nombreController.text.trim();
    final presentacion = presentacionController.text.trim();
    final precio = double.tryParse(precioController.text.trim()) ?? 0;
    final stock = int.tryParse(stockController.text.trim()) ?? 0;

    final producto = await supabase.from('productos').insert({
      'nombre_producto': nombre,
      'presentacion': presentacion,
      'precio_producto': precio,
      'fecha_ingreso': DateTime.now().toIso8601String(),
    }).select().single();

    final idProducto = producto['id_productos'];

    await supabase.from('inventario').insert({
      'id_producto': idProducto,
      'stock': stock,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar producto')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nombreController, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: presentacionController, decoration: const InputDecoration(labelText: 'Presentación')),
            TextField(controller: precioController, decoration: const InputDecoration(labelText: 'Precio')),
            TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock inicial')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: agregarProducto, child: const Text('Guardar')),
          ],
        ),
      ),
    );
  }
}
