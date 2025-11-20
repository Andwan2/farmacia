import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> mostrarEditarProveedor(
  BuildContext context,
  Map<String, dynamic> proveedor,
  VoidCallback onSuccess,
) async {
  final nombreController = TextEditingController(text: proveedor['nombre_proveedor']);
  final rucController = TextEditingController(text: proveedor['ruc_proveedor']);
  final telefonoController = TextEditingController(text: proveedor['numero_telefono'] ?? '');

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Editar proveedor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
            ),
            TextField(
              controller: rucController,
              decoration: const InputDecoration(labelText: 'RUC'),
            ),
            TextField(
              controller: telefonoController,
              decoration: const InputDecoration(labelText: 'Número de teléfono'),
              keyboardType: TextInputType.phone,
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
              final ruc = rucController.text.trim();
              final telefono = telefonoController.text.trim();

              if (nombre.isEmpty || ruc.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nombre y RUC son obligatorios')),
                );
                return;
              }

              await Supabase.instance.client
                  .from('proveedor')
                  .update({
                    'nombre_proveedor': nombre,
                    'ruc_proveedor': ruc,
                    'numero_telefono': telefono.isEmpty ? null : telefono,
                  })
                  .eq('id_proveedor', proveedor['id_proveedor']);

              Navigator.pop(context);
              onSuccess();
            },
            child: const Text('Confirmar datos'),
          ),
        ],
      );
    },
  );
}
