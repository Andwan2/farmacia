import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmacia_desktop/providers/theme_provider.dart';

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
          'id_producto,nombre_producto,id_presentacion,fecha_vencimiento,tipo,medida,esVisible',
        )
        .eq('esVisible', true)
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

  Future<void> eliminarProducto(int idProducto) async {
    await Supabase.instance.client
        .from('producto')
        .update({'esVisible': false})
        .eq('id_producto', idProducto);
    await cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    // Agrupar productos por tipo y rango de vencimiento
    final Map<String, List<dynamic>> gruposPorTipo = {};

    // Primero agrupar todos los productos por tipo
    for (final p in productos) {
      final tipo = p['tipo'] as String;
      if (!gruposPorTipo.containsKey(tipo)) {
        gruposPorTipo[tipo] = [];
      }
      gruposPorTipo[tipo]!.add(p);
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
      final key = '${p['tipo']}_${p['fecha_vencimiento']}';
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
                        ],
                        onChanged: (value) {
                          setState(() => ordenarPor = value!);
                        },
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
                          final idProducto = p['id_producto'] as int;
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
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      // TODO: Navegar a formulario de edición (usar id_producto)
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () =>
                                        eliminarProducto(idProducto),
                                  ),
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
        onPressed: () {
          // TODO: Navegar a formulario de agregar
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
