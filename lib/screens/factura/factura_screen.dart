import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farmacia_desktop/providers/factura_provider.dart';
import 'widgets/add_product_button.dart';
import 'widgets/invoice_header_fields.dart';
import 'widgets/invoice_table.dart';
import 'widgets/invoice_actions.dart';

class FacturaScreen extends StatelessWidget {
  static const String pathName = '/factura';
  static const String routeName = 'factura';
  
  const FacturaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FacturaProvider(),
      child: const _FacturaScreenContent(),
    );
  }
}

class _FacturaScreenContent extends StatelessWidget {
  const _FacturaScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              const Text(
                'Ventas',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1E1E),
                  height: 1.2,
                  letterSpacing: -0.96,
                ),
              ),

              const SizedBox(height: 24),
              
              // Campos de encabezado
              const InvoiceHeaderFields(),
              const SizedBox(height: 16),
              
              // Tabla de productos
              Consumer<FacturaProvider>(
                builder: (context, provider, child) {
                  return InvoiceTable(
                    productos: provider.productos,
                  );
                },
              ),

              const SizedBox(height: 24),
              
              // Botón agregar producto
              AddProductButton(
                onProductSelected: (producto) {
                  final provider = context.read<FacturaProvider>();
                  provider.agregarProducto(producto);
                },
              ),

              const SizedBox(height: 48),
              
              // Botones de acción
              InvoiceActions(
                onCancel: () {
                  final provider = context.read<FacturaProvider>();
                  provider.limpiarFactura();
                  Navigator.pop(context);
                },
                onConfirm: () {
                  // TODO: Implementar confirmación y guardar en DB
                  final provider = context.read<FacturaProvider>();
                  print('Total: \$${provider.total}');
                  print('Productos: ${provider.productos.length}');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}