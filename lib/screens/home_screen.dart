import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool cargando = true;

  // Estadísticas
  int totalProductos = 0;
  int productosProximosVencer = 0;
  int productosStockBajo = 0;
  double ventasHoy = 0.0;
  double ventasMes = 0.0;
  double comprasMes = 0.0;
  int totalClientes = 0;
  int totalProveedores = 0;

  // Para gráficas
  String periodoSeleccionado = 'semana'; // 'semana' o 'mes'
  Map<String, int> ventasPorPeriodo = {}; // Para el bar chart
  double totalGanancias = 0.0;
  double totalGastos = 0.0;

  @override
  void initState() {
    super.initState();
    cargarEstadisticas();
  }

  Future<void> cargarEstadisticas() async {
    setState(() => cargando = true);

    try {
      // Total de productos disponibles
      final productosResponse = await Supabase.instance.client
          .from('producto')
          .select('id_producto, fecha_vencimiento, estado')
          .eq('estado', 'Disponible');

      totalProductos = productosResponse.length;

      // Productos próximos a vencer (30 días)
      final ahora = DateTime.now();
      final en30Dias = ahora.add(const Duration(days: 30));
      productosProximosVencer = productosResponse.where((p) {
        final fechaVenc = p['fecha_vencimiento'] as String?;
        if (fechaVenc == null) return false;
        final fecha = DateTime.parse(fechaVenc);
        return fecha.isAfter(ahora) && fecha.isBefore(en30Dias);
      }).length;

      // Productos con stock bajo (agrupados, menos de 5 unidades)
      final productosAgrupados = <String, int>{};
      for (final p in productosResponse) {
        final nombre = p['id_producto'].toString();
        productosAgrupados[nombre] = (productosAgrupados[nombre] ?? 0) + 1;
      }
      productosStockBajo = productosAgrupados.values
          .where((stock) => stock < 5)
          .length;

      // Ventas de hoy
      final hoyStr =
          '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')}';
      final ventasHoyResponse = await Supabase.instance.client
          .from('venta')
          .select('total')
          .eq('fecha', hoyStr);

      ventasHoy = ventasHoyResponse.fold<double>(
        0.0,
        (sum, v) => sum + ((v['total'] as num?)?.toDouble() ?? 0.0),
      );

      // Ventas del mes
      final inicioMesDate = DateTime(ahora.year, ahora.month, 1);
      final inicioMes =
          '${inicioMesDate.year}-${inicioMesDate.month.toString().padLeft(2, '0')}-${inicioMesDate.day.toString().padLeft(2, '0')}';
      final ventasMesResponse = await Supabase.instance.client
          .from('venta')
          .select('total')
          .gte('fecha', inicioMes);

      ventasMes = ventasMesResponse.fold<double>(
        0.0,
        (sum, v) => sum + ((v['total'] as num?)?.toDouble() ?? 0.0),
      );

      // Compras del mes
      final comprasMesResponse = await Supabase.instance.client
          .from('compra')
          .select('total')
          .gte('fecha', inicioMes);

      comprasMes = comprasMesResponse.fold<double>(
        0.0,
        (sum, c) => sum + ((c['total'] as num?)?.toDouble() ?? 0.0),
      );

      // Total de clientes
      final clientesResponse = await Supabase.instance.client
          .from('cliente')
          .select('id_cliente');
      totalClientes = clientesResponse.length;

      // Total de proveedores
      final proveedoresResponse = await Supabase.instance.client
          .from('proveedor')
          .select('id_proveedor');
      totalProveedores = proveedoresResponse.length;

      // Cargar datos para gráficas
      await cargarDatosGraficas();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar estadísticas: $e')),
        );
      }
    }

    setState(() => cargando = false);
  }

  Future<void> cargarDatosGraficas() async {
    try {
      final ahora = DateTime.now();

      // Cargar ventas por período para el bar chart
      if (periodoSeleccionado == 'semana') {
        // Últimos 7 días
        ventasPorPeriodo = {};
        for (int i = 6; i >= 0; i--) {
          final fecha = ahora.subtract(Duration(days: i));
          final fechaStr =
              '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
          final diaNombre = _obtenerNombreDia(fecha.weekday);

          final ventasResponse = await Supabase.instance.client
              .from('venta')
              .select('id_venta')
              .eq('fecha', fechaStr);

          ventasPorPeriodo[diaNombre] = ventasResponse.length;
        }
      } else {
        // Últimas 4 semanas del mes
        ventasPorPeriodo = {};
        final inicioMes = DateTime(ahora.year, ahora.month, 1);

        for (int semana = 1; semana <= 4; semana++) {
          final inicioSemana = inicioMes.add(Duration(days: (semana - 1) * 7));
          final finSemana = inicioSemana.add(const Duration(days: 6));

          final inicioStr =
              '${inicioSemana.year}-${inicioSemana.month.toString().padLeft(2, '0')}-${inicioSemana.day.toString().padLeft(2, '0')}';
          final finStr =
              '${finSemana.year}-${finSemana.month.toString().padLeft(2, '0')}-${finSemana.day.toString().padLeft(2, '0')}';

          final ventasResponse = await Supabase.instance.client
              .from('venta')
              .select('id_venta')
              .gte('fecha', inicioStr)
              .lte('fecha', finStr);

          ventasPorPeriodo['Semana $semana'] = ventasResponse.length;
        }
      }

      // Calcular ganancias y gastos para el pie chart
      final inicioMesDate = DateTime(ahora.year, ahora.month, 1);
      final inicioMes =
          '${inicioMesDate.year}-${inicioMesDate.month.toString().padLeft(2, '0')}-${inicioMesDate.day.toString().padLeft(2, '0')}';

      // Obtener todas las ventas del mes con productos
      final ventasResponse = await Supabase.instance.client
          .from('venta')
          .select('id_venta, total')
          .gte('fecha', inicioMes);

      double totalVentas = 0.0;
      double totalCostos = 0.0;

      for (var venta in ventasResponse) {
        final idVenta = venta['id_venta'];
        final totalVenta = (venta['total'] as num?)?.toDouble() ?? 0.0;
        totalVentas += totalVenta;

        // Obtener productos de la venta para calcular costos
        final productosVenta = await Supabase.instance.client
            .from('producto_en_venta')
            .select('producto(precio_compra)')
            .eq('id_venta', idVenta);

        for (var pv in productosVenta) {
          final producto = pv['producto'] as Map<String, dynamic>?;
          final precioCompra =
              (producto?['precio_compra'] as num?)?.toDouble() ?? 0.0;
          totalCostos += precioCompra;
        }
      }

      totalGanancias = totalVentas - totalCostos;
      totalGastos = comprasMes + totalCostos;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar gráficas: $e')));
      }
      // Valores por defecto en caso de error
      ventasPorPeriodo = {};
      totalGanancias = 0.0;
      totalGastos = 0.0;
    }
  }

  String _obtenerNombreDia(int weekday) {
    switch (weekday) {
      case 1:
        return 'Lun';
      case 2:
        return 'Mar';
      case 3:
        return 'Mié';
      case 4:
        return 'Jue';
      case 5:
        return 'Vie';
      case 6:
        return 'Sáb';
      case 7:
        return 'Dom';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: cargarEstadisticas,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                Icon(Icons.home, size: 32, color: Colors.blue[700]),
                const SizedBox(width: 12),
                const Text(
                  'Inicio',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Bienvenido al Dashboard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),

            // Sección de Inventario
            _buildSeccionTitulo('Inventario', Icons.inventory_2),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCardEstadistica(
                    'Total Productos',
                    totalProductos.toString(),
                    Icons.inventory,
                    Colors.blue,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCardEstadistica(
                    'Próximos a Vencer',
                    productosProximosVencer.toString(),
                    Icons.warning,
                    Colors.orange,
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCardEstadistica(
              'Stock Bajo (< 5 unidades)',
              productosStockBajo.toString(),
              Icons.trending_down,
              Colors.red,
              isDark,
              fullWidth: true,
            ),

            const SizedBox(height: 24),

            // Sección de Ventas
            _buildSeccionTitulo('Ventas', Icons.point_of_sale),
            const SizedBox(height: 12),
            _buildCardEstadistica(
              'Ventas Hoy',
              'C\$${ventasHoy.toStringAsFixed(2)}',
              Icons.today,
              Colors.green,
              isDark,
              fullWidth: true,
            ),
            const SizedBox(height: 12),
            _buildCardEstadistica(
              'Ventas del Mes',
              'C\$${ventasMes.toStringAsFixed(2)}',
              Icons.calendar_month,
              Colors.teal,
              isDark,
              fullWidth: true,
            ),

            const SizedBox(height: 24),

            // Sección de Compras
            _buildSeccionTitulo('Compras', Icons.shopping_cart),
            const SizedBox(height: 12),
            _buildCardEstadistica(
              'Compras del Mes',
              'C\$${comprasMes.toStringAsFixed(2)}',
              Icons.attach_money,
              Colors.purple,
              isDark,
              fullWidth: true,
            ),

            const SizedBox(height: 24),

            // Sección de Contactos
            _buildSeccionTitulo('Contactos', Icons.people),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCardEstadistica(
                    'Clientes',
                    totalClientes.toString(),
                    Icons.person,
                    Colors.indigo,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCardEstadistica(
                    'Proveedores',
                    totalProveedores.toString(),
                    Icons.business,
                    Colors.cyan,
                    isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sección de Rentabilidad (Pie Chart)
            _buildSeccionTitulo('Rentabilidad del Negocio', Icons.pie_chart),
            const SizedBox(height: 12),
            _buildPieChart(isDark),

            const SizedBox(height: 24),

            // Nota de actualización
            Center(
              child: Text(
                'Desliza hacia abajo para actualizar',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionTitulo(String titulo, IconData icono) {
    return Row(
      children: [
        Icon(icono, size: 24, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCardEstadistica(
    String titulo,
    String valor,
    IconData icono,
    Color color,
    bool isDark, {
    bool fullWidth = false,
  }) {
    return Card(
      elevation: 2,
      color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icono, color: color, size: 32),
                if (!fullWidth)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      valor,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            if (fullWidth) ...[
              const SizedBox(height: 8),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(bool isDark) {
    final total = totalGanancias + totalGastos;
    final porcentajeGanancias = total > 0
        ? (totalGanancias / total) * 100
        : 0.0;
    final porcentajeGastos = total > 0 ? (totalGastos / total) * 100 : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 350;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ganancias vs Gastos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (total == 0)
                  const SizedBox(
                    height: 200,
                    child: Center(child: Text('No hay datos disponibles')),
                  )
                else if (isMobile) ...[
                  // Layout vertical para mobile
                  SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            value: totalGanancias,
                            title: '${porcentajeGanancias.toStringAsFixed(0)}%',
                            color: Colors.green,
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: totalGastos,
                            title: '${porcentajeGastos.toStringAsFixed(0)}%',
                            color: Colors.red,
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Leyenda compacta
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLeyendaCompacta(
                        'Ganancias',
                        Colors.green,
                        totalGanancias,
                      ),
                      _buildLeyendaCompacta('Gastos', Colors.red, totalGastos),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Total: C\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else ...[
                  // Layout horizontal para tablet/desktop
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(
                                  value: totalGanancias,
                                  title:
                                      '${porcentajeGanancias.toStringAsFixed(1)}%',
                                  color: Colors.green,
                                  radius: 60,
                                  titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: totalGastos,
                                  title:
                                      '${porcentajeGastos.toStringAsFixed(1)}%',
                                  color: Colors.red,
                                  radius: 60,
                                  titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLeyendaItem(
                                'Ganancias',
                                Colors.green,
                                totalGanancias,
                              ),
                              const SizedBox(height: 8),
                              _buildLeyendaItem(
                                'Gastos',
                                Colors.red,
                                totalGastos,
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 4),
                              Text(
                                'Total: C\$${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  totalGanancias > totalGastos
                      ? '✅ El negocio es rentable este mes'
                      : '⚠️ Los gastos superan las ganancias este mes',
                  style: TextStyle(
                    fontSize: 12,
                    color: totalGanancias > totalGastos
                        ? Colors.green
                        : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeyendaCompacta(String label, Color color, double valor) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        ),
        Text(
          'C\$${valor.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 9, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildLeyendaItem(String label, Color color, double valor) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'C\$${valor.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
