import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> mostrarAgregarProveedor(
  BuildContext context,
  VoidCallback onSuccess,
) async {
  final nombreController = TextEditingController();
  final rucController = TextEditingController();
  final telefonoController = TextEditingController();

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

              await Supabase.instance.client.from('proveedor').insert({
                // id_proveedor es BIGSERIAL, lo genera Postgres automáticamente
                'nombre_proveedor': nombre,
                'ruc_proveedor': ruc,
                'numero_telefono': telefono.isEmpty ? null : telefono,
              });

              // Ejecutar el callback antes de cerrar el diálogo para evitar
              // usar un BuildContext después de que el widget sea desmontado.
              onSuccess();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Proveedor agregado correctamente'),
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Confirmar datos'),
          ),
        ],
      );
    },
  );
}
