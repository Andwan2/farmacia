import 'package:flutter/material.dart';

class ProductoFactura {
  final int idProducto;
  final int cantidad;
  final String nombre;
  final String presentacion;
  final String medida;
  final String fechaVencimiento;
  final double precio;

  ProductoFactura({
    required this.idProducto,
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildHeaderCell(context, 'Cant.', flex: 1),
                _buildHeaderCell(context, 'Producto', flex: 2),
                _buildHeaderCell(context, 'Presentación', flex: 2),
                _buildHeaderCell(context, 'Medida', flex: 1),
                _buildHeaderCell(context, 'Vencimiento', flex: 2),
                _buildHeaderCell(context, 'Precio Ind.', flex: 2),
              ],
            ),
          ),
          // Rows
          if (productos.isEmpty)
            _buildEmptyState(context)
          else
            ...productos.asMap().entries.map((entry) {
              final index = entry.key;
              final producto = entry.value;
              final isEven = index % 2 == 0;
              return _buildRow(context, producto, isEven);
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 64,
            color: colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay productos en la factura',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega productos usando el botón de abajo',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, String text, {int flex = 1}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(
          text,
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, ProductoFactura producto, bool isEven) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: isEven 
          ? colorScheme.surfaceContainerLow
          : colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildCell(context, producto.cantidad.toString(), flex: 1),
          _buildCell(context, producto.nombre, flex: 2),
          _buildCell(context, producto.presentacion, flex: 2),
          _buildCell(context, producto.medida, flex: 1),
          _buildCell(context, producto.fechaVencimiento, flex: 2),
          _buildCell(context, 'C\$${producto.precio.toStringAsFixed(2)}', flex: 2, isMoney: true),
        ],
      ),
    );
  }

  Widget _buildCell(BuildContext context, String text, {int flex = 1, bool isMoney = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Text(
          text,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: isMoney ? FontWeight.w600 : FontWeight.w400,
            color: isMoney ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
