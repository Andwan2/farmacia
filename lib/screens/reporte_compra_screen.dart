import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  late TabController _tabController;

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
    var query = Supabase.instance.client.from('compra').select(
      'id_compras, fecha, total, metodo_pago, id_proveedor, id_empleado',
    );

    if (fechaInicio != null) {
      final fechaInicioStr = fechaInicio!.toIso8601String().substring(0, 10);
      query = query.gte('fecha', fechaInicioStr);
    }

    if (fechaFin != null) {
      final fechaFinStr = fechaFin!.toIso8601String().substring(0, 10);
      query = query.lte('fecha', fechaFinStr);
    }

    final response = await query;
    final comprasBase = List<Map<String, dynamic>>.from(response);

    // Obtener catálogo de proveedores para resolver nombres y RUC
    final proveedoresResponse = await Supabase.instance.client
        .from('proveedor')
        .select('id_proveedor, nombre_proveedor, ruc_proveedor');

    final proveedores = <int, Map<String, dynamic>>{};
    for (final p in proveedoresResponse) {
      final id = p['id_proveedor'] as int?;
      if (id != null) {
        proveedores[id] = p;
      }
    }

    for (var c in comprasBase) {
      final detalle = await Supabase.instance.client
          .from('producto_a_comprar')
          .select('precio_compra, producto(nombre_producto, tipo)')
          .eq('id_compra', c['id_compras']);

      final listaProductos = List<Map<String, dynamic>>.from(detalle);

      double totalCompra = 0.0;
      for (var p in listaProductos) {
        final precioCompra =
            (p['precio_compra'] as num?)?.toDouble() ?? 0.0;
        totalCompra += precioCompra;
      }

      c['productos'] = listaProductos;
      // Si la columna total en la tabla Compra no se usa, calculamos aquí
      c['total_calculado'] = c['total'] ?? totalCompra;

      // Asignar datos del proveedor si existen
      final provId = c['id_proveedor'] as int?;
      if (provId != null && proveedores.containsKey(provId)) {
        c['proveedor'] = proveedores[provId];
      }
    }

    setState(() {
      compras = comprasBase;
    });
  }

  int _contarProductos(Map<String, dynamic> compra) {
    final productos = (compra['productos'] as List?) ?? [];
    return productos.length;
  }

  double calcularTotalGeneral() {
    return compras.fold(0.0, (sum, c) => sum + (c['total_calculado'] ?? 0.0));
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
      cargarCompras();
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
      cargarCompras();
    }
  }

  Widget _buildTarjetaCompraResumen(Map<String, dynamic> c) {
    final proveedor = (c['proveedor'] as Map<String, dynamic>?) ?? {};
    final nombreProveedor =
        proveedor['nombre_proveedor']?.toString() ?? 'Proveedor #${c['id_proveedor']}';
    final rucProveedor = proveedor['ruc_proveedor']?.toString() ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.shopping_bag),
        title: Text(
          'Compra #${c['id_compras']} - C\$${(c['total_calculado'] ?? 0.0).toStringAsFixed(2)}',
        ),
        subtitle: Text(
          'Fecha: ${c['fecha']}\n'
          'Proveedor: $nombreProveedor (RUC: $rucProveedor)\n'
          'Empleado ID: ${c['id_empleado']}\n'
          'Método de Pago: ${c['metodo_pago'] ?? 'N/A'}\n'
          'Productos: ${_contarProductos(c)}',
        ),
      ),
    );
  }

  Widget _buildTarjetaCompraDetallada(Map<String, dynamic> c) {
    final productos = (c['productos'] as List?) ?? [];
    final proveedor = (c['proveedor'] as Map<String, dynamic>?) ?? {};
    final nombreProveedor =
        proveedor['nombre_proveedor']?.toString() ?? 'Proveedor #${c['id_proveedor']}';
    final rucProveedor = proveedor['ruc_proveedor']?.toString() ?? 'N/A';

    // Agrupar productos por nombre/tipo/precio_compra para obtener cantidad
    final Map<String, Map<String, dynamic>> productosAgrupados = {};
    for (final p in productos) {
      final prod = (p['producto'] as Map<String, dynamic>?) ?? {};
      final nombre = prod['nombre_producto']?.toString() ?? 'Sin nombre';
      final tipo = prod['tipo']?.toString() ?? 'N/A';
      final precioCompra = (p['precio_compra'] as num?)?.toDouble() ?? 0.0;

      final key = '$nombre|$tipo|$precioCompra';

      if (!productosAgrupados.containsKey(key)) {
        productosAgrupados[key] = {
          'nombre': nombre,
          'tipo': tipo,
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        leading: const Icon(Icons.receipt_long),
        title: Text(
          'Compra #${c['id_compras']} - C\$${(c['total_calculado'] ?? 0.0).toStringAsFixed(2)}',
        ),
        subtitle: Text(
          'Fecha: ${c['fecha']} | Proveedor: $nombreProveedor | Productos: ${_contarProductos(c)}',
        ),
        children: [
          Padding
          (
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Productos Comprados:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...listaAgrupada.map((p) {
                  final precioCompra = p['precio_compra'] as double? ?? 0.0;
                  final cantidad = p['cantidad'] as int? ?? 0;
                  final total = precioCompra * cantidad;
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.inventory_2),
                    title: Text('${p['nombre']} (${p['tipo']})'),
                    subtitle: Text(
                      'Cant: $cantidad  |  Precio compra: C\$${precioCompra.toStringAsFixed(2)}  |  Total: C\$${total.toStringAsFixed(2)}',
                    ),
                  );
                }),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Compras'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.summarize), text: 'Resumen'),
            Tab(icon: Icon(Icons.analytics), text: 'Detallado'),
          ],
        ),
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
                  onPressed: cargarCompras,
                ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Total general de compras: C\$${calcularTotalGeneral().toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Resumen
                compras.isEmpty
                    ? const Center(child: Text('No hay compras registradas.'))
                    : ListView.builder(
                        itemCount: compras.length,
                        itemBuilder: (context, index) =>
                            _buildTarjetaCompraResumen(compras[index]),
                      ),
                // Detallado
                compras.isEmpty
                    ? const Center(child: Text('No hay compras registradas.'))
                    : ListView.builder(
                        itemCount: compras.length,
                        itemBuilder: (context, index) =>
                            _buildTarjetaCompraDetallada(compras[index]),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
