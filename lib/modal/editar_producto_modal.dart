import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:abari/providers/theme_provider.dart';

Future<void> mostrarEditarProducto(
  BuildContext context,
  Map<String, dynamic> producto,
  VoidCallback onSuccess,
) async {
  final nombreController = TextEditingController(
    text: producto['nombre_producto']?.toString() ?? '',
  );
  final codigoController = TextEditingController(
    text: producto['codigo']?.toString() ?? '',
  );
  final cantidadProductoController = TextEditingController(
    text: producto['cantidad']?.toString() ?? '',
  );
  final fechaVencimientoController = TextEditingController(
    text: producto['fecha_vencimiento']?.toString().split('T').first ?? '',
  );
  final fechaAgregadoController = TextEditingController(
    text: producto['fecha_agregado']?.toString() ?? '',
  );
  final precioCompraController = TextEditingController(
    text: producto['precio_compra']?.toString() ?? '',
  );
  final precioVentaController = TextEditingController(
    text: producto['precio_venta']?.toString() ?? '',
  );

  // Cargar presentaciones disponibles
  final presentaciones = await Supabase.instance.client
      .from('presentacion')
      .select('id_presentacion,descripcion')
      .order('descripcion', ascending: true);

  // Cargar unidades de medida disponibles
  final unidadesMedida = await Supabase.instance.client
      .from('unidad_medida')
      .select('id,nombre,abreviatura')
      .order('nombre', ascending: true);

  final listaPresentaciones = presentaciones as List;
  final listaUnidadesMedida = unidadesMedida as List;
  int? presentacionSeleccionada = producto['id_presentacion'] as int?;
  int? unidadMedidaSeleccionada = producto['id_unidad_medida'] as int?;

  // Guardar valores originales para identificar productos del mismo grupo
  final codigoOriginal = producto['codigo']?.toString() ?? '';
  final fechaVencimientoOriginal =
      producto['fecha_vencimiento']?.toString().split('T').first ?? '';
  final estadoOriginal = producto['estado'] as String? ?? 'Disponible';

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
                            controller: codigoController,
                            decoration: const InputDecoration(
                              labelText: 'Código',
                              border: OutlineInputBorder(),
                              helperText:
                                  'Identificador para agrupar productos similares',
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<int>(
                            value: presentacionSeleccionada,
                            decoration: const InputDecoration(
                              labelText: 'Presentación',
                              border: OutlineInputBorder(),
                            ),
                            items: listaPresentaciones
                                .map<DropdownMenuItem<int>>((p) {
                                  return DropdownMenuItem<int>(
                                    value: p['id_presentacion'] as int,
                                    child: Text(
                                      p['descripcion']?.toString() ?? '',
                                    ),
                                  );
                                })
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                presentacionSeleccionada = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: cantidadProductoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Cantidad',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: false,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<int>(
                                  value: unidadMedidaSeleccionada,
                                  decoration: const InputDecoration(
                                    labelText: 'Unidad de medida',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: listaUnidadesMedida
                                      .map<DropdownMenuItem<int>>((u) {
                                        return DropdownMenuItem<int>(
                                          value: u['id'] as int,
                                          child: Text(
                                            '${u['nombre']} (${u['abreviatura']})',
                                          ),
                                        );
                                      })
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      unidadMedidaSeleccionada = value;
                                    });
                                  },
                                ),
                              ),
                            ],
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
                          const SizedBox(height: 10),
                          TextField(
                            controller: fechaAgregadoController,
                            decoration: const InputDecoration(
                              labelText: 'Fecha de agregado',
                              border: OutlineInputBorder(),
                              hintText: 'YYYY-MM-DD HH:MM',
                              suffixIcon: Icon(Icons.access_time),
                            ),
                            readOnly: true,
                            onTap: () async {
                              final fechaActual =
                                  fechaAgregadoController.text.isNotEmpty
                                  ? DateTime.tryParse(
                                      fechaAgregadoController.text,
                                    )
                                  : null;

                              final fechaSeleccionada = await showDatePicker(
                                context: context,
                                initialDate: fechaActual ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );

                              if (fechaSeleccionada != null) {
                                // Mostrar selector de hora
                                final horaActual = fechaActual != null
                                    ? TimeOfDay.fromDateTime(fechaActual)
                                    : TimeOfDay.now();

                                final horaSeleccionada = await showTimePicker(
                                  context: context,
                                  initialTime: horaActual,
                                );

                                if (horaSeleccionada != null) {
                                  final fechaCompleta = DateTime(
                                    fechaSeleccionada.year,
                                    fechaSeleccionada.month,
                                    fechaSeleccionada.day,
                                    horaSeleccionada.hour,
                                    horaSeleccionada.minute,
                                  );
                                  fechaAgregadoController.text = fechaCompleta
                                      .toIso8601String();
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          // Precios
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: precioCompraController,
                                  decoration: const InputDecoration(
                                    labelText: 'Precio compra',
                                    border: OutlineInputBorder(),
                                    hintText: 'Opcional',
                                    prefixText: 'C\$ ',
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: precioVentaController,
                                  decoration: const InputDecoration(
                                    labelText: 'Precio venta',
                                    border: OutlineInputBorder(),
                                    hintText: 'Opcional',
                                    prefixText: 'C\$ ',
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                              ),
                            ],
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
                            final codigo = codigoController.text.trim();
                            final cantidad = cantidadProductoController.text
                                .trim();
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

                            if (codigo.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('El código es obligatorio'),
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

                            if (unidadMedidaSeleccionada == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Debe seleccionar una unidad de medida',
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
                                      'codigo': codigo,
                                      'id_presentacion':
                                          presentacionSeleccionada,
                                      'id_unidad_medida':
                                          unidadMedidaSeleccionada,
                                      'cantidad': cantidad.isEmpty
                                          ? null
                                          : double.tryParse(cantidad),
                                      'fecha_vencimiento': fechaVencimiento,
                                      'fecha_agregado':
                                          fechaAgregadoController
                                              .text
                                              .isNotEmpty
                                          ? fechaAgregadoController.text
                                          : null,
                                      'precio_compra':
                                          precioCompraController.text.isNotEmpty
                                          ? double.tryParse(
                                              precioCompraController.text,
                                            )
                                          : null,
                                      'precio_venta':
                                          precioVentaController.text.isNotEmpty
                                          ? double.tryParse(
                                              precioVentaController.text,
                                            )
                                          : null,
                                    })
                                    .eq('codigo', codigoOriginal)
                                    .eq(
                                      'fecha_vencimiento',
                                      fechaVencimientoOriginal,
                                    )
                                    .eq('estado', estadoOriginal);

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
                                    .eq('codigo', codigoOriginal)
                                    .eq(
                                      'fecha_vencimiento',
                                      fechaVencimientoOriginal,
                                    )
                                    .eq('estado', estadoOriginal)
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
                                      'codigo': codigo,
                                      'id_presentacion':
                                          presentacionSeleccionada,
                                      'id_unidad_medida':
                                          unidadMedidaSeleccionada,
                                      'cantidad': cantidad.isEmpty
                                          ? null
                                          : double.tryParse(cantidad),
                                      'fecha_vencimiento': fechaVencimiento,
                                      'fecha_agregado':
                                          fechaAgregadoController
                                              .text
                                              .isNotEmpty
                                          ? fechaAgregadoController.text
                                          : null,
                                      'precio_compra':
                                          precioCompraController.text.isNotEmpty
                                          ? double.tryParse(
                                              precioCompraController.text,
                                            )
                                          : null,
                                      'precio_venta':
                                          precioVentaController.text.isNotEmpty
                                          ? double.tryParse(
                                              precioVentaController.text,
                                            )
                                          : null,
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
