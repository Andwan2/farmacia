import 'package:flutter/material.dart';
import 'widgets/add_product_button.dart';
import 'widgets/invoice_header_fields.dart';
import 'widgets/invoice_table.dart';
import 'widgets/invoice_actions.dart';

class FacturaScreen extends StatefulWidget {
  static const String pathName = '/factura';
  static const String routeName = 'factura';
  
  const FacturaScreen({super.key});

  @override
  State<FacturaScreen> createState() => _FacturaScreenState();
}

class _FacturaScreenState extends State<FacturaScreen> {
  // Datos de ejemplo
  final List<ProductoFactura> _productos = [];

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
              InvoiceHeaderFields(
                fecha: '12/12/2012',
                metodoPago: 'EFECTIVO',
                cliente: 'Casimiro Sotelo',
                empleado: 'Andre Abdul Mohamed',
                total: '1000\$',
              ),
              const SizedBox(height: 16),
              
              // Tabla de productos
              InvoiceTable(
                productos: _productos,
              ),

              const SizedBox(height: 24),
              
              // Barra de búsqueda
              AddProductButton(
                onProductSelected: (producto) {
                  // TODO: Agregar producto a la lista de la factura
                  print('Producto seleccionado: ${producto.nombreProducto}');
                },
              ),

              const SizedBox(height: 48),
              
              // Botones de acción
              InvoiceActions(
                onCancel: () {
                  // TODO: Implementar cancelación
                  Navigator.pop(context);
                },
                onConfirm: () {
                  // TODO: Implementar confirmación
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}