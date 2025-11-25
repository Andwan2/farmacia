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
  final Function(int)? onDelete;

  const InvoiceTable({
    super.key,
    required this.productos,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    
    if (isMobile) {
      return _buildMobileView(context);
    }
    return _buildDesktopView(context);
  }

  Widget _buildMobileView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (productos.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: productos.asMap().entries.map((entry) {
        final index = entry.key;
        final producto = entry.value;
        return GestureDetector(
          onTap: () => _showProductoDetails(context, producto),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                // Info principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${producto.cantidad} x C\$${producto.precio.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Icono de ver más
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 8),
                // Botón eliminar
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  onPressed: onDelete != null ? () => onDelete!(index) : null,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showProductoDetails(BuildContext context, ProductoFactura producto) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Título
                Text(
                  producto.nombre,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Detalles
                _buildDetailRow('Cantidad', producto.cantidad.toString()),
                _buildDetailRow('Presentación', producto.presentacion),
                _buildDetailRow('Medida', producto.medida),
                _buildDetailRow('Vencimiento', producto.fechaVencimiento),
                _buildDetailRow(
                  'Precio Unitario',
                  'C\$${producto.precio.toStringAsFixed(2)}',
                  isPrimary: true,
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  'Subtotal',
                  'C\$${(producto.precio * producto.cantidad).toStringAsFixed(2)}',
                  isPrimary: true,
                  isLarge: true,
                ),
                
                const SizedBox(height: 16),
                
                // Botón cerrar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isPrimary = false, bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isLarge ? 16 : 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isLarge ? 20 : 16,
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
              color: isPrimary ? Colors.blue : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopView(BuildContext context) {
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
                _buildHeaderCell(context, 'Medida', flex: 2),
                _buildHeaderCell(context, 'Vencimiento', flex: 2),
                _buildHeaderCell(context, 'Precio Ind.', flex: 2),
                _buildHeaderCell(context, 'Acciones', flex: 2),
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
              return _buildRow(context, producto, index.isEven, index);
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

  Widget _buildRow(BuildContext context, ProductoFactura producto, bool isEven, int index) {
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
          _buildCell(context, producto.medida, flex: 2),
          _buildCell(context, producto.fechaVencimiento, flex: 2),
          _buildCell(context, 'C\$${producto.precio.toStringAsFixed(2)}', flex: 2, isMoney: true),
          _buildActionCell(context, index),
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

  Widget _buildActionCell(BuildContext context, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Center(
          child: IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: colorScheme.error,
            ),
            onPressed: onDelete != null ? () => onDelete!(index) : null,
            tooltip: 'Eliminar producto',
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
            ),
          ),
        ),
      ),
    );
  }
}
