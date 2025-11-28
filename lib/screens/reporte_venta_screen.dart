import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportesVentasScreen extends StatefulWidget {
  const ReportesVentasScreen({super.key});

  @override
  State<ReportesVentasScreen> createState() => _ReportesVentasScreenState();
}

class _ReportesVentasScreenState extends State<ReportesVentasScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> ventas = [];
  DateTime? fechaInicio;
  DateTime? fechaFin;
  List<int> ventasSeleccionadas = []; // IDs de ventas para reporte detallado
  late TabController _tabController;
  bool _isLoading = true; // Estado de carga

  // Filtros para reporte detallado
  String busquedaCliente = '';
  String ordenarPor =
      'fecha_desc'; // fecha_asc, fecha_desc, ganancia_asc, ganancia_desc, total_asc, total_desc, productos_asc, productos_desc

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    cargarVentas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> cargarVentas() async {
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

      // ✅ OPTIMIZACIÓN: Ejecutar consultas en paralelo
      final results = await Future.wait([
        // Consulta 1: Ventas con filtros
        _buildVentasQuery(fechaInicioStr, fechaFinStr),
        // Consulta 2: TODOS los productos en venta de una vez
        Supabase.instance.client
            .from('producto_en_venta')
            .select(
              'id_venta, producto(nombre_producto, codigo, precio_venta, precio_compra, cantidad, id_presentacion, id_unidad_medida)',
            ),
      ]);

      final ventasBase = List<Map<String, dynamic>>.from(results[0]);
      final todosProductos = List<Map<String, dynamic>>.from(results[1]);

      // ✅ Indexar productos por id_venta para acceso O(1)
      final productosPorVenta = <int, List<Map<String, dynamic>>>{};
      for (var p in todosProductos) {
        final idVenta = p['id_venta'] as int?;
        if (idVenta != null) {
          productosPorVenta.putIfAbsent(idVenta, () => []).add(p);
        }
      }

      // Procesar ventas SIN consultas adicionales
      for (var v in ventasBase) {
        final idVenta = v['id_venta'] as int;
        final listaProductos = productosPorVenta[idVenta] ?? [];

        double totalVenta = 0.0;
        double totalCosto = 0.0;

        for (var p in listaProductos) {
          final precioVenta =
              (p['producto']?['precio_venta'] as num?)?.toDouble() ?? 0.0;
          final precioCompra =
              (p['producto']?['precio_compra'] as num?)?.toDouble() ?? 0.0;
          totalVenta += precioVenta;
          totalCosto += precioCompra;
        }

        v['productos'] = listaProductos;
        v['total_calculado'] = totalVenta;
        v['total_costo'] = totalCosto;
        v['ganancia_total'] = totalVenta - totalCosto;
      }

      if (mounted) {
        setState(() {
          ventas = ventasBase;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar ventas: $e')));
      }
    }
  }

  Future<List<dynamic>> _buildVentasQuery(
    String? fechaInicio,
    String? fechaFin,
  ) async {
    var query = Supabase.instance.client
        .from('venta')
        .select(
          'id_venta, fecha, cliente(nombre_cliente), empleado(nombre_empleado), payment_method:payment_method_id(name, provider)',
        );

    if (fechaInicio != null) {
      query = query.gte('fecha', fechaInicio);
    }
    if (fechaFin != null) {
      query = query.lte('fecha', fechaFin);
    }

    return await query;
  }

  int _contarProductos(Map<String, dynamic> venta) {
    final productos = (venta['productos'] as List?) ?? [];
    return productos.length;
  }

  // PDF para reporte general (resumen de ventas)
  Future<Uint8List> _buildPdfGeneral(
    List<Map<String, dynamic>> ventasParaPdf,
  ) async {
    final pdf = pw.Document();

    final totalGeneral = ventasParaPdf.fold<double>(
      0.0,
      (sum, v) => sum + (v['total_calculado'] ?? 0.0),
    );
    final costoGeneral = ventasParaPdf.fold<double>(
      0.0,
      (sum, v) => sum + (v['total_costo'] ?? 0.0),
    );
    final gananciaGeneral = totalGeneral - costoGeneral;

    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Reporte General de Ventas',
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
              headers: const [
                'ID',
                'Fecha',
                'Cliente',
                'Productos',
                'Total Venta',
                'Ganancia',
              ],
              data: ventasParaPdf.map((v) {
                return [
                  v['id_venta'].toString(),
                  (v['fecha'] ?? '').toString(),
                  v['cliente']?['nombre_cliente']?.toString() ?? 'N/A',
                  _contarProductos(v).toString(),
                  'C\$${(v['total_calculado'] ?? 0.0).toStringAsFixed(2)}',
                  'C\$${(v['ganancia_total'] ?? 0.0).toStringAsFixed(2)}',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Total Vendido: C\$${totalGeneral.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Total Costo: C\$${costoGeneral.toStringAsFixed(2)}',
                    ),
                    pw.Text(
                      'Ganancia Total: C\$${gananciaGeneral.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // PDF para reporte detallado (productos por venta)
  Future<Uint8List> _buildPdfDetallado(
    List<Map<String, dynamic>> ventasParaPdf,
  ) async {
    final pdf = pw.Document();

    for (var venta in ventasParaPdf) {
      final productos = (venta['productos'] as List?) ?? [];

      // Agrupar productos iguales
      final Map<String, Map<String, dynamic>> productosAgrupados = {};
      for (final p in productos) {
        final prod = (p['producto'] as Map<String, dynamic>?) ?? {};
        final nombre = prod['nombre_producto']?.toString() ?? 'Sin nombre';
        final codigo = prod['codigo']?.toString() ?? 'N/A';
        final precioVenta = (prod['precio_venta'] as num?)?.toDouble();
        final precioCompra = (prod['precio_compra'] as num?)?.toDouble();

        final key = '$nombre|$codigo|$precioVenta|$precioCompra';

        if (!productosAgrupados.containsKey(key)) {
          productosAgrupados[key] = {
            'nombre': nombre,
            'codigo': codigo,
            'precio_venta': precioVenta,
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
                  'ID de Venta: ${venta['id_venta']}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text('Fecha: ${venta['fecha'] ?? 'N/A'}'),
              pw.Text(
                'Cliente: ${venta['cliente']?['nombre_cliente'] ?? 'N/A'}',
              ),
              pw.Text(
                'Empleado: ${venta['empleado']?['nombre_empleado'] ?? 'N/A'}',
              ),
              pw.Text(
                'Método de Pago: ${venta['payment_method']?['name'] ?? 'N/A'}',
              ),
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
                  'P. Venta',
                  'Ganancia Unit.',
                  'Ganancia Total',
                ],
                data: listaAgrupada.map((p) {
                  final precioCompra = p['precio_compra'] as double? ?? 0.0;
                  final precioVenta = p['precio_venta'] as double? ?? 0.0;
                  final cantidad = p['cantidad'] as int? ?? 0;
                  final gananciaUnit = precioVenta - precioCompra;
                  final gananciaTotal = gananciaUnit * cantidad;

                  return [
                    p['nombre']?.toString() ?? 'N/A',
                    p['codigo']?.toString() ?? 'N/A',
                    cantidad.toString(),
                    'C\$${precioCompra.toStringAsFixed(2)}',
                    'C\$${precioVenta.toStringAsFixed(2)}',
                    'C\$${gananciaUnit.toStringAsFixed(2)}',
                    'C\$${gananciaTotal.toStringAsFixed(2)}',
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Total Costo: C\$${(venta['total_costo'] ?? 0.0).toStringAsFixed(2)}',
                      ),
                      pw.Text(
                        'Total Venta: C\$${(venta['total_calculado'] ?? 0.0).toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Ganancia: C\$${(venta['ganancia_total'] ?? 0.0).toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
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
    if (ventas.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay ventas para exportar.')),
        );
      }
      return;
    }

    await Printing.layoutPdf(
      onLayout: (format) async => _buildPdfGeneral(ventas),
    );
  }

  Future<void> _exportarPdfDetallado() async {
    if (ventasSeleccionadas.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona al menos una venta.')),
        );
      }
      return;
    }

    final ventasFiltradas = ventas
        .where((v) => ventasSeleccionadas.contains(v['id_venta'] as int))
        .toList();

    await Printing.layoutPdf(
      onLayout: (format) async => _buildPdfDetallado(ventasFiltradas),
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
      cargarVentas(); // Recargar automáticamente
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
      cargarVentas(); // Recargar automáticamente
    }
  }

  double calcularTotalGeneral() {
    return ventas.fold(0.0, (sum, v) => sum + (v['total_calculado'] ?? 0.0));
  }

  double calcularCostoGeneral() {
    return ventas.fold(0.0, (sum, v) => sum + (v['total_costo'] ?? 0.0));
  }

  double calcularGananciaGeneral() {
    return calcularTotalGeneral() - calcularCostoGeneral();
  }

  List<Map<String, dynamic>> _filtrarYOrdenarVentas() {
    var ventasFiltradas = ventas.where((v) {
      if (busquedaCliente.isEmpty) return true;
      final nombreCliente = (v['cliente']?['nombre_cliente']?.toString() ?? '')
          .toLowerCase();
      return nombreCliente.contains(busquedaCliente.toLowerCase());
    }).toList();

    // Ordenar según criterio seleccionado
    ventasFiltradas.sort((a, b) {
      switch (ordenarPor) {
        case 'fecha_asc':
          return (a['fecha'] ?? '').toString().compareTo(
            (b['fecha'] ?? '').toString(),
          );
        case 'fecha_desc':
          return (b['fecha'] ?? '').toString().compareTo(
            (a['fecha'] ?? '').toString(),
          );
        case 'ganancia_asc':
          return ((a['ganancia_total'] ?? 0.0) as double).compareTo(
            (b['ganancia_total'] ?? 0.0) as double,
          );
        case 'ganancia_desc':
          return ((b['ganancia_total'] ?? 0.0) as double).compareTo(
            (a['ganancia_total'] ?? 0.0) as double,
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

    return ventasFiltradas;
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
                      'Total Vendido',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'C\$${calcularTotalGeneral().toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, color: Colors.blue),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'Total Costo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'C\$${calcularCostoGeneral().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'Ganancia Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'C\$${calcularGananciaGeneral().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
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
        // Lista de ventas
        Expanded(
          child: ListView.builder(
            itemCount: ventas.length,
            itemBuilder: (context, index) {
              final v = ventas[index];
              final ganancia = v['ganancia_total'] ?? 0.0;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.shopping_cart, color: Colors.blue),
                  title: Text(
                    'ID de Venta: ${v['id_venta']} - C\$${(v['total_calculado'] ?? 0.0).toStringAsFixed(2)}',
                  ),
                  subtitle: Text(
                    'Fecha: ${v['fecha']}\n'
                    'Cliente: ${v['cliente']?['nombre_cliente'] ?? 'N/A'}\n'
                    'Ganancia: C\$${ganancia.toStringAsFixed(2)}',
                  ),
                  trailing: Text(
                    '${_contarProductos(v)} productos',
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
    final ventasFiltradas = _filtrarYOrdenarVentas();

    // Calcular totales de ventas seleccionadas
    final ventasSeleccionadasData = ventasFiltradas
        .where((v) => ventasSeleccionadas.contains(v['id_venta'] as int))
        .toList();

    final totalVentaSeleccionada = ventasSeleccionadasData.fold<double>(
      0.0,
      (sum, v) => sum + (v['total_calculado'] ?? 0.0),
    );
    final totalCostoSeleccionado = ventasSeleccionadasData.fold<double>(
      0.0,
      (sum, v) => sum + (v['total_costo'] ?? 0.0),
    );
    final gananciaSeleccionada =
        totalVentaSeleccionada - totalCostoSeleccionado;

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
                    labelText: 'Buscar por cliente',
                    hintText: 'Nombre del cliente',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: busquedaCliente.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => busquedaCliente = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() => busquedaCliente = value);
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
                      value: 'ganancia_desc',
                      child: Text('Ganancia (mayor)'),
                    ),
                    DropdownMenuItem(
                      value: 'ganancia_asc',
                      child: Text('Ganancia (menor)'),
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
        // Resumen de ventas seleccionadas (compacto)
        if (ventasSeleccionadas.isNotEmpty)
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
                    '${ventasSeleccionadas.length} seleccionada(s)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Total: C\$${totalVentaSeleccionada.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Ganancia: C\$${gananciaSeleccionada.toStringAsFixed(2)}',
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
        // Lista scrolleable de todas las ventas (seleccionadas y disponibles)
        Expanded(
          child: ListView.builder(
            itemCount: ventasFiltradas.length,
            itemBuilder: (context, index) {
              final v = ventasFiltradas[index];
              final isSelected = ventasSeleccionadas.contains(
                v['id_venta'] as int,
              );
              return _buildVentaDetalladaCard(v, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVentaDetalladaCard(Map<String, dynamic> v, bool isSelected) {
    final idVenta = v['id_venta'] as int;
    final productos = (v['productos'] as List?) ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Agrupar productos
    final Map<String, Map<String, dynamic>> productosAgrupados = {};
    for (final p in productos) {
      final prod = (p['producto'] as Map<String, dynamic>?) ?? {};
      final nombre = prod['nombre_producto']?.toString() ?? 'Sin nombre';
      final codigo = prod['codigo']?.toString() ?? 'N/A';
      final precioVenta = (prod['precio_venta'] as num?)?.toDouble();
      final precioCompra = (prod['precio_compra'] as num?)?.toDouble();

      final key = '$nombre|$codigo|$precioVenta|$precioCompra';

      if (!productosAgrupados.containsKey(key)) {
        productosAgrupados[key] = {
          'nombre': nombre,
          'codigo': codigo,
          'precio_venta': precioVenta,
          'precio_compra': precioCompra,
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
                ventasSeleccionadas.add(idVenta);
              } else {
                ventasSeleccionadas.remove(idVenta);
              }
            });
          },
        ),
        title: Text(
          'ID de Venta: $idVenta - C\$${(v['total_calculado'] ?? 0.0).toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${v['fecha']} | ${v['cliente']?['nombre_cliente'] ?? 'N/A'} | Ganancia: C\$${(v['ganancia_total'] ?? 0.0).toStringAsFixed(2)}',
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
                            'Compra: C\$${precioCompra.toStringAsFixed(2)} | Venta: C\$${precioVenta.toStringAsFixed(2)} | Ganancia: C\$${gananciaTotal.toStringAsFixed(2)}',
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
                      'Costo: C\$${(v['total_costo'] ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Venta: C\$${(v['total_calculado'] ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Ganancia: C\$${(v['ganancia_total'] ?? 0.0).toStringAsFixed(2)}',
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
        appBar: AppBar(title: const Text('Reportes de Ventas')),
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
        title: const Text('Reportes de Ventas'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (_tabController.index == 0) {
                    _exportarPdfGeneral();
                  } else {
                    _exportarPdfDetallado();
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade600, Colors.red.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade900.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Exportar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
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
                      icon: const Icon(Icons.search),
                      tooltip: 'Aplicar filtros',
                      onPressed: cargarVentas,
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Limpiar filtros',
                      onPressed: () {
                        setState(() {
                          fechaInicio = null;
                          fechaFin = null;
                        });
                        cargarVentas();
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
        ),
      ),
    );
  }
}
