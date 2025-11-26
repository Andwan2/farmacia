import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:abari/providers/theme_provider.dart';

Future<void> mostrarAgregarProducto(
  BuildContext context,
  VoidCallback onSuccess,
) async {
  final nombreController = TextEditingController();
  final cantidadController = TextEditingController();
  final stockController = TextEditingController(text: '1');
  final fechaVencimientoController = TextEditingController();
  final fechaAgregadoController = TextEditingController();
  final precioCompraController = TextEditingController();
  final precioVentaController = TextEditingController();

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

  List<dynamic> listaPresentaciones = presentaciones as List;
  List<dynamic> listaUnidadesMedida = unidadesMedida as List;
  int? presentacionSeleccionada;
  int? unidadMedidaSeleccionada;
  bool sinFechaVencimiento = false;

  // Función para agregar nueva presentación
  Future<void> agregarNuevaPresentacion(
    BuildContext context,
    StateSetter setState,
  ) async {
    final descripcionController = TextEditingController();

    final resultado = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_box_outlined),
              SizedBox(width: 8),
              Text('Nueva Presentación'),
            ],
          ),
          content: TextField(
            controller: descripcionController,
            decoration: const InputDecoration(
              labelText: 'Descripción *',
              border: OutlineInputBorder(),
              hintText: 'Ej: Bolsa, Caja, Botella, Lata',
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final descripcion = descripcionController.text.trim();
                if (descripcion.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La descripción es obligatoria'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, descripcion);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (resultado != null) {
      try {
        final response = await Supabase.instance.client
            .from('presentacion')
            .insert({'descripcion': resultado})
            .select()
            .single();

        final nuevasPresentaciones = await Supabase.instance.client
            .from('presentacion')
            .select('id_presentacion,descripcion')
            .order('descripcion', ascending: true);

        setState(() {
          listaPresentaciones = nuevasPresentaciones as List;
          presentacionSeleccionada = response['id_presentacion'] as int;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Presentación "$resultado" agregada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // Función para agregar nueva unidad de medida
  Future<void> agregarNuevaUnidadMedida(
    BuildContext context,
    StateSetter setState,
  ) async {
    final nombreController = TextEditingController();
    final abreviaturaController = TextEditingController();

    final resultado = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.straighten_outlined),
              SizedBox(width: 8),
              Text('Nueva Unidad de Medida'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Gramos, Kilogramos, Litros',
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: abreviaturaController,
                decoration: const InputDecoration(
                  labelText: 'Abreviatura *',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: g, kg, ml, L, un',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final nombre = nombreController.text.trim();
                final abreviatura = abreviaturaController.text.trim();
                if (nombre.isEmpty || abreviatura.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Todos los campos son obligatorios'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, {
                  'nombre': nombre,
                  'abreviatura': abreviatura,
                });
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (resultado != null) {
      try {
        final response = await Supabase.instance.client
            .from('unidad_medida')
            .insert({
              'nombre': resultado['nombre'],
              'abreviatura': resultado['abreviatura'],
            })
            .select()
            .single();

        final nuevasUnidades = await Supabase.instance.client
            .from('unidad_medida')
            .select('id,nombre,abreviatura')
            .order('nombre', ascending: true);

        setState(() {
          listaUnidadesMedida = nuevasUnidades as List;
          unidadMedidaSeleccionada = response['id'] as int;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unidad "${resultado['nombre']}" agregada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  showDialog(
    context: context,
    builder: (context) {
      int stock = 1;
      bool usarFechaPersonalizada = false;

      return StatefulBuilder(
        builder: (context, setState) {
          final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

          // Generar el código automáticamente
          String generarCodigo() {
            if (nombreController.text.isEmpty ||
                cantidadController.text.isEmpty ||
                presentacionSeleccionada == null ||
                unidadMedidaSeleccionada == null) {
              return '';
            }

            final unidad = listaUnidadesMedida.firstWhere(
              (u) => u['id'] == unidadMedidaSeleccionada,
              orElse: () => {'abreviatura': ''},
            );

            final presentacion = listaPresentaciones.firstWhere(
              (p) => p['id_presentacion'] == presentacionSeleccionada,
              orElse: () => {'descripcion': ''},
            );

            final abreviatura = unidad['abreviatura'] ?? '';
            final descripcionPres = presentacion['descripcion'] ?? '';
            final cantidadTexto = cantidadController.text.trim();
            final cantidadNum = double.tryParse(cantidadTexto);
            String cantidadFormateada = cantidadTexto;
            if (cantidadNum != null) {
              if (cantidadNum == cantidadNum.toInt()) {
                cantidadFormateada = cantidadNum.toInt().toString();
              } else {
                cantidadFormateada = cantidadNum.toString();
              }
            }
            // Formato: NombreCantidadUnidadPresentacion (sin espacios)
            final nombre = nombreController.text.trim().replaceAll(' ', '');
            return '$nombre$cantidadFormateada$abreviatura$descripcionPres'
                .toUpperCase();
          }

          return Dialog(
            child: Container(
              width: 550,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.90,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add_circle_outline, size: 22),
                        const SizedBox(width: 10),
                        const Text(
                          'Agregar producto',
                          style: TextStyle(
                            fontSize: 18,
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
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Información sobre campos automáticos
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.blue.withOpacity(0.2)
                                  : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.blue.withOpacity(0.4)
                                    : Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: isDarkMode
                                      ? Colors.blue[300]
                                      : Colors.blue[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'El código se generará automáticamente: Nombre + Medida + Unidad',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode
                                          ? Colors.blue[200]
                                          : Colors.blue[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: nombreController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del producto *',
                              border: OutlineInputBorder(),
                              hintText: 'Ej: Arroz, Frijoles, Aceite',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: presentacionSeleccionada,
                                  decoration: const InputDecoration(
                                    labelText: 'Presentación *',
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
                              ),
                              const SizedBox(width: 8),
                              Tooltip(
                                message: 'Agregar nueva presentación',
                                child: IconButton(
                                  onPressed: () => agregarNuevaPresentacion(
                                    context,
                                    setState,
                                  ),
                                  icon: const Icon(Icons.add_circle),
                                  color: isDarkMode
                                      ? Colors.green[300]
                                      : Colors.green[700],
                                  iconSize: 32,
                                  style: IconButton.styleFrom(
                                    backgroundColor: isDarkMode
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.green.withOpacity(0.1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Cantidad y Unidad de Medida en una fila
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Campo de cantidad
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: cantidadController,
                                  decoration: const InputDecoration(
                                    labelText: 'Cantidad *',
                                    border: OutlineInputBorder(),
                                    hintText: 'Ej: 500, 1, 2.5',
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: false,
                                      ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Dropdown de unidad de medida
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<int>(
                                  value: unidadMedidaSeleccionada,
                                  decoration: const InputDecoration(
                                    labelText: 'Unidad *',
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
                              const SizedBox(width: 8),
                              // Botón para agregar unidad de medida
                              Tooltip(
                                message: 'Agregar unidad de medida',
                                child: IconButton(
                                  onPressed: () => agregarNuevaUnidadMedida(
                                    context,
                                    setState,
                                  ),
                                  icon: const Icon(Icons.add_circle),
                                  color: isDarkMode
                                      ? Colors.blue[300]
                                      : Colors.blue[700],
                                  iconSize: 32,
                                  style: IconButton.styleFrom(
                                    backgroundColor: isDarkMode
                                        ? Colors.blue.withOpacity(0.2)
                                        : Colors.blue.withOpacity(0.1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Checkbox para omitir fecha de vencimiento
                          CheckboxListTile(
                            title: const Text(
                              'Sin fecha de vencimiento',
                              style: TextStyle(fontSize: 13),
                            ),
                            subtitle: const Text(
                              'Marcar si el producto no tiene fecha de caducidad',
                              style: TextStyle(fontSize: 11),
                            ),
                            value: sinFechaVencimiento,
                            onChanged: (value) {
                              setState(() {
                                sinFechaVencimiento = value ?? false;
                                if (sinFechaVencimiento) {
                                  fechaVencimientoController.clear();
                                }
                              });
                            },
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (!sinFechaVencimiento) ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: fechaVencimientoController,
                              decoration: const InputDecoration(
                                labelText: 'Fecha de vencimiento *',
                                border: OutlineInputBorder(),
                                hintText: 'YYYY-MM-DD',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              onTap: () async {
                                final fechaSeleccionada = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
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
                          const SizedBox(height: 10),
                          // Precios (opcionales)
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
                          const SizedBox(height: 10),
                          // Fecha de agregado (opcional)
                          CheckboxListTile(
                            title: const Text(
                              'Establecer fecha de agregado personalizada',
                              style: TextStyle(fontSize: 13),
                            ),
                            subtitle: const Text(
                              'Por defecto se usa la fecha y hora actual',
                              style: TextStyle(fontSize: 11),
                            ),
                            value: usarFechaPersonalizada,
                            onChanged: (value) {
                              setState(() {
                                usarFechaPersonalizada = value ?? false;
                                if (!usarFechaPersonalizada) {
                                  fechaAgregadoController.clear();
                                }
                              });
                            },
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (usarFechaPersonalizada) ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: fechaAgregadoController,
                              decoration: const InputDecoration(
                                labelText: 'Fecha de agregado',
                                border: OutlineInputBorder(),
                                hintText: 'YYYY-MM-DD HH:MM',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              onTap: () async {
                                final fechaSeleccionada = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );

                                if (fechaSeleccionada != null) {
                                  // Mostrar selector de hora
                                  final horaSeleccionada = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
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
                          ],
                          const SizedBox(height: 10),
                          const Divider(),
                          const SizedBox(height: 10),
                          // Cantidad a agregar
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      color: Colors.green[700],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Cantidad a agregar',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      onPressed: stock > 1
                                          ? () {
                                              setState(() {
                                                stock--;
                                                stockController.text = stock
                                                    .toString();
                                              });
                                            }
                                          : null,
                                      iconSize: 28,
                                      color: Colors.green,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 40,
                                        minHeight: 40,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: TextField(
                                        controller: stockController,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
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
                                          final nuevoStock =
                                              int.tryParse(value) ?? 1;
                                          setState(() {
                                            stock = nuevoStock.clamp(1, 9999);
                                            stockController.text = stock
                                                .toString();
                                            stockController.selection =
                                                TextSelection.fromPosition(
                                                  TextPosition(
                                                    offset: stockController
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
                                      onPressed: stock < 9999
                                          ? () {
                                              setState(() {
                                                stock++;
                                                stockController.text = stock
                                                    .toString();
                                              });
                                            }
                                          : null,
                                      iconSize: 28,
                                      color: Colors.green,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 40,
                                        minHeight: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Vista previa del código generado
                          if (generarCodigo().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Código generado:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    generarCodigo(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Footer con botones
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
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
                            final cantidad = cantidadController.text.trim();
                            final fechaVencimiento = fechaVencimientoController
                                .text
                                .trim();

                            // Validaciones
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

                            if (cantidad.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('La cantidad es obligatoria'),
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

                            if (!sinFechaVencimiento &&
                                fechaVencimiento.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'La fecha de vencimiento es obligatoria',
                                  ),
                                ),
                              );
                              return;
                            }

                            try {
                              final codigo = generarCodigo();

                              // Preparar datos base
                              final Map<String, dynamic> datosBase = {
                                'nombre_producto': nombre,
                                'codigo': codigo,
                                'id_presentacion': presentacionSeleccionada,
                                'id_unidad_medida': unidadMedidaSeleccionada,
                                'cantidad': double.tryParse(cantidad),
                              };

                              // Agregar fecha_vencimiento solo si tiene valor
                              if (!sinFechaVencimiento &&
                                  fechaVencimiento.isNotEmpty) {
                                datosBase['fecha_vencimiento'] =
                                    fechaVencimiento;
                              }

                              // Agregar precios solo si tienen valor
                              if (precioCompraController.text.isNotEmpty) {
                                datosBase['precio_compra'] = double.tryParse(
                                  precioCompraController.text,
                                );
                              }
                              if (precioVentaController.text.isNotEmpty) {
                                datosBase['precio_venta'] = double.tryParse(
                                  precioVentaController.text,
                                );
                              }

                              // Agregar fecha_agregado solo si se estableció
                              if (usarFechaPersonalizada &&
                                  fechaAgregadoController.text.isNotEmpty) {
                                datosBase['fecha_agregado'] =
                                    fechaAgregadoController.text;
                              }

                              // Insertar productos según el stock
                              for (int i = 0; i < stock; i++) {
                                await Supabase.instance.client
                                    .from('producto')
                                    .insert(datosBase);
                              }

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '$stock producto(s) agregado(s) correctamente',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              onSuccess();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error al agregar productos: $e',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Agregar productos'),
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
