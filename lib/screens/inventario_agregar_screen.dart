// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

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
  final fechaController = TextEditingController();
  final supabase = Supabase.instance.client;

  Future<void> seleccionarFecha() async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (fecha != null) {
      fechaController.text = fecha.toIso8601String().split('T').first;
    }
  }

  Future<void> agregarProducto() async {
    final nombre = nombreController.text.trim();
    final presentacion = presentacionController.text.trim();
    final precio = double.tryParse(precioController.text.trim());
    final stock = int.tryParse(stockController.text.trim());
    final fechaVencimiento = fechaController.text.trim();

    if (nombre.isEmpty || presentacion.isEmpty || fechaVencimiento.isEmpty || precio == null || stock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los campos son obligatorios y deben tener formato válido')),
      );
      return;
    }

    try {
      DateTime.parse(fechaVencimiento);

      final inventarioRes = await supabase
          .from('inventario')
          .insert({
            'stock': stock,
            'presentacion': presentacion,
            'fecha_vencimiento': fechaVencimiento,
          })
          .select();

      if (inventarioRes == null || inventarioRes.isEmpty || inventarioRes.first['id_inventario'] == null) {
        throw Exception('Error al insertar inventario');
      }

      final idInventario = inventarioRes.first['id_inventario'];

      final productoRes = await supabase.from('productos').insert({
        'nombre_producto': nombre,
        'precio_producto': precio,
        'id_inventario': idInventario,
      }).select();

      if (productoRes == null || productoRes.isEmpty) {
        throw Exception('Error al insertar producto');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto agregado correctamente')),
      );

    } catch (e) {
      debugPrint('Error al agregar producto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar producto'),
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
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: nombreController, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: presentacionController, decoration: const InputDecoration(labelText: 'Presentación')),
            TextField(controller: precioController, decoration: const InputDecoration(labelText: 'Precio')),
            TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock inicial')),
            TextField(
              controller: fechaController,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Fecha de vencimiento'),
              onTap: seleccionarFecha,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: agregarProducto, child: const Text('Guardar')),
          ],
        ),
      ),
    );
  }
}
