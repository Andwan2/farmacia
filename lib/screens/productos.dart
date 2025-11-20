import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmacia_desktop/providers/theme_provider.dart';
import 'package:farmacia_desktop/modal/editar_producto_modal.dart';
import 'package:farmacia_desktop/modal/agregar_producto_modal.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});
  @override
  State<ProductosScreen> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<ProductosScreen> {
  List<dynamic> productos = [];
  Map<int, Map<String, dynamic>> presentaciones =
      {}; // id_presentacion -> {descripcion, unidad_medida}
  Map<String, int> stockPorTipo = {};
  String busqueda = '';
  bool cargando = true;
  bool mostrarEliminados = false;

  // Filtros
  String? filtroTipo;
  String? filtroPresentacion;
  String ordenarPor =
      'nombre'; // nombre, precio_venta, precio_compra, vencimiento

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() => cargando = true);
    final client = Supabase.instance.client;

    // 1) Productos
    final resProd = await client
        .from('producto')
        .select(
          'id_producto,nombre_producto,id_presentacion,fecha_vencimiento,tipo,medida,esVisible,estado,fecha_agregado',
        )
        .eq('esVisible', mostrarEliminados ? false : true)
        .order('nombre_producto', ascending: true);

    final dataProd = (resProd is List) ? resProd : <dynamic>[];

    // 2) Presentaciones para mapear id_presentacion -> descripcion/unidad_medida
    final resPres = await client
        .from('presentacion')
        .select('id_presentacion,descripcion,unidad_medida')
        .order('id_presentacion', ascending: true);

    final dataPres = (resPres is List) ? resPres : <dynamic>[];
    final Map<int, Map<String, dynamic>> presMap = {};
    for (final p in dataPres) {
      final id = p['id_presentacion'] as int;
      presMap[id] = {
        'descripcion': p['descripcion'],
        'unidad_medida': p['unidad_medida'],
      };
    }

    // 3) Stock por tipo (conteo)
    final Map<String, int> stock = {};
    for (final item in dataProd) {
      final tipo = item['tipo'] as String;
      stock[tipo] = (stock[tipo] ?? 0) + 1;
    }

    setState(() {
      productos = dataProd;
      presentaciones = presMap;
      stockPorTipo = stock;
      cargando = false;
    });
  }

  Future<void> eliminarProducto(
    BuildContext context,
    Map<String, dynamic> producto,
  ) async {
    final nombre = producto['nombre_producto'] as String;
    final tipo = producto['tipo'] as String;
    final medida = producto['medida']?.toString() ?? '';
    final idPres = producto['id_presentacion'] as int;
    final presentacion = presentaciones[idPres]?['descripcion'] ?? '—';
    final unidad = presentaciones[idPres]?['unidad_medida'] ?? '';
    final fechaStr = producto['fecha_vencimiento'] as String;
    final fecha = DateTime.parse(fechaStr);
    final stockGrupo = producto['_stock_grupo'] as int? ?? 1;
    final tipoOriginal = producto['tipo'] as String;
    final fechaVencimientoOriginal =
        producto['fecha_vencimiento']?.toString().split('T').first ?? '';
    final estadoOriginal = producto['estado'] as String? ?? 'Comprado';

    bool eliminarTodos = true;
    int cantidadEliminar = 1;
    final cantidadController = TextEditingController(text: '1');
    String estadoSeleccionado = 'Vendido'; // Vendido o Removido

    final resultado = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

            return AlertDialog(
              title: const Text('Confirmar eliminación'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿Está seguro que desea eliminar este producto?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildInfoRow('Nombre:', nombre),
                    _buildInfoRow('Tipo:', tipo),
                    _buildInfoRow('Presentación:', '$presentacion ($unidad)'),
                    _buildInfoRow('Medida:', '$medida $unidad'),
                    _buildInfoRow('Stock:', '$stockGrupo unidades'),
                    _buildInfoRow(
                      'Fecha de vencimiento:',
                      fecha.toIso8601String().split('T').first,
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    // Opciones de eliminación
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.grey[800]
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.grey[600]!
                              : Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: isDarkMode
                                    ? Colors.orange[300]
                                    : Colors.orange[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Opciones de eliminación',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          RadioListTile<bool>(
                            title: const Text(
                              'Eliminar todos los productos del grupo',
                              style: TextStyle(fontSize: 13),
                            ),
                            value: true,
                            groupValue: eliminarTodos,
                            onChanged: (value) {
                              setState(() {
                                eliminarTodos = value!;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            visualDensity: VisualDensity.compact,
                          ),
                          RadioListTile<bool>(
                            title: const Text(
                              'Eliminar cantidad específica',
                              style: TextStyle(fontSize: 13),
                            ),
                            value: false,
                            groupValue: eliminarTodos,
                            onChanged: (value) {
                              setState(() {
                                eliminarTodos = value!;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            visualDensity: VisualDensity.compact,
                          ),
                          if (!eliminarTodos) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Cantidad a eliminar (Máx: $stockGrupo)',
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
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: cantidadEliminar > 1
                                      ? () {
                                          setState(() {
                                            cantidadEliminar--;
                                            cantidadController.text =
                                                cantidadEliminar.toString();
                                          });
                                        }
                                      : null,
                                  iconSize: 28,
                                  color: isDarkMode
                                      ? Colors.orange[300]
                                      : Colors.orange,
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
                                      final cantidad = int.tryParse(value) ?? 1;
                                      setState(() {
                                        cantidadEliminar = cantidad.clamp(
                                          1,
                                          stockGrupo,
                                        );
                                        cantidadController.text =
                                            cantidadEliminar.toString();
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
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: cantidadEliminar < stockGrupo
                                      ? () {
                                          setState(() {
                                            cantidadEliminar++;
                                            cantidadController.text =
                                                cantidadEliminar.toString();
                                          });
                                        }
                                      : null,
                                  iconSize: 28,
                                  color: isDarkMode
                                      ? Colors.orange[300]
                                      : Colors.orange,
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
                    const Divider(),
                    const SizedBox(height: 12),
                    // Selector de estado
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.grey[850]
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.label_outline,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Motivo de eliminación',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          RadioListTile<String>(
                            title: const Text(
                              'Vendido',
                              style: TextStyle(fontSize: 13),
                            ),
                            subtitle: const Text(
                              'El producto fue vendido',
                              style: TextStyle(fontSize: 11),
                            ),
                            value: 'Vendido',
                            groupValue: estadoSeleccionado,
                            onChanged: (value) {
                              setState(() {
                                estadoSeleccionado = value!;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            visualDensity: VisualDensity.compact,
                          ),
                          RadioListTile<String>(
                            title: const Text(
                              'Removido',
                              style: TextStyle(fontSize: 13),
                            ),
                            subtitle: const Text(
                              'El producto fue descartado o retirado',
                              style: TextStyle(fontSize: 11),
                            ),
                            value: 'Removido',
                            groupValue: estadoSeleccionado,
                            onChanged: (value) {
                              setState(() {
                                estadoSeleccionado = value!;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Esta acción no se puede deshacer.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'confirmar': true,
                      'eliminarTodos': eliminarTodos,
                      'cantidad': cantidadEliminar,
                      'estado': estadoSeleccionado,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Eliminar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (resultado != null && resultado['confirmar'] == true) {
      final estadoFinal = resultado['estado'] as String;

      try {
        if (resultado['eliminarTodos'] == true) {
          // Eliminar todos los productos del grupo con el mismo estado
          // Solo elimina productos activos (esVisible=true) que tengan el mismo estado
          await Supabase.instance.client
              .from('producto')
              .update({'esVisible': false, 'estado': estadoFinal})
              .eq('tipo', tipoOriginal)
              .eq('fecha_vencimiento', fechaVencimientoOriginal)
              .eq('estado', estadoOriginal)
              .eq('esVisible', true);

          await cargarDatos();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '$stockGrupo producto(s) eliminado(s) correctamente',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Eliminar solo una cantidad específica
          final cantidad = resultado['cantidad'] as int;

          // Obtener los IDs de los productos a eliminar con el mismo estado
          final productosGrupo = await Supabase.instance.client
              .from('producto')
              .select('id_producto')
              .eq('tipo', tipoOriginal)
              .eq('fecha_vencimiento', fechaVencimientoOriginal)
              .eq('estado', estadoOriginal)
              .eq('esVisible', true)
              .limit(cantidad);

          final listaProductos = productosGrupo as List;
          final idsEliminar = listaProductos
              .map((p) => p['id_producto'] as int)
              .toList();

          if (idsEliminar.isEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No se encontraron productos para eliminar'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }

          // Eliminar solo los productos seleccionados
          await Supabase.instance.client
              .from('producto')
              .update({'esVisible': false, 'estado': estadoFinal})
              .inFilter('id_producto', idsEliminar);

          await cargarDatos();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${idsEliminar.length} producto(s) eliminado(s) correctamente',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar productos: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Agrupar productos por tipo y rango de vencimiento
    final Map<String, List<dynamic>> gruposPorTipo = {};

    // Primero agrupar todos los productos por tipo y estado
    for (final p in productos) {
      final tipo = p['tipo'] as String;
      final estado = p['estado'] as String? ?? 'Comprado';
      final clave = '${tipo}_$estado'; // Agrupar por tipo Y estado
      if (!gruposPorTipo.containsKey(clave)) {
        gruposPorTipo[clave] = [];
      }
      gruposPorTipo[clave]!.add(p);
    }

    // Ahora separar por rangos de vencimiento si hay diferencias > 60 días
    final List<Map<String, dynamic>> productosAgrupados = [];

    for (final tipo in gruposPorTipo.keys) {
      final productosDelTipo = gruposPorTipo[tipo]!;

      // Ordenar por fecha de vencimiento
      productosDelTipo.sort((a, b) {
        final fechaA = DateTime.parse(a['fecha_vencimiento'] as String);
        final fechaB = DateTime.parse(b['fecha_vencimiento'] as String);
        return fechaA.compareTo(fechaB);
      });

      // Crear grupos por rango de vencimiento
      final List<List<dynamic>> rangosPorVencimiento = [];
      List<dynamic> grupoActual = [productosDelTipo[0]];
      DateTime fechaBaseGrupo = DateTime.parse(
        productosDelTipo[0]['fecha_vencimiento'] as String,
      );

      for (int i = 1; i < productosDelTipo.length; i++) {
        final producto = productosDelTipo[i];
        final fechaProducto = DateTime.parse(
          producto['fecha_vencimiento'] as String,
        );
        final diferenciaDias = fechaProducto.difference(fechaBaseGrupo).inDays;

        if (diferenciaDias <= 60) {
          // Mismo grupo
          grupoActual.add(producto);
        } else {
          // Nuevo grupo
          rangosPorVencimiento.add(grupoActual);
          grupoActual = [producto];
          fechaBaseGrupo = fechaProducto;
        }
      }
      rangosPorVencimiento.add(grupoActual);

      // Crear un representante para cada grupo
      for (final grupo in rangosPorVencimiento) {
        final representante = Map<String, dynamic>.from(grupo[0]);
        representante['_stock_grupo'] = grupo.length;
        representante['_fecha_min'] = grupo
            .map((p) => DateTime.parse(p['fecha_vencimiento'] as String))
            .reduce((a, b) => a.isBefore(b) ? a : b);
        representante['_fecha_max'] = grupo
            .map((p) => DateTime.parse(p['fecha_vencimiento'] as String))
            .reduce((a, b) => a.isAfter(b) ? a : b);
        productosAgrupados.add(representante);
      }
    }

    // Crear mapa para compatibilidad con filtros
    final Map<String, dynamic> productosPorTipo = {};
    for (final p in productosAgrupados) {
      final estado = p['estado'] as String? ?? 'Comprado';
      final key = '${p['tipo']}_${p['fecha_vencimiento']}_$estado';
      productosPorTipo[key] = p;
    }

    // Filtrar por búsqueda, tipo y presentación
    var listaFiltrada = productosPorTipo.values.where((p) {
      final nombre = p['nombre_producto']?.toString() ?? '';
      final tipo = p['tipo']?.toString() ?? '';
      final idPres = p['id_presentacion'] as int;
      final presentacion = presentaciones[idPres]?['descripcion'] ?? '';

      // Filtro de búsqueda
      final cumpleBusqueda =
          nombre.toLowerCase().contains(busqueda.toLowerCase()) ||
          tipo.toLowerCase().contains(busqueda.toLowerCase());

      // Filtro de tipo
      final cumpleTipo = filtroTipo == null || tipo == filtroTipo;

      // Filtro de presentación
      final cumplePresentacion =
          filtroPresentacion == null || presentacion == filtroPresentacion;

      return cumpleBusqueda && cumpleTipo && cumplePresentacion;
    }).toList();

    // Ordenar
    listaFiltrada.sort((a, b) {
      switch (ordenarPor) {
        case 'nombre':
          return (a['nombre_producto'] as String).compareTo(
            b['nombre_producto'] as String,
          );
        case 'vencimiento':
          final fechaA = DateTime.parse(a['fecha_vencimiento'] as String);
          final fechaB = DateTime.parse(b['fecha_vencimiento'] as String);
          return fechaA.compareTo(fechaB);
        case 'stock':
          final stockA = a['_stock_grupo'] as int? ?? 1;
          final stockB = b['_stock_grupo'] as int? ?? 1;
          return stockB.compareTo(stockA); // Descendente
        case 'agregado_reciente':
          final fechaA = a['fecha_agregado'] != null
              ? DateTime.parse(a['fecha_agregado'] as String)
              : DateTime(1970);
          final fechaB = b['fecha_agregado'] != null
              ? DateTime.parse(b['fecha_agregado'] as String)
              : DateTime(1970);
          return fechaB.compareTo(fechaA); // Descendente (más reciente primero)
        case 'agregado_antiguo':
          final fechaA = a['fecha_agregado'] != null
              ? DateTime.parse(a['fecha_agregado'] as String)
              : DateTime(1970);
          final fechaB = b['fecha_agregado'] != null
              ? DateTime.parse(b['fecha_agregado'] as String)
              : DateTime(1970);
          return fechaA.compareTo(fechaB); // Ascendente (más antiguo primero)
        default:
          return 0;
      }
    });

    return Scaffold(
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Campo de búsqueda
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar producto',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => busqueda = value),
                ),
                const SizedBox(height: 8),

                // Fila de filtros
                Row(
                  children: [
                    // Filtro por Tipo
                    Expanded(
                      child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          // Obtener tipos únicos
                          final tiposUnicos = productosPorTipo.values
                              .map((p) => p['tipo'] as String)
                              .toSet()
                              .toList();

                          if (textEditingValue.text.isEmpty) {
                            return tiposUnicos;
                          }
                          return tiposUnicos.where((String option) {
                            return option.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            );
                          });
                        },
                        onSelected: (String selection) {
                          setState(() => filtroTipo = selection);
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                              if (filtroTipo != null &&
                                  controller.text.isEmpty) {
                                controller.text = filtroTipo!;
                              }
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: 'Filtrar por tipo',
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  suffixIcon: filtroTipo != null
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              filtroTipo = null;
                                              controller.clear();
                                            });
                                          },
                                        )
                                      : null,
                                ),
                                onChanged: (value) {
                                  if (value.isEmpty) {
                                    setState(() => filtroTipo = null);
                                  }
                                },
                              );
                            },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Filtro por Presentación
                    Expanded(
                      child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final presentacionesUnicas = presentaciones.values
                              .map((p) => p['descripcion'] as String)
                              .toSet()
                              .toList();

                          if (textEditingValue.text.isEmpty) {
                            return presentacionesUnicas;
                          }
                          return presentacionesUnicas.where((String option) {
                            return option.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            );
                          });
                        },
                        onSelected: (String selection) {
                          setState(() => filtroPresentacion = selection);
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                              if (filtroPresentacion != null &&
                                  controller.text.isEmpty) {
                                controller.text = filtroPresentacion!;
                              }
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: 'Filtrar por presentación',
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  suffixIcon: filtroPresentacion != null
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              filtroPresentacion = null;
                                              controller.clear();
                                            });
                                          },
                                        )
                                      : null,
                                ),
                                onChanged: (value) {
                                  if (value.isEmpty) {
                                    setState(() => filtroPresentacion = null);
                                  }
                                },
                              );
                            },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Ordenar por
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: ordenarPor,
                        decoration: const InputDecoration(
                          labelText: 'Ordenar por',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'nombre',
                            child: Text('Nombre'),
                          ),
                          DropdownMenuItem(
                            value: 'vencimiento',
                            child: Text('Fecha de vencimiento'),
                          ),
                          DropdownMenuItem(
                            value: 'stock',
                            child: Text('Stock'),
                          ),
                          DropdownMenuItem(
                            value: 'agregado_reciente',
                            child: Text('Más reciente'),
                          ),
                          DropdownMenuItem(
                            value: 'agregado_antiguo',
                            child: Text('Más antiguo'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => ordenarPor = value!);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Switch para mostrar productos eliminados
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        title: Text(
                          mostrarEliminados
                              ? 'Mostrando productos eliminados'
                              : 'Mostrando productos activos',
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          mostrarEliminados
                              ? 'Los productos eliminados se muestran con su estado (Vendido/Removido)'
                              : 'Activa para ver productos eliminados',
                          style: const TextStyle(fontSize: 11),
                        ),
                        value: mostrarEliminados,
                        onChanged: (value) {
                          setState(() {
                            mostrarEliminados = value;
                          });
                          cargarDatos();
                        },
                        secondary: Icon(
                          mostrarEliminados
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: cargando
                ? const Center(child: CircularProgressIndicator())
                : Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return ListView.builder(
                        itemCount: listaFiltrada.length,
                        itemBuilder: (context, index) {
                          final p = listaFiltrada[index];
                          final nombre = p['nombre_producto'] as String;
                          final idPres = p['id_presentacion'] as int;
                          final tipo = p['tipo'] as String;
                          final medida = p['medida']?.toString() ?? '';
                          final presentacion =
                              presentaciones[idPres]?['descripcion'] ?? '—';
                          final unidad =
                              presentaciones[idPres]?['unidad_medida'] ?? '';
                          final fechaStr = p['fecha_vencimiento'] as String;
                          final fecha = DateTime.parse(fechaStr);
                          final diasRestantes = fecha
                              .difference(DateTime.now())
                              .inDays;

                          // Usar el stock del grupo si existe, sino usar el stock por tipo
                          final stockGrupo = p['_stock_grupo'] as int? ?? 1;
                          final fechaMin = p['_fecha_min'] as DateTime?;
                          final fechaMax = p['_fecha_max'] as DateTime?;
                          final estado = p['estado'] as String?;

                          return Card(
                            color: diasRestantes < 60
                                ? (themeProvider.isDarkMode
                                      ? Colors.orange[900]?.withOpacity(0.4)
                                      : Colors.orange[100])
                                : null,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ListTile(
                              title: Text(
                                nombre,
                                style: const TextStyle(fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$presentacion • $tipo'),
                                  Text(
                                    'Medida: $medida $unidad • Cantidad en Stock: $stockGrupo',
                                  ),
                                  if (mostrarEliminados && estado != null)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: estado == 'Vendido'
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.red.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: estado == 'Vendido'
                                              ? Colors.green
                                              : Colors.red,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        'Estado: $estado',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: estado == 'Vendido'
                                              ? Colors.green[800]
                                              : Colors.red[800],
                                        ),
                                      ),
                                    ),
                                  if (fechaMin != null &&
                                      fechaMax != null &&
                                      fechaMin != fechaMax)
                                    Text(
                                      'Rango de vencimiento: ${fechaMin.toIso8601String().split('T').first} - ${fechaMax.toIso8601String().split('T').first}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Vence: ${fecha.toIso8601String().split('T').first}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        diasRestantes < 60
                                            ? '⚠️ $diasRestantes días'
                                            : '$diasRestantes días',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: diasRestantes < 30
                                              ? Colors.red
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!mostrarEliminados) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        await mostrarEditarProducto(
                                          context,
                                          p,
                                          cargarDatos,
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () =>
                                          eliminarProducto(context, p),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await mostrarAgregarProducto(context, cargarDatos);
        },
        tooltip: 'Agregar producto',
        child: const Icon(Icons.add),
      ),
    );
  }
}
