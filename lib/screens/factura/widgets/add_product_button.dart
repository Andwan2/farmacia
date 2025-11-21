import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farmacia_desktop/models/producto_db.dart';
import 'package:farmacia_desktop/providers/factura_provider.dart';
import 'producto_search_dialog.dart';

class AddProductButton extends StatelessWidget {
  final ValueChanged<ProductoDB>? onProductSelected;
  
  const AddProductButton({
    super.key,
    this.onProductSelected,
  });

  Future<void> _abrirDialogoBusqueda(BuildContext context) async {
    // Obtener los IDs de productos ya agregados a la factura
    final provider = context.read<FacturaProvider>();
    final idsYaAgregados = provider.productos
        .map((p) => p.idProducto)
        .toSet()
        .toList();
    
    final producto = await showDialog<ProductoDB>(
      context: context,
      builder: (context) => ProductoSearchDialog(
        idsYaAgregados: idsYaAgregados,
      ),
    );

    if (producto != null) {
      onProductSelected?.call(producto);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _abrirDialogoBusqueda(context),
      icon: const Icon(Icons.add_circle_outline, size: 24),
      label: const Text(
        'Agregar Producto',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }
}
