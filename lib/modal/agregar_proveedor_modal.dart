import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> mostrarAgregarProveedor(
  BuildContext context,
  VoidCallback onSuccess,
) async {
  final nombreController = TextEditingController();
  final telefonoController = TextEditingController();
  final cargoController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Agregar proveedor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
            ),
            TextField(
              controller: telefonoController,
              decoration: const InputDecoration(labelText: 'Número de teléfono'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: cargoController,
              decoration: const InputDecoration(labelText: 'Cargo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombre = nombreController.text.trim();
              final telefono = telefonoController.text.trim();
              final cargo = cargoController.text.trim();

              if (nombre.isEmpty || cargo.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nombre y cargo son obligatorios')),
                );
                return;
              }

              await Supabase.instance.client.from('proveedor').insert({
                'id_proveedor': DateTime.now().millisecondsSinceEpoch,
                'nombre_proveedor': nombre,
                'numero_telefono': telefono.isEmpty ? null : telefono,
                'cargo': cargo,
              });

              Navigator.pop(context);
              onSuccess(); // refresca la lista
            },
            child: const Text('Confirmar datos'),
          ),
        ],
      );
    },
  );
}
