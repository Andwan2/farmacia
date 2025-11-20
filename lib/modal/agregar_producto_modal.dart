import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:farmacia_desktop/providers/theme_provider.dart';

Future<void> mostrarAgregarProducto(
  BuildContext context,
  VoidCallback onSuccess,
) async {
  final nombreController = TextEditingController();
  final medidaController = TextEditingController();
  final cantidadController = TextEditingController(text: '1');
  final fechaVencimientoController = TextEditingController();
  final fechaAgregadoController = TextEditingController();

  // Cargar presentaciones disponibles
  final presentaciones = await Supabase.instance.client
      .from('presentacion')
      .select('id_presentacion,descripcion,unidad_medida')
      .order('descripcion', ascending: true);

  final listaPresentaciones = presentaciones as List;
  int? presentacionSeleccionada;

  showDialog(
    context: context,
    builder: (context) {
      int cantidad = 1;
      bool usarFechaPersonalizada = false;

      return StatefulBuilder(
        builder: (context, setState) {
          final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

          // Generar el tipo automáticamente
          String generarTipo() {
            if (nombreController.text.isEmpty ||
                medidaController.text.isEmpty ||
                presentacionSeleccionada == null) {
              return '';
            }

            final presentacion = listaPresentaciones.firstWhere(
              (p) => p['id_presentacion'] == presentacionSeleccionada,
              orElse: () => {'unidad_medida': ''},
            );

            final unidadMedida = presentacion['unidad_medida'] ?? '';
            // Formatear medida: si es entero mostrar sin decimales, si es decimal mantenerlo
            final medidaTexto = medidaController.text.trim();
            final medidaNum = double.tryParse(medidaTexto);
            String medidaFormateada = medidaTexto;
            if (medidaNum != null) {
              // Si es un número entero, mostrar sin decimales
              if (medidaNum == medidaNum.toInt()) {
                medidaFormateada = medidaNum.toInt().toString();
              } else {
                // Si es decimal, mantener el valor tal cual
                medidaFormateada = medidaNum.toString();
              }
            }
            return '${nombreController.text} $medidaFormateada $unidadMedida';
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
                                    'El tipo se generará automáticamente: Nombre + Medida + Unidad',
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
                              hintText: 'Ej: Paracetamol',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<int>(
                            value: presentacionSeleccionada,
                            decoration: const InputDecoration(
                              labelText: 'Presentación *',
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
                              labelText: 'Medida *',
                              border: OutlineInputBorder(),
                              hintText: 'Ej: 500 o 2.5',
                              helperText: 'Puede ser entero o decimal',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: false,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 10),
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
                                      onPressed: cantidad > 1
                                          ? () {
                                              setState(() {
                                                cantidad--;
                                                cantidadController.text =
                                                    cantidad.toString();
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
                                        controller: cantidadController,
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
                                          final nuevaCantidad =
                                              int.tryParse(value) ?? 1;
                                          setState(() {
                                            cantidad = nuevaCantidad.clamp(
                                              1,
                                              9999,
                                            );
                                            cantidadController.text = cantidad
                                                .toString();
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
                                      onPressed: cantidad < 9999
                                          ? () {
                                              setState(() {
                                                cantidad++;
                                                cantidadController.text =
                                                    cantidad.toString();
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
                          // Vista previa del tipo generado
                          if (generarTipo().isNotEmpty)
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
                                    'Tipo generado:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    generarTipo(),
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
                            final medida = medidaController.text.trim();
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

                            if (medida.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('La medida es obligatoria'),
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

                            try {
                              final tipo = generarTipo();

                              // Preparar datos base
                              final datosBase = {
                                'nombre_producto': nombre,
                                'tipo': tipo,
                                'id_presentacion': presentacionSeleccionada,
                                'medida': double.tryParse(medida),
                                'fecha_vencimiento': fechaVencimiento,
                              };

                              // Agregar fecha_agregado solo si se estableció
                              if (usarFechaPersonalizada &&
                                  fechaAgregadoController.text.isNotEmpty) {
                                datosBase['fecha_agregado'] =
                                    fechaAgregadoController.text;
                              }
                              // Si no se establece, Supabase usará el default automático

                              // Insertar productos según la cantidad
                              for (int i = 0; i < cantidad; i++) {
                                await Supabase.instance.client
                                    .from('producto')
                                    .insert(datosBase);
                              }

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '$cantidad producto(s) agregado(s) correctamente',
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
