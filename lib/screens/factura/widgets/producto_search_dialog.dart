import 'package:flutter/material.dart';
import 'package:abari/models/producto_db.dart';
import 'package:abari/services/producto_service.dart';
import 'package:abari/core/utils/debouncer.dart';

class ProductoSearchDialog extends StatefulWidget {
  final List<int> idsYaAgregados;

  const ProductoSearchDialog({super.key, this.idsYaAgregados = const []});

  @override
  State<ProductoSearchDialog> createState() => _ProductoSearchDialogState();
}

class _ProductoSearchDialogState extends State<ProductoSearchDialog> {
  final _controller = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));
  final _productoService = ProductoService();

  List<ProductoDB> _resultados = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _buscarProductos(String query) {
    if (query.isEmpty) {
      setState(() {
        _resultados = [];
      });
      return;
    }

    _debouncer.run(() async {
      setState(() => _isSearching = true);

      final productos = await _productoService.buscarProductos(query);

      // Filtrar productos cuyo ID ya esté agregado a la factura
      final productosFiltrados = productos.where((producto) {
        return !widget.idsYaAgregados.contains(producto.idProducto);
      }).toList();

      setState(() {
        _resultados = productosFiltrados;
        _isSearching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Row(
              children: [
                const Text(
                  'Buscar Producto',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Campo de búsqueda
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _buscarProductos,
              decoration: InputDecoration(
                hintText: 'Escribe el nombre del producto...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Resultados
            Expanded(child: _buildResultados()),
          ],
        ),
      ),
    );
  }

  Widget _buildResultados() {
    if (_controller.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Escribe para buscar productos',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_resultados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No se encontraron productos',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _resultados.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final producto = _resultados[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Icon(Icons.medication, color: Colors.blue[700]),
          ),
          title: Text(
            producto.nombreProducto,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${producto.tipo} • ${producto.medida}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                'Vence: ${producto.fechaVencimiento}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: producto.precioVenta != null
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'C\$${producto.precioVenta!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.green[800],
                    ),
                  ),
                )
              : null,
          onTap: () => Navigator.pop(context, producto),
        );
      },
    );
  }
}
