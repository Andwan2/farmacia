import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:abari/providers/theme_provider.dart';
import 'package:abari/modal/editar_producto_modal.dart';
import 'package:abari/modal/agregar_producto_modal.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});
  @override
  State<ProductosScreen> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<ProductosScreen> {
  List<dynamic> productos = [];
  Map<int, Map<String, dynamic>> presentaciones =
      {}; // id_presentacion -> {descripcion}
  Map<int, Map<String, dynamic>> unidadesMedida =
      {}; // id -> {nombre, abreviatura}
  Map<String, int> stockPorTipo = {};
  List<String> categorias = []; // Lista de categorías únicas
  String busqueda = '';
  bool cargando = true;
  bool mostrarEliminados = false;

  // Filtros
  List<String> filtrosPresentacion = []; // Múltiples presentaciones
  List<String> filtrosCategorias = []; // Múltiples categorías
  String ordenarPor =
      'nombre'; // nombre, precio_venta, precio_compra, vencimiento

  // Contador de filtros activos
  int get filtrosActivos {
    int count = 0;
    count += filtrosPresentacion.length;
    count += filtrosCategorias.length;
    if (ordenarPor != 'nombre') count++;
    return count;
  }

  // Helper para obtener nombre legible del orden
  String _getNombreOrden(String orden) {
    switch (orden) {
      case 'nombre':
        return 'Nombre';
      case 'vencimiento':
        return 'Vencimiento';
      case 'stock':
        return 'Stock';
      case 'agregado_reciente':
        return 'Más reciente';
      case 'agregado_antiguo':
        return 'Más antiguo';
      default:
        return orden;
    }
  }

  // Mostrar modal de filtros
  void _mostrarFiltros(BuildContext context) {
    // Variables temporales para los filtros
    List<String> tempFiltrosPresentacion = List.from(filtrosPresentacion);
    List<String> tempFiltrosCategorias = List.from(filtrosCategorias);
    String tempOrdenarPor = ordenarPor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Obtener presentaciones únicas
            final presentacionesUnicas =
                presentaciones.values
                    .map((p) => p['descripcion'] as String)
                    .toSet()
                    .toList()
                  ..sort();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header fijo
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtros',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempFiltrosPresentacion.clear();
                            tempFiltrosCategorias.clear();
                            tempOrdenarPor = 'nombre';
                          });
                        },
                        child: const Text('Limpiar todo'),
                      ),
                    ],
                  ),
                ),

                // Contenido scrolleable
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filtro por Categoría (múltiple)
                        if (categorias.isNotEmpty) ...[
                          const Text(
                            'Categoría',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: categorias.map((cat) {
                              final isSelected = tempFiltrosCategorias.contains(
                                cat,
                              );
                              return FilterChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setModalState(() {
                                    if (selected) {
                                      tempFiltrosCategorias.add(cat);
                                    } else {
                                      tempFiltrosCategorias.remove(cat);
                                    }
                                  });
                                },
                                selectedColor: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                                checkmarkColor: Theme.of(
                                  context,
                                ).colorScheme.secondary,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Filtro por Presentación (múltiple)
                        const Text(
                          'Presentación',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: presentacionesUnicas.map((pres) {
                            final isSelected = tempFiltrosPresentacion.contains(
                              pres,
                            );
                            return FilterChip(
                              label: Text(pres),
                              selected: isSelected,
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    tempFiltrosPresentacion.add(pres);
                                  } else {
                                    tempFiltrosPresentacion.remove(pres);
                                  }
                                });
                              },
                              selectedColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              checkmarkColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Ordenar por
                        const Text(
                          'Ordenar por',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('Nombre'),
                              selected: tempOrdenarPor == 'nombre',
                              onSelected: (selected) {
                                setModalState(() => tempOrdenarPor = 'nombre');
                              },
                              selectedColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              checkmarkColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                            ),
                            FilterChip(
                              label: const Text('Vencimiento'),
                              selected: tempOrdenarPor == 'vencimiento',
                              onSelected: (selected) {
                                setModalState(
                                  () => tempOrdenarPor = 'vencimiento',
                                );
                              },
                              selectedColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              checkmarkColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                            ),
                            FilterChip(
                              label: const Text('Stock'),
                              selected: tempOrdenarPor == 'stock',
                              onSelected: (selected) {
                                setModalState(() => tempOrdenarPor = 'stock');
                              },
                              selectedColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              checkmarkColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                            ),
                            FilterChip(
                              label: const Text('Más reciente'),
                              selected: tempOrdenarPor == 'agregado_reciente',
                              onSelected: (selected) {
                                setModalState(
                                  () => tempOrdenarPor = 'agregado_reciente',
                                );
                              },
                              selectedColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              checkmarkColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                            ),
                            FilterChip(
                              label: const Text('Más antiguo'),
                              selected: tempOrdenarPor == 'agregado_antiguo',
                              onSelected: (selected) {
                                setModalState(
                                  () => tempOrdenarPor = 'agregado_antiguo',
                                );
                              },
                              selectedColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              checkmarkColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Botones de acción
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: const Text('Cerrar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    filtrosPresentacion =
                                        tempFiltrosPresentacion;
                                    filtrosCategorias = tempFiltrosCategorias;
                                    ordenarPor = tempOrdenarPor;
                                  });
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Aplicar filtros'),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).viewInsets.bottom,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> cargarDatos() async {
    setState(() => cargando = true);
    final client = Supabase.instance.client;

    try {
      // ✅ OPTIMIZACIÓN: Ejecutar todas las consultas en paralelo
      final results = await Future.wait([
        // 0: Productos
        client
            .from('producto')
            .select()
            .order('nombre_producto', ascending: true),
        // 1: Presentaciones
        client.from('presentacion').select('id_presentacion,descripcion'),
        // 2: Unidades de medida
        client.from('unidad_medida').select('id,nombre,abreviatura'),
      ]);

      // Procesar productos
      List<dynamic> dataProd = (results[0] is List)
          ? results[0] as List
          : <dynamic>[];

      // Filtrar en memoria por estado
      if (mostrarEliminados) {
        dataProd = dataProd
            .where((p) => p['estado'] == 'Vendido' || p['estado'] == 'Removido')
            .toList();
      } else {
        dataProd = dataProd
            .where((p) => p['estado'] == null || p['estado'] == 'Disponible')
            .toList();
      }

      // Procesar presentaciones
      final dataPres = (results[1] is List) ? results[1] as List : <dynamic>[];
      final Map<int, Map<String, dynamic>> presMap = {};
      for (final p in dataPres) {
        final id = p['id_presentacion'] as int?;
        if (id != null) {
          presMap[id] = {'descripcion': p['descripcion']};
        }
      }

      // Procesar unidades de medida
      final dataUnidades = (results[2] is List)
          ? results[2] as List
          : <dynamic>[];
      final Map<int, Map<String, dynamic>> unidadesMap = {};
      for (final u in dataUnidades) {
        final id = u['id'] as int?;
        if (id != null) {
          unidadesMap[id] = {
            'nombre': u['nombre'],
            'abreviatura': u['abreviatura'],
          };
        }
      }

      // Stock por código (conteo en memoria)
      final Map<String, int> stock = {};
      for (final item in dataProd) {
        final codigo = item['codigo']?.toString() ?? 'Sin código';
        stock[codigo] = (stock[codigo] ?? 0) + 1;
      }

      // Extraer categorías únicas
      final Set<String> categoriasSet = {};
      for (final item in dataProd) {
        final cat = item['categoria']?.toString();
        if (cat != null && cat.isNotEmpty) {
          categoriasSet.add(cat);
        }
      }
      final categoriasLista = categoriasSet.toList()..sort();

      if (mounted) {
        setState(() {
          productos = dataProd;
          presentaciones = presMap;
          unidadesMedida = unidadesMap;
          stockPorTipo = stock;
          categorias = categoriasLista;
          cargando = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar datos: $e');
      if (mounted) {
        setState(() => cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar productos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> eliminarProducto(
    BuildContext context,
    Map<String, dynamic> producto,
  ) async {
    final nombre = producto['nombre_producto']?.toString() ?? 'Sin nombre';
    final codigo = producto['codigo']?.toString() ?? 'Sin código';
    final cantidad = producto['cantidad']?.toString() ?? '';
    final idPres = producto['id_presentacion'] as int?;
    final idUnidad = producto['id_unidad_medida'] as int?;
    final presentacion = idPres != null
        ? (presentaciones[idPres]?['descripcion'] ?? '—')
        : '—';
    final abreviatura = idUnidad != null
        ? (unidadesMedida[idUnidad]?['abreviatura'] ?? '')
        : '';
    final fechaStr = producto['fecha_vencimiento']?.toString();
    final fecha = fechaStr != null ? DateTime.tryParse(fechaStr) : null;
    final stockGrupo = (producto['_stock_grupo'] as num?)?.toInt() ?? 1;
    final esGranel = producto['_es_granel'] as bool? ?? false;
    final codigoOriginal = producto['codigo']?.toString() ?? 'Sin código';
    final fechaVencimientoOriginal = producto['fecha_vencimiento']
        ?.toString()
        .split('T')
        .first;
    final estadoOriginal = producto['estado'] as String? ?? 'Disponible';

    // Texto del stock con unidad de medida si es a granel
    final stockTexto = esGranel
        ? '$stockGrupo $abreviatura'
        : '$stockGrupo unidades';

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
                    _buildInfoRow('Código:', codigo),
                    _buildInfoRow('Presentación:', presentacion),
                    _buildInfoRow('Cantidad:', '$cantidad $abreviatura'),
                    _buildInfoRow('Stock:', stockTexto),
                    _buildInfoRow(
                      'Fecha de vencimiento:',
                      fecha?.toIso8601String().split('T').first ?? 'Sin fecha',
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
                          // Para productos a granel, mostrar mensaje informativo
                          if (esGranel)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Para productos a granel, se reducirá la cantidad del producto.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (!esGranel)
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
                          if (!esGranel)
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
                          // Para productos a granel, mostrar campo de cantidad a reducir
                          if (esGranel) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Cantidad a reducir (Máx: $stockGrupo $abreviatura)',
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
                          if (!esGranel && !eliminarTodos) ...[
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
                      'esGranel': esGranel,
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
      final esProductoGranel = resultado['esGranel'] as bool? ?? false;

      try {
        // Lógica especial para productos a granel
        if (esProductoGranel) {
          final cantidadReducir = resultado['cantidad'] as int;
          final cantidadActual = producto['cantidad'] as num? ?? 0;
          final nuevaCantidad = cantidadActual - cantidadReducir;

          if (nuevaCantidad <= 0) {
            // Si la cantidad llega a 0 o menos, marcar como eliminado
            if (fechaVencimientoOriginal != null) {
              await Supabase.instance.client
                  .from('producto')
                  .update({'estado': estadoFinal})
                  .eq('codigo', codigoOriginal)
                  .eq('fecha_vencimiento', fechaVencimientoOriginal)
                  .eq('estado', estadoOriginal);
            } else {
              await Supabase.instance.client
                  .from('producto')
                  .update({'estado': estadoFinal})
                  .eq('codigo', codigoOriginal)
                  .isFilter('fecha_vencimiento', null)
                  .eq('estado', estadoOriginal);
            }
          } else {
            // Reducir la cantidad del producto
            if (fechaVencimientoOriginal != null) {
              await Supabase.instance.client
                  .from('producto')
                  .update({'cantidad': nuevaCantidad})
                  .eq('codigo', codigoOriginal)
                  .eq('fecha_vencimiento', fechaVencimientoOriginal)
                  .eq('estado', estadoOriginal);
            } else {
              await Supabase.instance.client
                  .from('producto')
                  .update({'cantidad': nuevaCantidad})
                  .eq('codigo', codigoOriginal)
                  .isFilter('fecha_vencimiento', null)
                  .eq('estado', estadoOriginal);
            }
          }

          await cargarDatos();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  nuevaCantidad <= 0
                      ? 'Producto eliminado correctamente'
                      : 'Se redujo $cantidadReducir $abreviatura del stock',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else if (resultado['eliminarTodos'] == true) {
          // Eliminar todos los productos del grupo con el mismo estado
          // estadoOriginal ya garantiza que son productos disponibles
          if (fechaVencimientoOriginal != null) {
            await Supabase.instance.client
                .from('producto')
                .update({'estado': estadoFinal})
                .eq('codigo', codigoOriginal)
                .eq('fecha_vencimiento', fechaVencimientoOriginal)
                .eq('estado', estadoOriginal);
          } else {
            await Supabase.instance.client
                .from('producto')
                .update({'estado': estadoFinal})
                .eq('codigo', codigoOriginal)
                .isFilter('fecha_vencimiento', null)
                .eq('estado', estadoOriginal);
          }

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
          // estadoOriginal ya garantiza que son productos disponibles
          var selectQuery = Supabase.instance.client
              .from('producto')
              .select('id_producto')
              .eq('codigo', codigoOriginal);

          // Manejar fecha_vencimiento null correctamente
          if (fechaVencimientoOriginal != null) {
            selectQuery = selectQuery.eq(
              'fecha_vencimiento',
              fechaVencimientoOriginal,
            );
          } else {
            selectQuery = selectQuery.isFilter('fecha_vencimiento', null);
          }

          final productosGrupo = await selectQuery
              .eq('estado', estadoOriginal)
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
              .update({'estado': estadoFinal})
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

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Agrupar productos por tipo y rango de vencimiento
    final Map<String, List<dynamic>> gruposPorCodigo = {};

    // Primero agrupar todos los productos por código y estado
    for (final p in productos) {
      final codigo = p['codigo']?.toString() ?? 'Sin código';
      final estado = p['estado'] as String? ?? 'Disponible';
      final clave = '${codigo}_$estado'; // Agrupar por código Y estado
      if (!gruposPorCodigo.containsKey(clave)) {
        gruposPorCodigo[clave] = [];
      }
      gruposPorCodigo[clave]!.add(p);
    }

    // Ahora separar por rangos de vencimiento si hay diferencias > 60 días
    final List<Map<String, dynamic>> productosAgrupados = [];

    for (final codigoKey in gruposPorCodigo.keys) {
      final productosDelCodigo = gruposPorCodigo[codigoKey]!;

      // Ordenar por fecha de vencimiento
      productosDelCodigo.sort((a, b) {
        final fechaStrA = a['fecha_vencimiento']?.toString();
        final fechaStrB = b['fecha_vencimiento']?.toString();
        final fechaA = fechaStrA != null ? DateTime.tryParse(fechaStrA) : null;
        final fechaB = fechaStrB != null ? DateTime.tryParse(fechaStrB) : null;
        if (fechaA == null && fechaB == null) return 0;
        if (fechaA == null) return 1;
        if (fechaB == null) return -1;
        return fechaA.compareTo(fechaB);
      });

      // Crear grupos por rango de vencimiento
      final List<List<dynamic>> rangosPorVencimiento = [];
      List<dynamic> grupoActual = [productosDelCodigo[0]];
      final fechaBaseStr = productosDelCodigo[0]['fecha_vencimiento']
          ?.toString();
      DateTime? fechaBaseGrupo = fechaBaseStr != null
          ? DateTime.tryParse(fechaBaseStr)
          : null;

      for (int i = 1; i < productosDelCodigo.length; i++) {
        final producto = productosDelCodigo[i];
        final fechaProductoStr = producto['fecha_vencimiento']?.toString();
        final fechaProducto = fechaProductoStr != null
            ? DateTime.tryParse(fechaProductoStr)
            : null;
        final diferenciaDias = (fechaProducto != null && fechaBaseGrupo != null)
            ? fechaProducto.difference(fechaBaseGrupo).inDays
            : 0;

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

        // Verificar si es producto a granel
        final idPresentacion = representante['id_presentacion'] as int?;
        final descripcionPresentacion = idPresentacion != null
            ? (presentaciones[idPresentacion]?['descripcion']
                      ?.toString()
                      .toLowerCase() ??
                  '')
            : '';
        final esAGranel = descripcionPresentacion == 'a granel';

        if (esAGranel) {
          // Para productos a granel: stock = cantidad del producto (como double)
          final cantidad = representante['cantidad'] as num? ?? 0;
          representante['_stock_grupo'] = cantidad.toDouble();
          representante['_es_granel'] = true;
        } else {
          // Para otros productos: stock = cantidad de registros en el grupo
          representante['_stock_grupo'] = grupo.length.toDouble();
          representante['_es_granel'] = false;
        }
        final fechasValidas = grupo
            .map((p) {
              final fStr = p['fecha_vencimiento']?.toString();
              return fStr != null ? DateTime.tryParse(fStr) : null;
            })
            .whereType<DateTime>()
            .toList();
        if (fechasValidas.isNotEmpty) {
          representante['_fecha_min'] = fechasValidas.reduce(
            (a, b) => a.isBefore(b) ? a : b,
          );
          representante['_fecha_max'] = fechasValidas.reduce(
            (a, b) => a.isAfter(b) ? a : b,
          );
        }
        productosAgrupados.add(representante);
      }
    }

    // Crear mapa para compatibilidad con filtros
    final Map<String, dynamic> productosPorCodigo = {};
    for (final p in productosAgrupados) {
      final estado = p['estado'] as String? ?? 'Disponible';
      final key = '${p['codigo']}_${p['fecha_vencimiento']}_$estado';
      productosPorCodigo[key] = p;
    }

    // Filtrar por búsqueda, presentación y categoría
    var listaFiltrada = productosPorCodigo.values.where((p) {
      final nombre = p['nombre_producto']?.toString() ?? '';
      final idPres = p['id_presentacion'] as int?;
      final presentacion = idPres != null
          ? (presentaciones[idPres]?['descripcion'] ?? '')
          : '';
      final categoria = p['categoria']?.toString() ?? '';

      // Filtro de búsqueda
      final cumpleBusqueda = nombre.toLowerCase().contains(
        busqueda.toLowerCase(),
      );

      // Filtro de presentación
      final cumplePresentacion =
          filtrosPresentacion.isEmpty ||
          filtrosPresentacion.contains(presentacion);

      // Filtro de categoría
      final cumpleCategoria =
          filtrosCategorias.isEmpty || filtrosCategorias.contains(categoria);

      return cumpleBusqueda && cumplePresentacion && cumpleCategoria;
    }).toList();

    // Ordenar
    listaFiltrada.sort((a, b) {
      switch (ordenarPor) {
        case 'nombre':
          final nombreA = a['nombre_producto']?.toString() ?? '';
          final nombreB = b['nombre_producto']?.toString() ?? '';
          return nombreA.compareTo(nombreB);
        case 'vencimiento':
          final fechaStrA = a['fecha_vencimiento']?.toString();
          final fechaStrB = b['fecha_vencimiento']?.toString();
          final fechaA = fechaStrA != null
              ? DateTime.tryParse(fechaStrA)
              : null;
          final fechaB = fechaStrB != null
              ? DateTime.tryParse(fechaStrB)
              : null;
          if (fechaA == null && fechaB == null) return 0;
          if (fechaA == null) return 1;
          if (fechaB == null) return -1;
          return fechaA.compareTo(fechaB);
        case 'stock':
          final stockA = (a['_stock_grupo'] as num?)?.toInt() ?? 1;
          final stockB = (b['_stock_grupo'] as num?)?.toInt() ?? 1;
          return stockB.compareTo(stockA); // Descendente
        case 'agregado_reciente':
          final fechaAgregadoA = a['fecha_agregado']?.toString();
          final fechaAgregadoB = b['fecha_agregado']?.toString();
          final fechaA = fechaAgregadoA != null
              ? (DateTime.tryParse(fechaAgregadoA) ?? DateTime(1970))
              : DateTime(1970);
          final fechaB = fechaAgregadoB != null
              ? (DateTime.tryParse(fechaAgregadoB) ?? DateTime(1970))
              : DateTime(1970);
          return fechaB.compareTo(fechaA); // Descendente (más reciente primero)
        case 'agregado_antiguo':
          final fechaAgregadoA2 = a['fecha_agregado']?.toString();
          final fechaAgregadoB2 = b['fecha_agregado']?.toString();
          final fechaA = fechaAgregadoA2 != null
              ? (DateTime.tryParse(fechaAgregadoA2) ?? DateTime(1970))
              : DateTime(1970);
          final fechaB = fechaAgregadoB2 != null
              ? (DateTime.tryParse(fechaAgregadoB2) ?? DateTime(1970))
              : DateTime(1970);
          return fechaA.compareTo(fechaB); // Ascendente (más antiguo primero)
        default:
          return 0;
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              // Barra de búsqueda y filtros
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra de búsqueda con botón de filtros
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Buscar producto',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            onChanged: (value) =>
                                setState(() => busqueda = value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Botón de filtros con badge
                        Stack(
                          children: [
                            IconButton(
                              onPressed: () => _mostrarFiltros(context),
                              icon: const Icon(Icons.filter_list),
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                            if (filtrosActivos > 0)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    '$filtrosActivos',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    // Chips de filtros activos
                    if (filtrosPresentacion.isNotEmpty ||
                        filtrosCategorias.isNotEmpty ||
                        ordenarPor != 'nombre') ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...filtrosCategorias.map(
                            (cat) => Chip(
                              label: Text(cat),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                              onDeleted: () {
                                setState(() {
                                  filtrosCategorias.remove(cat);
                                });
                              },
                              deleteIcon: const Icon(Icons.close, size: 18),
                            ),
                          ),
                          ...filtrosPresentacion.map(
                            (pres) => Chip(
                              label: Text(pres),
                              onDeleted: () {
                                setState(() {
                                  filtrosPresentacion.remove(pres);
                                });
                              },
                              deleteIcon: const Icon(Icons.close, size: 18),
                            ),
                          ),
                          if (ordenarPor != 'nombre')
                            Chip(
                              label: Text(
                                'Orden: ${_getNombreOrden(ordenarPor)}',
                              ),
                              onDeleted: () =>
                                  setState(() => ordenarPor = 'nombre'),
                              deleteIcon: const Icon(Icons.close, size: 18),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Botón de agregar producto
                    ElevatedButton.icon(
                      onPressed: () async {
                        await mostrarAgregarProducto(context, cargarDatos);
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text('Agregar producto'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Switch
                    SwitchListTile(
                      title: Text(
                        mostrarEliminados
                            ? 'Mostrar solo productos inactivos'
                            : 'Mostrar solo productos activos',
                        style: const TextStyle(fontSize: 13),
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
                        size: 20,
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              // Lista de productos agrupados por categoría
              Expanded(
                child: cargando
                    ? const Center(child: CircularProgressIndicator())
                    : Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          final colorScheme = Theme.of(context).colorScheme;
                          final isDark = themeProvider.isDarkMode;

                          // Agrupar por categoría
                          final Map<String, List<dynamic>> porCategoria = {};
                          for (final p in listaFiltrada) {
                            final cat =
                                p['categoria']?.toString() ?? 'Sin categoría';
                            porCategoria.putIfAbsent(cat, () => []).add(p);
                          }
                          final categoriasOrdenadas = porCategoria.keys.toList()
                            ..sort();

                          return ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: categoriasOrdenadas.length,
                            itemBuilder: (context, catIndex) {
                              final categoria = categoriasOrdenadas[catIndex];
                              final productosCategoria =
                                  porCategoria[categoria]!;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Separador de categoría
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.fromLTRB(
                                      12,
                                      8,
                                      12,
                                      4,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondaryContainer
                                          .withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.category,
                                          size: 18,
                                          color: colorScheme.secondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          categoria,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.secondary,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${productosCategoria.length} items',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme
                                                .onSecondaryContainer,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Productos de esta categoría
                                  ...productosCategoria.map(
                                    (p) => _buildProductoCard(
                                      context,
                                      p,
                                      colorScheme,
                                      isDark,
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductoCard(
    BuildContext context,
    dynamic p,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final nombre = p['nombre_producto']?.toString() ?? 'Sin nombre';
    final idPres = p['id_presentacion'] as int?;
    final codigo = p['codigo']?.toString() ?? 'Sin código';
    final cantidad = p['cantidad']?.toString() ?? '';
    final idUnidad = p['id_unidad_medida'] as int?;
    final presentacion = idPres != null
        ? (presentaciones[idPres]?['descripcion'] ?? '')
        : '';
    final abreviatura = idUnidad != null
        ? (unidadesMedida[idUnidad]?['abreviatura'] ?? '')
        : '';
    final fechaStr = p['fecha_vencimiento']?.toString();
    final fecha = fechaStr != null ? DateTime.tryParse(fechaStr) : null;
    final diasRestantes = fecha != null
        ? fecha.difference(DateTime.now()).inDays
        : 0;
    final stockGrupoRaw = p['_stock_grupo'] as num? ?? 1;
    final esGranel = p['_es_granel'] as bool? ?? false;
    final estado = p['estado'] as String?;
    final precioCompra = p['precio_compra'] as num?;
    final precioVenta = p['precio_venta'] as num?;

    // Formatear stock: redondear a .5 o entero, mostrar decimal solo si no es .0
    String formatearStock(num valor) {
      // Redondear a .5 más cercano
      final redondeado = (valor * 2).round() / 2;
      if (redondeado == redondeado.toInt()) {
        return redondeado.toInt().toString();
      } else {
        return redondeado.toStringAsFixed(1);
      }
    }

    final stockFormateado = formatearStock(stockGrupoRaw);
    final stockGrupo = stockGrupoRaw.toDouble();

    // Texto del stock con unidad de medida si es a granel
    final stockTexto = esGranel
        ? '$stockFormateado $abreviatura'
        : stockFormateado;

    // Construir descripción de presentación compacta
    final presentacionCompleta = [
      if (presentacion.isNotEmpty) presentacion,
      if (cantidad.isNotEmpty) cantidad,
      if (abreviatura.isNotEmpty) abreviatura,
    ].join(' ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (fecha != null && diasRestantes < 30)
              ? Colors.red.withOpacity(0.5)
              : (fecha != null && diasRestantes < 60)
              ? Colors.orange.withOpacity(0.5)
              : colorScheme.outlineVariant,
          width: (fecha != null && diasRestantes < 60) ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: Nombre + Precio
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Badge de Stock (estilo similar a Precio)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: stockGrupo > 5
                      ? Colors.blue[600]
                      : stockGrupo > 0
                      ? Colors.orange[600]
                      : Colors.red[600],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Text(
                      'Stock',
                      style: TextStyle(fontSize: 9, color: Colors.white70),
                    ),
                    Text(
                      stockTexto,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Badge de Precio
              if (precioVenta != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      Text(
                        esGranel ? 'x $abreviatura' : 'x unidad',
                        style: TextStyle(fontSize: 9, color: Colors.green[100]),
                      ),
                      Text(
                        'C\$${precioVenta.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Fila 2: Presentación
          if (presentacionCompleta.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    presentacionCompleta,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

          // Fila 2.5: Código del producto
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.qr_code,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Código: $codigo',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Fila 3: Precio compra (si existe) + Estado (si eliminado)
          if (precioCompra != null ||
              (mostrarEliminados && estado != null)) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (precioCompra != null) ...[
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 12,
                    color: Colors.blue[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Costo: C\$${precioCompra.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 11, color: Colors.blue[600]),
                  ),
                ],
                const Spacer(),
                if (mostrarEliminados && estado != null)
                  _buildBadge(
                    icon: estado == 'Vendido'
                        ? Icons.sell
                        : Icons.delete_outline,
                    label: estado,
                    color: estado == 'Vendido' ? Colors.green : Colors.red,
                    isDark: isDark,
                  ),
              ],
            ),
          ],

          // Fila 4 (Footer): Vencimiento + Acciones
          const SizedBox(height: 8),
          Row(
            children: [
              // Vencimiento
              if (fecha != null)
                Expanded(
                  child: _buildVencimientoCompacto(
                    fecha,
                    diasRestantes,
                    isDark,
                  ),
                )
              else
                const Expanded(child: SizedBox()),

              // Acciones
              if (!mostrarEliminados) ...[
                InkWell(
                  onTap: () async {
                    await mostrarEditarProducto(context, p, cargarDatos);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => eliminarProducto(context, p),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVencimientoCompacto(
    DateTime fecha,
    int diasRestantes,
    bool isDark,
  ) {
    Color color;
    String texto;
    IconData icon;

    if (diasRestantes < 0) {
      color = Colors.red;
      icon = Icons.warning;
      texto = 'Vencido hace ${-diasRestantes}d';
    } else if (diasRestantes == 0) {
      color = Colors.red;
      icon = Icons.warning;
      texto = 'Vence hoy';
    } else if (diasRestantes <= 30) {
      color = Colors.red;
      icon = Icons.schedule;
      texto = '${fecha.day}/${fecha.month}/${fecha.year} ($diasRestantes días)';
    } else if (diasRestantes <= 60) {
      color = Colors.orange;
      icon = Icons.schedule;
      texto = '${fecha.day}/${fecha.month}/${fecha.year} ($diasRestantes días)';
    } else {
      color = Colors.grey;
      icon = Icons.event;
      texto = '${fecha.day}/${fecha.month}/${fecha.year} ($diasRestantes días)';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
