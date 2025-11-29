import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:abari/providers/compra_provider.dart';
import 'package:abari/modal/seleccionar_empleado_modal.dart';
import 'package:abari/modal/agregar_producto_modal.dart';
import 'package:abari/modal/agregar_proveedor_modal.dart';

class ComprasScreen extends StatelessWidget {
  const ComprasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CompraProvider()
        ..cargarMetodosPago()
        ..cargarProveedores(),
      child: const _ComprasScreenContent(),
    );
  }
}

class _ComprasScreenContent extends StatelessWidget {
  const _ComprasScreenContent();

  void _agregarNuevoProducto(BuildContext context) {
    final provider = context.read<CompraProvider>();

    mostrarAgregarProducto(
      context,
      () {}, // onSuccess callback
      onProductoCreado: (productoCreado) {
        // Agregar el producto creado a la lista de compras
        provider.agregarProductoItem(
          ProductoCompraItem(
            idProductoBase: null, // Es un producto nuevo
            idPresentacion: productoCreado.idPresentacion,
            nombre: productoCreado.nombre,
            tipo: productoCreado.codigo,
            medida: productoCreado.cantidad.toString(),
            fechaVencimiento: '',
            precioCompra: productoCreado.precioCompra,
            precioVenta: productoCreado.precioVenta,
            cantidad: productoCreado.stock,
          ),
        );
      },
    );
  }

  Widget _buildPriceChip(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarLimpiar(
    BuildContext context,
    CompraProvider provider,
  ) async {
    // Si no hay productos, limpiar directamente
    if (provider.productos.isEmpty) {
      provider.limpiarCompra();
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning_amber, color: Colors.orange[700], size: 48),
        title: const Text('¿Limpiar compra?'),
        content: const Text(
          'Se eliminarán todos los productos agregados y se reiniciará el formulario. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      provider.limpiarCompra();
    }
  }

  Widget _buildResumenRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isLarge = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: isLarge ? 22 : 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isLarge ? 15 : 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 18 : 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatoFecha = DateFormat('dd/MM/yyyy');

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;
            final padding = isMobile ? 16.0 : 32.0;

            if (isMobile) {
              return _buildMobileLayout(context, formatoFecha, padding);
            }
            return _buildDesktopLayout(context, formatoFecha, padding);
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    DateFormat formatoFecha,
    double padding,
  ) {
    return Consumer<CompraProvider>(
      builder: (context, provider, child) {
        final errorValidacion = provider.validarCompra();
        final isValid = errorValidacion == null;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Compras',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Proveedor
              Row(
                children: [
                  Expanded(
                    child: Autocomplete<String>(
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return provider.proveedores.map(
                            (p) => p.nombreProveedor,
                          );
                        }
                        return provider.proveedores
                            .where(
                              (p) => p.nombreProveedor.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              ),
                            )
                            .map((p) => p.nombreProveedor);
                      },
                      onSelected: (value) => provider.setProveedor(value),
                      initialValue: TextEditingValue(text: provider.proveedor),
                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: 'Proveedor',
                                border: const OutlineInputBorder(),
                                isDense: true,
                                suffixIcon: controller.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          controller.clear();
                                          provider.setProveedor('');
                                        },
                                      )
                                    : null,
                              ),
                              onChanged: (value) {
                                // Actualizar proveedor si coincide exactamente
                                final match = provider.proveedores.where(
                                  (p) =>
                                      p.nombreProveedor.toLowerCase() ==
                                      value.toLowerCase(),
                                );
                                if (match.isNotEmpty) {
                                  provider.setProveedor(
                                    match.first.nombreProveedor,
                                  );
                                }
                              },
                            );
                          },
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Nuevo proveedor',
                    icon: const Icon(Icons.add_business),
                    onPressed: () {
                      mostrarAgregarProveedor(context, () {
                        context.read<CompraProvider>().cargarProveedores();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Método de pago
              DropdownButtonFormField<String>(
                value: provider.metodoPago.isEmpty ? null : provider.metodoPago,
                decoration: const InputDecoration(
                  labelText: 'Método de pago',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: provider.metodosPago
                    .map(
                      (m) => DropdownMenuItem<String>(
                        value: m.name,
                        child: Text(m.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) provider.setMetodoPago(value);
                },
              ),
              const SizedBox(height: 12),

              // Empleado y Fecha en fila
              Row(
                children: [
                  Expanded(
                    child: provider.empleado.isEmpty
                        ? OutlinedButton.icon(
                            onPressed: () {
                              mostrarSeleccionarEmpleado(context, (empleado) {
                                provider.setEmpleado(
                                  empleado.nombreEmpleado,
                                  empleadoId: empleado.idEmpleado,
                                );
                              });
                            },
                            icon: const Icon(Icons.badge, size: 18),
                            label: const Text(
                              'Empleado',
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : Chip(
                            avatar: const Icon(Icons.badge, size: 16),
                            label: Text(
                              provider.empleado,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onDeleted: () => provider.setEmpleado(''),
                            deleteIconColor: Colors.red,
                          ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: provider.fecha,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) provider.setFecha(picked);
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(formatoFecha.format(provider.fecha)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Lista de productos
              if (provider.productos.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No hay productos',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Agrega productos a la compra',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: provider.productos.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final subtotalCompra = item.precioCompra * item.cantidad;
                    final subtotalVenta = item.precioVenta * item.cantidad;
                    final ganancia = subtotalVenta - subtotalCompra;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${item.cantidad}x',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red[400],
                                    size: 22,
                                  ),
                                  onPressed: () => provider.eliminarProducto(index),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPriceChip(
                                    context,
                                    'Compra',
                                    'C\$${subtotalCompra.toStringAsFixed(2)}',
                                    Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildPriceChip(
                                    context,
                                    'Venta',
                                    'C\$${subtotalVenta.toStringAsFixed(2)}',
                                    Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildPriceChip(
                                    context,
                                    'Ganancia',
                                    'C\$${ganancia.toStringAsFixed(2)}',
                                    Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 12),

              // Botón de nuevo producto
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _agregarNuevoProducto(context),
                  icon: const Icon(Icons.add_box_outlined, size: 20),
                  label: const Text(
                    'Nuevo producto',
                    style: TextStyle(fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Resumen mejorado
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                      Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                    ],
                  ),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Resumen de compra',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildResumenRow(
                      context,
                      'Total invertido',
                      'C\$${provider.totalCosto.toStringAsFixed(2)}',
                      Icons.shopping_bag_outlined,
                      Colors.red,
                      isLarge: true,
                    ),
                    const SizedBox(height: 12),
                    _buildResumenRow(
                      context,
                      'Venta esperable',
                      'C\$${provider.totalVentaEsperable.toStringAsFixed(2)}',
                      Icons.sell_outlined,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildResumenRow(
                      context,
                      'Ganancia esperada',
                      'C\$${provider.gananciaEsperable.toStringAsFixed(2)}',
                      Icons.trending_up,
                      Colors.blue,
                    ),
                    if (!isValid && errorValidacion != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.red[400], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorValidacion,
                                style: TextStyle(
                                  color: Colors.red[400],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmarLimpiar(context, provider),
                      icon: const Icon(Icons.clear_all, size: 20),
                      label: const Text('Limpiar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: !isValid
                          ? null
                          : () => _guardarCompra(context, provider),
                      icon: const Icon(Icons.save, size: 20),
                      label: const Text(
                        'Guardar compra',
                        style: TextStyle(fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _guardarCompra(
    BuildContext context,
    CompraProvider provider,
  ) async {
    final error = await provider.guardarCompra();
    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red[700]),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡Compra guardada exitosamente!'),
          backgroundColor: Colors.green[700],
        ),
      );
      provider.limpiarCompra();
    }
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    DateFormat formatoFecha,
    double padding,
  ) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna izquierda: formulario principal
          Expanded(
            flex: 2,
            child: Consumer<CompraProvider>(
              builder: (context, provider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Compras',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Proveedor y método de pago
                    Row(
                      children: [
                        Expanded(
                          child: Autocomplete<String>(
                            optionsBuilder: (textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return provider.proveedores.map(
                                  (p) => p.nombreProveedor,
                                );
                              }
                              return provider.proveedores
                                  .where(
                                    (p) => p.nombreProveedor
                                        .toLowerCase()
                                        .contains(
                                          textEditingValue.text.toLowerCase(),
                                        ),
                                  )
                                  .map((p) => p.nombreProveedor);
                            },
                            onSelected: (value) => provider.setProveedor(value),
                            initialValue: TextEditingValue(
                              text: provider.proveedor,
                            ),
                            fieldViewBuilder:
                                (
                                  context,
                                  controller,
                                  focusNode,
                                  onFieldSubmitted,
                                ) {
                                  return TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: InputDecoration(
                                      labelText: 'Proveedor',
                                      border: const OutlineInputBorder(),
                                      suffixIcon: controller.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.clear,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                controller.clear();
                                                provider.setProveedor('');
                                              },
                                            )
                                          : null,
                                    ),
                                    onChanged: (value) {
                                      final match = provider.proveedores.where(
                                        (p) =>
                                            p.nombreProveedor.toLowerCase() ==
                                            value.toLowerCase(),
                                      );
                                      if (match.isNotEmpty) {
                                        provider.setProveedor(
                                          match.first.nombreProveedor,
                                        );
                                      }
                                    },
                                  );
                                },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Nuevo proveedor',
                          icon: const Icon(Icons.add_business),
                          onPressed: () {
                            mostrarAgregarProveedor(context, () {
                              context
                                  .read<CompraProvider>()
                                  .cargarProveedores();
                            });
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: provider.metodoPago.isEmpty
                                ? null
                                : provider.metodoPago,
                            decoration: const InputDecoration(
                              labelText: 'Método de pago',
                              border: OutlineInputBorder(),
                            ),
                            items: provider.metodosPago
                                .map(
                                  (m) => DropdownMenuItem<String>(
                                    value: m.name,
                                    child: Text(m.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                provider.setMetodoPago(value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Tabla sencilla de productos de compra
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade700),
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Producto',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Cant.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'P. Compra',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'P. Venta',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Vence',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 40),
                                ],
                              ),
                            ),
                            Expanded(
                              child: provider.productos.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No hay productos en la compra',
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: provider.productos.length,
                                      itemBuilder: (context, index) {
                                        final item = provider.productos[index];
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              top: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Text(item.nombre),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  item.cantidad.toString(),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  'C\$${item.precioCompra.toStringAsFixed(2)}',
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  'C\$${item.precioVenta.toStringAsFixed(2)}',
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  item.fechaVencimiento,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () {
                                                  provider.eliminarProducto(
                                                    index,
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _agregarNuevoProducto(context),
                        icon: const Icon(Icons.add_box_outlined),
                        label: const Text('Nuevo producto'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(width: 24),

          // Columna derecha: resumen y empleado/fecha
          SizedBox(
            width: 360,
            child: Consumer<CompraProvider>(
              builder: (context, provider, child) {
                final errorValidacion = provider.validarCompra();
                final isValid = errorValidacion == null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Resumen de compra',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Total invertido: C\$${provider.totalCosto.toStringAsFixed(2)}',
                            ),
                            Text(
                              'Venta esperable: C\$${provider.totalVentaEsperable.toStringAsFixed(2)}',
                            ),
                            Text(
                              'Ganancia esperable: C\$${provider.gananciaEsperable.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      provider.limpiarCompra();
                                    },
                                    child: const Text('Limpiar'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: !isValid
                                        ? null
                                        : () async {
                                            final error = await provider
                                                .guardarCompra();

                                            if (!context.mounted) return;

                                            if (error != null) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(error),
                                                  backgroundColor:
                                                      Colors.red[700],
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: const Text(
                                                    '¡Compra guardada exitosamente!',
                                                  ),
                                                  backgroundColor:
                                                      Colors.green[700],
                                                ),
                                              );
                                              provider.limpiarCompra();
                                            }
                                          },
                                    icon: const Icon(Icons.save),
                                    label: const Text('Guardar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (!isValid && provider.productos.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  errorValidacion!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Empleado',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            provider.empleado.isEmpty
                                ? OutlinedButton.icon(
                                    onPressed: () {
                                      mostrarSeleccionarEmpleado(context, (
                                        empleado,
                                      ) {
                                        provider.setEmpleado(
                                          empleado.nombreEmpleado,
                                          empleadoId: empleado.idEmpleado,
                                        );
                                      });
                                    },
                                    icon: const Icon(Icons.badge),
                                    label: const Text('Seleccionar empleado'),
                                  )
                                : Row(
                                    children: [
                                      const Icon(Icons.badge, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(provider.empleado)),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: () {
                                          provider.setEmpleado('');
                                        },
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fecha de compra',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: provider.fecha,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  provider.setFecha(picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 18),
                                    const SizedBox(width: 8),
                                    Text(formatoFecha.format(provider.fecha)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
