import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class InventarioAgregarScreen extends StatefulWidget {
  const InventarioAgregarScreen({super.key});

  @override
  State<InventarioAgregarScreen> createState() =>
      _InventarioAgregarScreenState();
}

class _InventarioAgregarScreenState extends State<InventarioAgregarScreen> {
  final nombreController = TextEditingController();
  final presentacionController = TextEditingController();
  final precioController = TextEditingController();
  final stockController = TextEditingController();
  final fechaController = TextEditingController();
  final formKey = GlobalKey<FormState>();
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
    if (!formKey.currentState!.validate()) {
      return;
    }

    final nombre = nombreController.text.trim();
    final presentacion = presentacionController.text.trim();
    final precio = double.parse(precioController.text.trim());
    final stock = int.parse(stockController.text.trim());
    final fechaVencimiento = fechaController.text.trim();

    try {
      DateTime.parse(fechaVencimiento);

      final inventarioRes = await supabase.from('inventario').insert({
        'stock': stock,
        'presentacion': presentacion,
        'fecha_vencimiento': fechaVencimiento,
      }).select();

      if (inventarioRes == null ||
          inventarioRes.isEmpty ||
          inventarioRes.first['id_inventario'] == null) {
        formKey.currentState?.reset();
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

      if (mounted) {
        context.goNamed('inventario-ver');
      }
    } catch (e) {
      debugPrint('Error al agregar producto: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
      body: Form(
        autovalidateMode: AutovalidateMode.onUnfocus,
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: presentacionController,
                decoration: const InputDecoration(labelText: 'Presentación'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La presentación es obligatoria';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: precioController,
                decoration: const InputDecoration(labelText: 'Precio'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El precio es obligatorio';
                  }
                  final precio = double.tryParse(value.trim());
                  if (precio == null) {
                    return 'El precio debe ser un número válido';
                  }
                  if (precio <= 0) {
                    return 'El precio debe ser mayor a 0';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Stock inicial'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El stock es obligatorio';
                  }
                  final stock = int.tryParse(value.trim());
                  if (stock == null) {
                    return 'El stock debe ser un número entero válido';
                  }
                  if (stock < 0) {
                    return 'El stock no puede ser negativo';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: fechaController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Fecha de vencimiento',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La fecha de vencimiento es obligatoria';
                  }
                  return null;
                },
                onTap: seleccionarFecha,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: agregarProducto,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
