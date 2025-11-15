import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetalleVentaScreen extends StatefulWidget {
  final String idVenta;
  const DetalleVentaScreen({required this.idVenta, super.key});

  @override
  State<DetalleVentaScreen> createState() => _DetalleVentaScreenState();
}

class _DetalleVentaScreenState extends State<DetalleVentaScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> detalles = [];
  Map<String, dynamic>? ventaInfo;

  Future<void> cargarDetalleVenta() async {
    final venta = await supabase
        .from('venta')
        .select('fecha_hora, total_pago, metodo_pago, clientes(nombre_cliente)')
        .eq('id_venta', widget.idVenta)
        .single();

    final detalle = await supabase
        .from('detalle_ventas')
        .select('cantidad, precio_unitario, subtotal, productos(nombre_producto)')
        .eq('id_venta', widget.idVenta);

    setState(() {
      ventaInfo = venta;
      detalles = List<Map<String, dynamic>>.from(detalle);
    });
  }

 @override
  void initState() {
    super.initState();
    if (widget.idVenta.isEmpty || widget.idVenta == 'null') {
      debugPrint('ID de venta inválido');
      return;
    }
    cargarDetalleVenta();
  }


  @override
  Widget build(BuildContext context) {
    final fecha = ventaInfo?['fecha_hora']?.split('T')[0] ?? '';
    final cliente = ventaInfo?['clientes']?['nombre_cliente'] ?? '';
    final total = ventaInfo?['total_pago'] ?? 0;
    final metodo = ventaInfo?['metodo_pago'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de venta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver al reporte',
          onPressed: () => context.pop('/reporteVenta'),
        ),
      ),
      body: ventaInfo == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cliente: $cliente', style: const TextStyle(fontSize: 16)),
                  Text('Fecha: $fecha'),
                  Text('Método de pago: $metodo'),
                  Text('Total: \$${total.toStringAsFixed(2)}'),
                  const Divider(),
                  const Text('Productos vendidos:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: detalles.length,
                      itemBuilder: (context, index) {
                        final item = detalles[index];
                        return ListTile(
                          title: Text(item['productos']['nombre_producto']),
                          subtitle: Text(
                              'Cantidad: ${item['cantidad']} | Precio: \$${item['precio_unitario']} | Subtotal: \$${item['subtotal']}'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
