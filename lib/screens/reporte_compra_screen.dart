import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportesComprasScreen extends StatefulWidget {
  const ReportesComprasScreen({super.key});

  @override
  State<ReportesComprasScreen> createState() => _ReportesComprasScreenState();
}

class _ReportesComprasScreenState extends State<ReportesComprasScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> compras = [];
  DateTime? fechaInicio;
  DateTime? fechaFin;
  List<int> comprasSeleccionadas = [];
  late TabController _tabController;
  bool _isLoading = true; // Estado de carga

  // Filtros para reporte detallado
  String busquedaProveedor = '';
  String ordenarPor =
      'fecha_desc'; // fecha_asc, fecha_desc, total_asc, total_desc, productos_asc, productos_desc

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    cargarCompras();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> cargarCompras() async {
    setState(() => _isLoading = true);

    try {
      // Construir filtros de fecha
      String? fechaInicioStr;
      String? fechaFinStr;

      if (fechaInicio != null) {
        fechaInicioStr = fechaInicio!.toIso8601String().substring(0, 10);
      }
      if (fechaFin != null) {
        fechaFinStr = fechaFin!.toIso8601String().substring(0, 10);
      }

      // ✅ OPTIMIZACIÓN: Ejecutar TODAS las consultas en paralelo
      final results = await Future.wait([
        // Consulta 1: Compras con filtros
        _buildComprasQuery(fechaInicioStr, fechaFinStr),
        // Consulta 2: Catálogo de proveedores
        Supabase.instance.client
            .from('proveedor')
            .select('id_proveedor, nombre_proveedor, ruc_proveedor'),
        // Consulta 3: TODOS los productos a comprar de una vez
        Supabase.instance.client
            .from('producto_a_comprar')
            .select(
              'id_compra, producto(precio_compra, precio_venta, nombre_producto, codigo, cantidad, id_presentacion, id_unidad_medida)',
            ),
      ]);

      final comprasBase = List<Map<String, dynamic>>.from(results[0]);
      final proveedoresResponse = List<Map<String, dynamic>>.from(results[1]);
      final todosProductos = List<Map<String, dynamic>>.from(results[2]);

      // ✅ Indexar proveedores por id para acceso O(1)
      final proveedores = <int, Map<String, dynamic>>{};
      for (final p in proveedoresResponse) {
        final id = p['id_proveedor'] as int?;
        if (id != null) {
          proveedores[id] = p;
        }
      }

      // ✅ Indexar productos por id_compra para acceso O(1)
      final productosPorCompra = <int, List<Map<String, dynamic>>>{};
      for (var p in todosProductos) {
        final idCompra = p['id_compra'] as int?;
        if (idCompra != null) {
          productosPorCompra.putIfAbsent(idCompra, () => []).add(p);
        }
      }

      // Procesar compras SIN consultas adicionales
      for (var c in comprasBase) {
        final idCompra = c['id_compras'] as int;
        final listaProductos = productosPorCompra[idCompra] ?? [];

        double totalCosto = 0.0;
        double totalVenta = 0.0;

        for (var p in listaProductos) {
          final producto = p['producto'] as Map<String, dynamic>?;
          final precioCompra =
              (producto?['precio_compra'] as num?)?.toDouble() ?? 0.0;
          final precioVenta =
              (producto?['precio_venta'] as num?)?.toDouble() ?? 0.0;
          totalCosto += precioCompra;
          totalVenta += precioVenta;
        }

        c['productos'] = listaProductos;
        c['total_costo'] = totalCosto;
        c['total_calculado'] = totalVenta;
        c['ganancia_total'] = totalVenta - totalCosto;

        // Asignar datos del proveedor
        final provId = c['id_proveedor'] as int?;
        if (provId != null && proveedores.containsKey(provId)) {
          c['proveedor'] = proveedores[provId];
        }
      }

      if (mounted) {
        setState(() {
          compras = comprasBase;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar compras: $e')));
      }
    }
  }

  Future<List<dynamic>> _buildComprasQuery(
    String? fechaInicio,
    String? fechaFin,
  ) async {
    var query = Supabase.instance.client
        .from('compra')
        .select(
          'id_compras, fecha, total, metodo_pago, id_proveedor, id_empleado',
        );

    if (fechaInicio != null) {
      query = query.gte('fecha', fechaInicio);
    }
    if (fechaFin != null) {
      query = query.lte('fecha', fechaFin);
    }

    return await query;
  }

  int _contarProductos(Map<String, dynamic> compra) {
    final productos = (compra['productos'] as List?) ?? [];
    return productos.length;
  }

  double calcularTotalCosto() {
    return compras.fold(0.0, (sum, c) => sum + (c['total_costo'] ?? 0.0));
  }

  double calcularTotalVentaEsperable() {
    return compras.fold(0.0, (sum, c) => sum + (c['total_calculado'] ?? 0.0));
  }

  double calcularGananciaEsperable() {
    return compras.fold(0.0, (sum, c) => sum + (c['ganancia_total'] ?? 0.0));
  }

  List<Map<String, dynamic>> _filtrarYOrdenarCompras() {
    var comprasFiltradas = compras.where((c) {
      if (busquedaProveedor.isEmpty) return true;
      final prov = (c['proveedor'] as Map<String, dynamic>?) ?? {};
      final nombreProveedor = (prov['nombre_proveedor']?.toString() ?? '')
          .toLowerCase();
      return nombreProveedor.contains(busquedaProveedor.toLowerCase());
    }).toList();

    // Ordenar según criterio seleccionado
    comprasFiltradas.sort((a, b) {
      switch (ordenarPor) {
        case 'fecha_asc':
          return (a['fecha'] ?? '').toString().compareTo(
            (b['fecha'] ?? '').toString(),
          );
        case 'fecha_desc':
          return (b['fecha'] ?? '').toString().compareTo(
            (a['fecha'] ?? '').toString(),
          );
        case 'total_asc':
          return ((a['total_calculado'] ?? 0.0) as double).compareTo(
            (b['total_calculado'] ?? 0.0) as double,
          );
        case 'total_desc':
          return ((b['total_calculado'] ?? 0.0) as double).compareTo(
            (a['total_calculado'] ?? 0.0) as double,
          );
        case 'productos_asc':
          return _contarProductos(a).compareTo(_contarProductos(b));
        case 'productos_desc':
          return _contarProductos(b).compareTo(_contarProductos(a));
        default:
          return 0;
      }
    });

    return comprasFiltradas;
  }

  // PDF para reporte general
  Future<Uint8List> _buildPdfGeneral(
    List<Map<String, dynamic>> comprasParaPdf,
  ) async {
    final pdf = pw.Document();

    final totalGeneral = comprasParaPdf.fold<double>(
      0.0,
      (sum, c) => sum + (c['total_calculado'] ?? 0.0),
    );

    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Reporte General de Compras',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Text(
              'Rango de fechas: '
              '${fechaInicio != null ? '${fechaInicio!.day}/${fechaInicio!.month}/${fechaInicio!.year}' : 'Todas'}'
              ' - '
              '${fechaFin != null ? '${fechaFin!.day}/${fechaFin!.month}/${fechaFin!.year}' : 'Todas'}',
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: const ['ID', 'Fecha', 'Proveedor', 'Productos', 'Total'],
              data: comprasParaPdf.map((c) {
                final prov = (c['proveedor'] as Map<String, dynamic>?) ?? {};
                final nombreProv =
                    prov['nombre_proveedor']?.toString() ?? 'N/A';
                return [
                  c['id_compras'].toString(),
                  (c['fecha'] ?? '').toString(),
                  nombreProv,
                  _contarProductos(c).toString(),
                  'C\$${(c['total_calculado'] ?? 0.0).toStringAsFixed(2)}',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Total General: C\$${totalGeneral.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // PDF para reporte detallado
  Future<Uint8List> _buildPdfDetallado(
    List<Map<String, dynamic>> comprasParaPdf,
  ) async {
    final pdf = pw.Document();

    for (var compra in comprasParaPdf) {
      final productos = (compra['productos'] as List?) ?? [];
      final prov = (compra['proveedor'] as Map<String, dynamic>?) ?? {};
      final nombreProv = prov['nombre_proveedor']?.toString() ?? 'N/A';

      // Agrupar productos iguales
      final Map<String, Map<String, dynamic>> productosAgrupados = {};
      for (final p in productos) {
        final prod = (p['producto'] as Map<String, dynamic>?) ?? {};
        final nombre = prod['nombre_producto']?.toString() ?? 'Sin nombre';
        final codigo = prod['codigo']?.toString() ?? 'N/A';
        final precioCompra = (p['precio_compra'] as num?)?.toDouble();

        final key = '$nombre|$codigo|$precioCompra';

        if (!productosAgrupados.containsKey(key)) {
          productosAgrupados[key] = {
            'nombre': nombre,
            'codigo': codigo,
            'precio_compra': precioCompra,
            'cantidad': 1,
          };
        } else {
          productosAgrupados[key]!['cantidad'] =
              (productosAgrupados[key]!['cantidad'] as int) + 1;
        }
      }

      final listaAgrupada = productosAgrupados.values.toList();

      pdf.addPage(
        pw.MultiPage(
          build: (context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'ID de Compra: ${compra['id_compras']}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text('Fecha: ${compra['fecha'] ?? 'N/A'}'),
              pw.Text('Proveedor: $nombreProv'),
              pw.Text('Método de Pago: ${compra['metodo_pago'] ?? 'N/A'}'),
              pw.SizedBox(height: 10),
              pw.Text(
                'Productos:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              pw.Table.fromTextArray(
                headers: const [
                  'Producto',
                  'Código',
                  'Cant.',
                  'P. Compra',
                  'Total',
                ],
                data: listaAgrupada.map((p) {
                  final precioCompra = p['precio_compra'] as double? ?? 0.0;
                  final cantidad = p['cantidad'] as int? ?? 0;
                  final total = precioCompra * cantidad;

                  return [
                    p['nombre']?.toString() ?? 'N/A',
                    p['codigo']?.toString() ?? 'N/A',
                    cantidad.toString(),
                    'C\$${precioCompra.toStringAsFixed(2)}',
                    'C\$${total.toStringAsFixed(2)}',
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total Compra: C\$${(compra['total_calculado'] ?? 0.0).toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ];
          },
        ),
      );
    }

    return pdf.save();
  }

  Future<void> _exportarPdfGeneral() async {
    if (compras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay compras para exportar.')),
        );
      }
      return;
    }

    await Printing.layoutPdf(
      onLayout: (format) async => _buildPdfGeneral(compras),
    );
  }

  Future<void> _exportarPdfDetallado() async {
    if (comprasSeleccionadas.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona al menos una compra.')),
        );
      }
      return;
    }

    final comprasFiltradas = compras
        .where((c) => comprasSeleccionadas.contains(c['id_compras'] as int))
        .toList();

    await Printing.layoutPdf(
      onLayout: (format) async => _buildPdfDetallado(comprasFiltradas),
    );
  }

  void seleccionarFechaInicio() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha != null && mounted) {
      setState(() => fechaInicio = fecha);
      cargarCompras(); // Recarga automática
    }
  }

  void seleccionarFechaFin() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaFin ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha != null && mounted) {
      setState(() => fechaFin = fecha);
      cargarCompras(); // Recarga automática
    }
  }

  Widget _buildReporteGeneral(bool isDark) {
    return Column(
      children: [
        // Resumen de totales
        Card(
          margin: const EdgeInsets.all(12),
          color: isDark ? Colors.blue[900]?.withOpacity(0.3) : Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Total Invertido',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'C\$${calcularTotalCosto().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'Venta Esperable',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'C\$${calcularTotalVentaEsperable().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'Ganancia Esperable',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'C\$${calcularGananciaEsperable().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Lista de compras
        Expanded(
          child: ListView.builder(
            itemCount: compras.length,
            itemBuilder: (context, index) {
              final c = compras[index];
              final prov = (c['proveedor'] as Map<String, dynamic>?) ?? {};
              final nombreProv = prov['nombre_proveedor']?.toString() ?? 'N/A';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.shopping_bag, color: Colors.blue),
                  title: Text(
                    'ID de Compra: ${c['id_compras']} - C\$${(c['total_calculado'] ?? 0.0).toStringAsFixed(2)}',
                  ),
                  subtitle: Text(
                    'Fecha: ${c['fecha']}\n'
                    'Proveedor: $nombreProv',
                  ),
                  trailing: Text(
                    '${_contarProductos(c)} productos',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReporteDetallado(bool isDark) {
    // Aplicar filtros y ordenamiento
    final comprasFiltradas = _filtrarYOrdenarCompras();

    // Calcular totales de compras seleccionadas
    final comprasSeleccionadasData = comprasFiltradas
        .where((c) => comprasSeleccionadas.contains(c['id_compras'] as int))
        .toList();

    final totalCostoSeleccionado = comprasSeleccionadasData.fold<double>(
      0.0,
      (sum, c) => sum + (c['total_costo'] ?? 0.0),
    );

    final totalVentaSeleccionada = comprasSeleccionadasData.fold<double>(
      0.0,
      (sum, c) => sum + (c['total_calculado'] ?? 0.0),
    );

    final gananciaSeleccionada = comprasSeleccionadasData.fold<double>(
      0.0,
      (sum, c) => sum + (c['ganancia_total'] ?? 0.0),
    );

    return Column(
      children: [
        // Filtros y búsqueda
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Buscar por proveedor',
                    hintText: 'Nombre del proveedor',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: busquedaProveedor.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => busquedaProveedor = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() => busquedaProveedor = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: ordenarPor,
                  decoration: const InputDecoration(
                    labelText: 'Ordenar por',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'fecha_desc',
                      child: Text('Fecha (más reciente)'),
                    ),
                    DropdownMenuItem(
                      value: 'fecha_asc',
                      child: Text('Fecha (más antigua)'),
                    ),
                    DropdownMenuItem(
                      value: 'total_desc',
                      child: Text('Total (mayor)'),
                    ),
                    DropdownMenuItem(
                      value: 'total_asc',
                      child: Text('Total (menor)'),
                    ),
                    DropdownMenuItem(
                      value: 'productos_desc',
                      child: Text('Productos (más)'),
                    ),
                    DropdownMenuItem(
                      value: 'productos_asc',
                      child: Text('Productos (menos)'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => ordenarPor = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        // Resumen de compras seleccionadas (compacto)
        if (comprasSeleccionadas.isNotEmpty)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: isDark
                ? Colors.green[900]?.withOpacity(0.3)
                : Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${comprasSeleccionadas.length} seleccionada(s)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Invertido: C\$${totalCostoSeleccionado.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Venta Esp.: C\$${totalVentaSeleccionada.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Ganancia Esp.: C\$${gananciaSeleccionada.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Lista scrolleable de todas las compras
        Expanded(
          child: ListView.builder(
            itemCount: comprasFiltradas.length,
            itemBuilder: (context, index) {
              final c = comprasFiltradas[index];
              final isSelected = comprasSeleccionadas.contains(
                c['id_compras'] as int,
              );
              return _buildCompraDetalladaCard(c, isSelected, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompraDetalladaCard(
    Map<String, dynamic> c,
    bool isSelected,
    bool isDark,
  ) {
    final idCompra = c['id_compras'] as int;
    final productos = (c['productos'] as List?) ?? [];
    final prov = (c['proveedor'] as Map<String, dynamic>?) ?? {};
    final nombreProv = prov['nombre_proveedor']?.toString() ?? 'N/A';

    // Agrupar productos
    final Map<String, Map<String, dynamic>> productosAgrupados = {};
    for (final p in productos) {
      final prod = (p['producto'] as Map<String, dynamic>?) ?? {};
      final nombre = prod['nombre_producto']?.toString() ?? 'Sin nombre';
      final codigo = prod['codigo']?.toString() ?? 'N/A';
      final precioCompra = (prod['precio_compra'] as num?)?.toDouble();
      final precioVenta = (prod['precio_venta'] as num?)?.toDouble();

      final key = '$nombre|$codigo|$precioCompra|$precioVenta';

      if (!productosAgrupados.containsKey(key)) {
        productosAgrupados[key] = {
          'nombre': nombre,
          'codigo': codigo,
          'precio_compra': precioCompra,
          'precio_venta': precioVenta,
          'cantidad': 1,
        };
      } else {
        productosAgrupados[key]!['cantidad'] =
            (productosAgrupados[key]!['cantidad'] as int) + 1;
      }
    }

    final listaAgrupada = productosAgrupados.values.toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: isSelected
          ? (isDark ? Colors.green[900]?.withOpacity(0.3) : Colors.green[50])
          : null,
      child: ExpansionTile(
        dense: true,
        leading: Checkbox(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                comprasSeleccionadas.add(idCompra);
              } else {
                comprasSeleccionadas.remove(idCompra);
              }
            });
          },
        ),
        title: Text(
          'ID de Compra: $idCompra - C\$${(c['total_calculado'] ?? 0.0).toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${c['fecha']} | Proveedor: $nombreProv',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Productos:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                ...listaAgrupada.map((p) {
                  final precioCompra = p['precio_compra'] as double? ?? 0.0;
                  final precioVenta = p['precio_venta'] as double? ?? 0.0;
                  final cantidad = p['cantidad'] as int? ?? 0;
                  final gananciaUnit = precioVenta - precioCompra;
                  final gananciaTotal = gananciaUnit * cantidad;

                  return Card(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    margin: const EdgeInsets.only(bottom: 4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${p['nombre']} (${p['codigo']}) - Cant: $cantidad',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Compra: C\$${precioCompra.toStringAsFixed(2)} | Venta Esp.: C\$${precioVenta.toStringAsFixed(2)} | Ganancia Esp.: C\$${gananciaTotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Invertido: C\$${(c['total_costo'] ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Venta Esp.: C\$${(c['total_calculado'] ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Ganancia Esp.: C\$${(c['ganancia_total'] ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Mostrar pantalla de carga mientras se cargan los datos
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reportes de Compras')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Cargando reportes...',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Compras'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf, size: 24),
              label: const Text('Exportar PDF', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                elevation: 4,
              ),
              onPressed: () {
                if (_tabController.index == 0) {
                  _exportarPdfGeneral();
                } else {
                  _exportarPdfDetallado();
                }
              },
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.summarize), text: 'Reporte General'),
            Tab(icon: Icon(Icons.analytics), text: 'Reporte Detallado'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filtros de fecha
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      fechaInicio != null
                          ? 'Desde: ${fechaInicio!.day}/${fechaInicio!.month}/${fechaInicio!.year}'
                          : 'Fecha inicio',
                    ),
                    onPressed: seleccionarFechaInicio,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      fechaFin != null
                          ? 'Hasta: ${fechaFin!.day}/${fechaFin!.month}/${fechaFin!.year}'
                          : 'Fecha fin',
                    ),
                    onPressed: seleccionarFechaFin,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Limpiar filtros',
                  onPressed: () {
                    setState(() {
                      fechaInicio = null;
                      fechaFin = null;
                    });
                    cargarCompras();
                  },
                ),
              ],
            ),
          ),
          // Contenido de tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReporteGeneral(isDark),
                _buildReporteDetallado(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
