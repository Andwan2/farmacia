import 'package:flutter/material.dart';
import 'package:abari/models/producto_db.dart';
import 'package:abari/services/producto_service.dart';
import 'package:abari/core/utils/debouncer.dart';

/// Resultado del diálogo: producto seleccionado, cantidad y stock total
class ProductoSeleccionado {
  final ProductoDB producto;
  final int cantidad;
  final int stockTotal;

  ProductoSeleccionado({
    required this.producto,
    required this.cantidad,
    required this.stockTotal,
  });
}

class ProductoSearchDialog extends StatefulWidget {
  /// Mapa de código -> cantidad ya agregada al carrito
  final Map<String, int> cantidadesEnCarrito;

  const ProductoSearchDialog({super.key, this.cantidadesEnCarrito = const {}});

  @override
  State<ProductoSearchDialog> createState() => _ProductoSearchDialogState();
}

class _ProductoSearchDialogState extends State<ProductoSearchDialog> {
  final _controller = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));
  final _productoService = ProductoService();

  List<ProductoAgrupado> _resultados = [];
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

      final productosAgrupados = await _productoService
          .buscarProductosAgrupados(query);

      setState(() {
        _resultados = productosAgrupados;
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
        final grupo = _resultados[index];
        // Calcular stock disponible (total - ya en carrito)
        final enCarrito = widget.cantidadesEnCarrito[grupo.codigo] ?? 0;
        final stockDisponible = grupo.stock - enCarrito;

        // Si no hay stock disponible, mostrar deshabilitado
        if (stockDisponible <= 0) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: Icon(Icons.medication, color: Colors.grey[400]),
            ),
            title: Text(
              grupo.nombreProducto,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  grupo.codigo,
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    'En carrito: $enCarrito (sin stock adicional)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Icon(Icons.medication, color: Colors.blue[700]),
          ),
          title: Text(
            grupo.nombreProducto,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(grupo.codigo, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: stockDisponible > 5
                          ? Colors.green[50]
                          : const Color.fromARGB(255, 250, 249, 249),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: stockDisponible > 5
                            ? Colors.green[300]!
                            : const Color.fromARGB(255, 237, 146, 20)!,
                      ),
                    ),
                    child: Text(
                      'Disponible: $stockDisponible',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: stockDisponible > 5
                            ? Colors.green[700]
                            : const Color.fromARGB(255, 245, 0, 0),
                      ),
                    ),
                  ),
                  if (enCarrito > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue[300]!),
                      ),
                      child: Text(
                        'En carrito: $enCarrito',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: grupo.precioVenta != null
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
                    'C\$${grupo.precioVenta!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.green[800],
                    ),
                  ),
                )
              : null,
          onTap: () =>
              _mostrarSelectorCantidad(context, grupo, stockDisponible),
        );
      },
    );
  }

  void _mostrarSelectorCantidad(
    BuildContext context,
    ProductoAgrupado grupo,
    int stockDisponible,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    int cantidadSeleccionada = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
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
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Título del producto
                  Text(
                    grupo.nombreProducto,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    grupo.codigo,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info de stock y precio
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: stockDisponible > 5
                              ? Colors.green.withOpacity(0.1)
                              : const Color.fromARGB(
                                  255,
                                  255,
                                  251,
                                  0,
                                ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: stockDisponible > 5
                                ? Colors.green
                                : const Color.fromARGB(255, 255, 0, 0),
                          ),
                        ),
                        child: Text(
                          'Disponible: $stockDisponible unidades',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: stockDisponible > 5
                                ? Colors.green[700]
                                : const Color.fromARGB(255, 249, 6, 6),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (grupo.precioVenta != null)
                        Text(
                          'C\$${grupo.precioVenta!.toStringAsFixed(2)} c/u',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Selector de cantidad
                  Text(
                    'Cantidad a agregar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Botón decrementar
                      IconButton.filled(
                        onPressed: cantidadSeleccionada > 1
                            ? () => setModalState(() => cantidadSeleccionada--)
                            : null,
                        icon: const Icon(Icons.remove),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          foregroundColor: colorScheme.onSurface,
                          disabledBackgroundColor:
                              colorScheme.surfaceContainerLow,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Campo de cantidad
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.outline),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$cantidadSeleccionada',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Botón incrementar
                      IconButton.filled(
                        onPressed: cantidadSeleccionada < stockDisponible
                            ? () => setModalState(() => cantidadSeleccionada++)
                            : null,
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          disabledBackgroundColor:
                              colorScheme.surfaceContainerLow,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Subtotal
                  if (grupo.precioVenta != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Subtotal: C\$${(grupo.precioVenta! * cantidadSeleccionada).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Botón agregar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: grupo.primerProducto != null
                          ? () {
                              Navigator.pop(
                                bottomContext,
                              ); // Cerrar bottom sheet
                              Navigator.pop(
                                this.context,
                                ProductoSeleccionado(
                                  producto: grupo.primerProducto!,
                                  cantidad: cantidadSeleccionada,
                                  stockTotal: grupo.stock,
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(
                        'Agregar $cantidadSeleccionada ${cantidadSeleccionada == 1 ? 'unidad' : 'unidades'}',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
