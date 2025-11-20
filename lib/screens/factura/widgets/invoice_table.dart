import 'package:flutter/material.dart';

class ProductoFactura {
  final int cantidad;
  final String nombre;
  final String presentacion;
  final String medida;
  final String fechaVencimiento;
  final double precio;

  ProductoFactura({
    required this.cantidad,
    required this.nombre,
    required this.presentacion,
    required this.medida,
    required this.fechaVencimiento,
    required this.precio,
  });
}

class InvoiceTable extends StatelessWidget {
  final List<ProductoFactura> productos;

  const InvoiceTable({
    super.key,
    required this.productos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFFE6E0E9),
            child: Row(
              children: [
                _buildHeaderCell('Cantidad', flex: 1),
                _buildHeaderCell('Producto', flex: 2),
                _buildHeaderCell('Presentacion', flex: 2),
                _buildHeaderCell('Medida + Unidad de medida', flex: 2),
                _buildHeaderCell('Fecha vencimiento', flex: 2),
                _buildHeaderCell('Precio', flex: 1),
              ],
            ),
          ),
          // Rows
          if (productos.isEmpty)
            _buildEmptyState()
          else
            ...productos.map((producto) => _buildRow(producto)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay productos en la factura',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega productos usando el botón de abajo',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1D1B20),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(ProductoFactura producto) {
    return Row(
      children: [
        _buildCell(producto.cantidad.toString(), flex: 1),
        _buildCell(producto.nombre, flex: 2),
        _buildCell(producto.presentacion, flex: 2),
        _buildCell(producto.medida, flex: 2),
        _buildCell(producto.fechaVencimiento, flex: 2),
        _buildCell(producto.precio.toString(), flex: 1),
      ],
    );
  }

  Widget _buildCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFD9D9D9),
          border: Border.all(color: Colors.black),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
