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

class _ReportesVentasScreenState extends State<ReportesVentasScreen> {
  List<Map<String, dynamic>> ventas = [];
  DateTime? fechaInicio;
  DateTime? fechaFin;

  @override
  void initState() {
    super.initState();
    cargarVentas();
  }

  Future<void> cargarVentas() async {
    var query = Supabase.instance.client.from('venta').select(
      'id_venta, fecha, cliente(nombre_cliente), empleado(nombre_empleado), payment_method:payment_method_id(name, provider)',
    );

    // ✅ Filtros por rango de fechas si se seleccionaron
    if (fechaInicio != null) {
      final fechaInicioStr = fechaInicio!.toIso8601String().substring(0, 10);
      query = query.gte('fecha', fechaInicioStr);
    }

    if (fechaFin != null) {
      final fechaFinStr = fechaFin!.toIso8601String().substring(0, 10);
      query = query.lte('fecha', fechaFinStr);
    }

    final response = await query;
    final ventasBase = List<Map<String, dynamic>>.from(response);

    // 🔎 Calcular total dinámico por cada venta
    for (var v in ventasBase) {
      final producto = await Supabase.instance.client
          .from('producto_en_venta')
          .select('producto(nombre_producto, precio_venta, tipo)')
          .eq('id_venta', v['id_venta']);

      final listaProductos = List<Map<String, dynamic>>.from(producto);
      final total = listaProductos.fold<double>(
        0.0,
        (sum, p) => sum + ((p['producto']?['precio_venta'] as num?)?.toDouble() ?? 0.0),
      );

      v['productos'] = listaProductos;
      v['total_calculado'] = total;
    }

    setState(() {
      ventas = ventasBase;
    });
  }

  int _contarProductos(Map<String, dynamic> venta) {
    final productos = (venta['productos'] as List?) ?? [];
    return productos.length;
  }

  Future<Map<String, String>?> _mostrarDialogoFiltroPdf() async {
    String tipoFiltro = 'ninguno';
    String valorFiltro = '';

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filtros para reporte PDF'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: tipoFiltro,
                    decoration: const InputDecoration(labelText: 'Tipo de filtro'),
                    items: const [
                      DropdownMenuItem(value: 'ninguno', child: Text('Sin filtro adicional')),
                      DropdownMenuItem(value: 'cliente', child: Text('Por cliente')),
                      DropdownMenuItem(value: 'producto', child: Text('Por producto')),
                      DropdownMenuItem(value: 'metodo_pago', child: Text('Por método de pago')),
                      DropdownMenuItem(value: 'fecha', child: Text('Por fecha (YYYY-MM-DD)')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => tipoFiltro = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Valor a buscar',
                      hintText: 'Ej. nombre de cliente, producto, etc.',
                    ),
                    onChanged: (value) => valorFiltro = value,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'tipo': tipoFiltro,
                      'valor': valorFiltro.trim(),
                    });
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _filtrarVentasParaPdf(
    List<Map<String, dynamic>> origen,
    String tipo,
    String valor,
  ) {
    if (tipo == 'ninguno' || valor.isEmpty) {
      return List<Map<String, dynamic>>.from(origen);
    }

    final lower = valor.toLowerCase();

    if (tipo == 'cliente') {
      return origen
          .where((v) =>
              (v['cliente']?['nombre_cliente']?.toString().toLowerCase() ?? '')
                  .contains(lower))
          .toList();
    }

    if (tipo == 'fecha') {
      return origen
          .where((v) => (v['fecha']?.toString().toLowerCase() ?? '').contains(lower))
          .toList();
    }

    if (tipo == 'metodo_pago') {
      return origen
          .where((v) =>
              (v['payment_method']?['name']?.toString().toLowerCase() ?? '')
                  .contains(lower))
          .toList();
    }

    if (tipo == 'producto') {
      return origen.where((v) {
        final productos = (v['productos'] as List?) ?? [];
        return productos.any((p) =>
            (p['producto']?['nombre_producto']?.toString().toLowerCase() ?? '')
                .contains(lower));
      }).toList();
    }

    return List<Map<String, dynamic>>.from(origen);
  }

  Future<Uint8List> _buildPdf(
    List<Map<String, dynamic>> ventasParaPdf,
    String descripcionFiltro,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Reporte de ventas', style: pw.TextStyle(fontSize: 20)),
            ),
            pw.Text(
              'Rango de fechas: '
              '${fechaInicio != null ? '${fechaInicio!.day}/${fechaInicio!.month}/${fechaInicio!.year}' : 'Todas'}'
              ' - '
              '${fechaFin != null ? '${fechaFin!.day}/${fechaFin!.month}/${fechaFin!.year}' : 'Todas'}',
            ),
            if (descripcionFiltro.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text('Filtro aplicado: $descripcionFiltro'),
            ],
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: const [
                'ID',
                'Fecha',
                'Cliente',
                'Empleado',
                'Pago',
                'Productos',
                'Total',
              ],
              data: ventasParaPdf.map((v) {
                final productosCount = _contarProductos(v);
                return [
                  v['id_venta'].toString(),
                  (v['fecha'] ?? '').toString(),
                  v['cliente']?['nombre_cliente']?.toString() ?? 'N/A',
                  v['empleado']?['nombre_empleado']?.toString() ?? 'N/A',
                  v['payment_method']?['name']?.toString() ?? 'N/A',
                  productosCount.toString(),
                  'C\$${(v['total_calculado'] ?? 0.0).toStringAsFixed(2)}',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 10),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total general: C\$${ventasParaPdf.fold<double>(
                      0.0,
                      (sum, v) => sum + (v['total_calculado'] ?? 0.0),
                    ).toStringAsFixed(2)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _exportarPdf() async {
    if (ventas.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay ventas para exportar.')),
        );
      }
      return;
    }

    final filtro = await _mostrarDialogoFiltroPdf();
    if (filtro == null) return;

    final tipo = filtro['tipo'] ?? 'ninguno';
    final valor = filtro['valor'] ?? '';

    final ventasFiltradas = _filtrarVentasParaPdf(ventas, tipo, valor);
    if (ventasFiltradas.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontraron ventas con ese filtro.')),
        );
      }
      return;
    }

    final descripcionFiltro = tipo == 'ninguno' || valor.isEmpty
        ? 'Sin filtro adicional'
        : '$tipo = $valor';

    await Printing.layoutPdf(
      onLayout: (format) async => _buildPdf(ventasFiltradas, descripcionFiltro),
    );
  }

  void seleccionarFechaInicio() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      setState(() => fechaInicio = fecha);
    }
  }

  void seleccionarFechaFin() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaFin ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      setState(() => fechaFin = fecha);
    }
  }

  double calcularTotalGeneral() {
    return ventas.fold(0.0, (sum, v) => sum + (v['total_calculado'] ?? 0.0));
  }

  Future<void> mostrarProductosVenta(BuildContext context, int idVenta, List<Map<String, dynamic>> productos) async {
    showDialog(
      context: context,
      builder: (context) {
        // Agrupar productos iguales para obtener cantidad por producto
        final Map<String, Map<String, dynamic>> productosAgrupados = {};

        for (final p in productos) {
          final prod = (p['producto'] as Map<String, dynamic>?) ?? {};
          final nombre = prod['nombre_producto']?.toString() ?? 'Sin nombre';
          final tipo = prod['tipo']?.toString() ?? 'N/A';
          final precio = (prod['precio_venta'] as num?)?.toDouble();

          final key = '$nombre|$tipo|$precio';

          if (!productosAgrupados.containsKey(key)) {
            productosAgrupados[key] = {
              'nombre': nombre,
              'tipo': tipo,
              'precio': precio,
              'cantidad': 1,
            };
          } else {
            productosAgrupados[key]!['cantidad'] =
                (productosAgrupados[key]!['cantidad'] as int) + 1;
          }
        }

        final listaAgrupada = productosAgrupados.values.toList();

        return AlertDialog(
          title: Text('Productos de la venta $idVenta'),
          content: SizedBox(
            width: double.maxFinite,
            child: listaAgrupada.isEmpty
                ? const Text('No hay productos registrados en esta venta.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: listaAgrupada.length,
                    itemBuilder: (context, index) {
                      final p = listaAgrupada[index];
                      final precio = p['precio'] as double?;
                      final cantidad = p['cantidad'] as int? ?? 0;
                      return ListTile(
                        leading: const Icon(Icons.shopping_bag),
                        title: Text(p['nombre']?.toString() ?? 'Sin nombre'),
                        subtitle: Text(
                          'Precio: C\$${precio?.toStringAsFixed(2) ?? 'N/A'}\n'
                          'Cantidad en esta venta: $cantidad\n'
                          'Tipo: ${p['tipo'] ?? 'N/A'}',
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Ventas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar a PDF',
            onPressed: _exportarPdf,
          ),
        ],
      ),
      body: Column(
        children: [
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
          Expanded(
            child: ListView.builder(
              itemCount: ventas.length,
              itemBuilder: (context, index) {
                final v = ventas[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.shopping_cart),
                    title: Text(
                      'Venta #${v['id_venta'].toString()} - C\$${(v['total_calculado'] ?? 0.0).toStringAsFixed(2)}',
                    ),
                    subtitle: Text(
                      'Fecha: ${v['fecha']}\n'
                      'Cliente: ${v['cliente']?['nombre_cliente'] ?? 'N/A'}\n'
                      'Empleado: ${v['empleado']?['nombre_empleado'] ?? 'N/A'}\n'
                      'Metodo de Pago: ${v['payment_method']?['name'] ?? 'N/A'}\n'
                      'Proveedor: ${v['payment_method']?['provider'] ?? 'N/A'}\n'
                      'Productos: ${_contarProductos(v)}',
                    ),
                    onTap: () => mostrarProductosVenta(
                      context,
                      v['id_venta'] as int,
                      List<Map<String, dynamic>>.from(v['productos'] ?? []),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
