import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> mostrarAgregarEmpleado(
  BuildContext context,
  VoidCallback onSuccess,
) async {
  final nombreController = TextEditingController();
  final telefonoController = TextEditingController();
  int? idCargoSeleccionado;

  final cargos = await Supabase.instance.client
      .from('cargo_empleado')
      .select('id_cargo, cargo');

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Agregar empleado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
            ),
            TextField(
              controller: telefonoController,
              decoration: const InputDecoration(labelText: 'Teléfono'),
              keyboardType: TextInputType.phone,
            ),
            DropdownButtonFormField<int>(
              value: idCargoSeleccionado,
              items: cargos.map<DropdownMenuItem<int>>((cargo) {
                return DropdownMenuItem<int>(
                  value: cargo['id_cargo'],
                  child: Text(cargo['cargo']),
                );
              }).toList(),
              onChanged: (value) => idCargoSeleccionado = value,
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

              if (nombre.isEmpty || idCargoSeleccionado == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nombre y cargo son obligatorios')),
                );
                return;
              }

              await Supabase.instance.client.from('empleado').insert({
                'id_empleado': DateTime.now().millisecondsSinceEpoch,
                'nombre_empleado': nombre,
                'telefono': telefono.isEmpty ? null : telefono,
                'id_cargo': idCargoSeleccionado,
              });

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
