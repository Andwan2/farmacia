import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:farmacia_desktop/providers/theme_provider.dart';

Future<void> mostrarEditarProducto(
  BuildContext context,
  Map<String, dynamic> producto,
  VoidCallback onSuccess,
) async {
  final nombreController = TextEditingController(
    text: producto['nombre_producto'],
  );
  final tipoController = TextEditingController(text: producto['tipo']);
  final medidaController = TextEditingController(
    text: producto['medida']?.toString() ?? '',
  );
  final fechaVencimientoController = TextEditingController(
    text: producto['fecha_vencimiento']?.toString().split('T').first ?? '',
  );

  // Cargar presentaciones disponibles
  final presentaciones = await Supabase.instance.client
      .from('presentacion')
      .select('id_presentacion,descripcion,unidad_medida')
      .order('descripcion', ascending: true);

  final listaPresentaciones = presentaciones as List;
  int? presentacionSeleccionada = producto['id_presentacion'] as int?;

  // Guardar valores originales para identificar productos del mismo grupo
  final tipoOriginal = producto['tipo'] as String;
  final fechaVencimientoOriginal =
      producto['fecha_vencimiento']?.toString().split('T').first ?? '';

  // Obtener la cantidad de productos en el grupo
  final stockGrupo = producto['_stock_grupo'] as int? ?? 1;

  showDialog(
    context: context,
    builder: (context) {
      bool editarTodos = true;
      int cantidadIndividual = 1;
      final cantidadController = TextEditingController(text: '1');

      return StatefulBuilder(
        builder: (context, setState) {
          final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

          return Dialog(
            child: Container(
              width: 600,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Editar producto',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.grey[600]!
                                    : Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: isDarkMode
                                          ? Colors.blue[300]
                                          : Colors.blue[700],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Stock disponible: $stockGrupo unidades',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode
                                              ? Colors.grey[200]
                                              : Colors.blue[900],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                RadioListTile<bool>(
                                  title: const Text(
                                    'Editar todos los productos del grupo',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  value: true,
                                  groupValue: editarTodos,
                                  onChanged: (value) {
                                    setState(() {
                                      editarTodos = value!;
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                ),
                                RadioListTile<bool>(
                                  title: const Text(
                                    'Editar cantidad específica',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  value: false,
                                  groupValue: editarTodos,
                                  onChanged: (value) {
                                    setState(() {
                                      editarTodos = value!;
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                ),
                                if (!editarTodos) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Cantidad a editar (Máx: $stockGrupo)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                        onPressed: cantidadIndividual > 1
                                            ? () {
                                                setState(() {
                                                  cantidadIndividual--;
                                                  cantidadController.text =
                                                      cantidadIndividual
                                                          .toString();
                                                });
                                              }
                                            : null,
                                        iconSize: 28,
                                        color: isDarkMode
                                            ? Colors.blue[300]
                                            : Colors.blue,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 40,
                                          minHeight: 40,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 80,
                                        child: TextField(
                                          controller: cantidadController,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 8,
                                                ),
                                            isDense: true,
                                          ),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) {
                                            final cantidad =
                                                int.tryParse(value) ?? 1;
                                            setState(() {
                                              cantidadIndividual = cantidad
                                                  .clamp(1, stockGrupo);
                                              cantidadController.text =
                                                  cantidadIndividual.toString();
                                              cantidadController.selection =
                                                  TextSelection.fromPosition(
                                                    TextPosition(
                                                      offset: cantidadController
                                                          .text
                                                          .length,
                                                    ),
                                                  );
                                            });
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                        onPressed:
                                            cantidadIndividual < stockGrupo
                                            ? () {
                                                setState(() {
                                                  cantidadIndividual++;
                                                  cantidadController.text =
                                                      cantidadIndividual
                                                          .toString();
                                                });
                                              }
                                            : null,
                                        iconSize: 28,
                                        color: isDarkMode
                                            ? Colors.blue[300]
                                            : Colors.blue,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 40,
                                          minHeight: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: nombreController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del producto',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: tipoController,
                            decoration: const InputDecoration(
                              labelText: 'Tipo',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<int>(
                            value: presentacionSeleccionada,
                            decoration: const InputDecoration(
                              labelText: 'Presentación',
                              border: OutlineInputBorder(),
                            ),
                            items: listaPresentaciones.map<DropdownMenuItem<int>>((
                              p,
                            ) {
                              return DropdownMenuItem<int>(
                                value: p['id_presentacion'] as int,
                                child: Text(
                                  '${p['descripcion']} (${p['unidad_medida']})',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                presentacionSeleccionada = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: medidaController,
                            decoration: const InputDecoration(
                              labelText: 'Medida',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: fechaVencimientoController,
                            decoration: const InputDecoration(
                              labelText: 'Fecha de vencimiento (YYYY-MM-DD)',
                              border: OutlineInputBorder(),
                              hintText: '2024-12-31',
                            ),
                            readOnly: true,
                            onTap: () async {
                              final fechaActual =
                                  DateTime.tryParse(
                                    fechaVencimientoController.text,
                                  ) ??
                                  DateTime.now();

                              final fechaSeleccionada = await showDatePicker(
                                context: context,
                                initialDate: fechaActual,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 3650),
                                ),
                              );

                              if (fechaSeleccionada != null) {
                                fechaVencimientoController.text =
                                    fechaSeleccionada
                                        .toIso8601String()
                                        .split('T')
                                        .first;
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Footer con botones
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            final nombre = nombreController.text.trim();
                            final tipo = tipoController.text.trim();
                            final medida = medidaController.text.trim();
                            final fechaVencimiento = fechaVencimientoController
                                .text
                                .trim();

                            if (nombre.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'El nombre del producto es obligatorio',
                                  ),
                                ),
                              );
                              return;
                            }

                            if (tipo.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('El tipo es obligatorio'),
                                ),
                              );
                              return;
                            }

                            if (presentacionSeleccionada == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Debe seleccionar una presentación',
                                  ),
                                ),
                              );
                              return;
                            }

                            if (fechaVencimiento.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'La fecha de vencimiento es obligatoria',
                                  ),
                                ),
                              );
                              return;
                            }

                            // Validar cantidad si se seleccionó editar cantidad específica
                            if (!editarTodos) {
                              if (cantidadIndividual < 1 ||
                                  cantidadIndividual > stockGrupo) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'La cantidad debe estar entre 1 y $stockGrupo',
                                    ),
                                  ),
                                );
                                return;
                              }
                            }

                            try {
                              if (editarTodos) {
                                // Actualizar todos los productos con el mismo tipo y fecha de vencimiento original
                                await Supabase.instance.client
                                    .from('producto')
                                    .update({
                                      'nombre_producto': nombre,
                                      'tipo': tipo,
                                      'id_presentacion':
                                          presentacionSeleccionada,
                                      'medida': medida.isEmpty
                                          ? null
                                          : double.tryParse(medida),
                                      'fecha_vencimiento': fechaVencimiento,
                                    })
                                    .eq('tipo', tipoOriginal)
                                    .eq(
                                      'fecha_vencimiento',
                                      fechaVencimientoOriginal,
                                    )
                                    .eq('esVisible', true);

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '$stockGrupo productos actualizados correctamente',
                                    ),
                                  ),
                                );
                              } else {
                                // Actualizar solo una cantidad específica de productos
                                final productosGrupo = await Supabase
                                    .instance
                                    .client
                                    .from('producto')
                                    .select('id_producto')
                                    .eq('tipo', tipoOriginal)
                                    .eq(
                                      'fecha_vencimiento',
                                      fechaVencimientoOriginal,
                                    )
                                    .eq('esVisible', true)
                                    .limit(cantidadIndividual);

                                final listaProductos = productosGrupo as List;
                                final idsActualizar = listaProductos
                                    .map((p) => p['id_producto'] as int)
                                    .toList();

                                if (idsActualizar.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'No se encontraron productos para actualizar',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                // Actualizar solo los productos seleccionados
                                await Supabase.instance.client
                                    .from('producto')
                                    .update({
                                      'nombre_producto': nombre,
                                      'tipo': tipo,
                                      'id_presentacion':
                                          presentacionSeleccionada,
                                      'medida': medida.isEmpty
                                          ? null
                                          : double.tryParse(medida),
                                      'fecha_vencimiento': fechaVencimiento,
                                    })
                                    .inFilter('id_producto', idsActualizar);

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${idsActualizar.length} producto(s) actualizado(s) correctamente',
                                    ),
                                  ),
                                );
                              }

                              onSuccess();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error al actualizar productos: $e',
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text('Guardar cambios'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
