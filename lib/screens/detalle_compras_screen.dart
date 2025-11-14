import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetalleCompraScreen extends StatefulWidget {
  final String idCompra;
  const DetalleCompraScreen({required this.idCompra, super.key});

  @override
  State<DetalleCompraScreen> createState() => _DetalleCompraScreenState();
}

class _DetalleCompraScreenState extends State<DetalleCompraScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> detalles = [];
  Map<String, dynamic>? compraInfo;

  Future<void> cargarDetalleCompra() async {
    final compra = await supabase
        .from('compras')
        .select('fecha_compra, total_compra,  proveedores(nombre_proveedor)')
        .eq('id_compras', widget.idCompra)
        .single();

    final detalle = await supabase
        .from('detalle_compras')
        .select('cantidad, precio_unitario, subtotal, productos(nombre_producto)')
        .eq('id_compras', widget.idCompra);

    setState(() {
      compraInfo = compra;
      detalles = List<Map<String, dynamic>>.from(detalle);
    });
  }

  @override
  void initState() {
    super.initState();
    cargarDetalleCompra();
  }

  @override
  Widget build(BuildContext context) {
    final fecha = compraInfo?['fecha_compra']?.split('T')[0] ?? '';
    final proveedor = compraInfo?['proveedores']?['nombre_proveedor'] ?? '';
    final total = compraInfo?['total_compra'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de compra'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver al reporte',
          onPressed: () => Navigator.pop(context)
        ),
      ),
      body: compraInfo == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Proveedor: $proveedor', style: const TextStyle(fontSize: 16)),
                  Text('Fecha: $fecha'),
                  Text('Total: \$${total.toStringAsFixed(2)}'),
                  const Divider(),
                  const Text('Productos comprados:', style: TextStyle(fontWeight: FontWeight.bold)),
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
