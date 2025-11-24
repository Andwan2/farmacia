import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:abari/models/producto_db.dart';
import 'package:abari/providers/compra_provider.dart';
import 'package:abari/screens/factura/widgets/producto_search_dialog.dart';
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

  Future<void> _agregarProductoDialog(BuildContext context) async {
    final provider = context.read<CompraProvider>();

    // Primero seleccionar un producto existente
    final producto = await showDialog<ProductoDB>(
      context: context,
      builder: (context) => const ProductoSearchDialog(),
    );

    if (producto == null) return;

    final cantidadController = TextEditingController(text: '1');
    final precioCompraController = TextEditingController(
      text: (producto.precioCompra ?? 0.0).toStringAsFixed(2),
    );
    final precioVentaController = TextEditingController(
      text: (producto.precioVenta ?? 0.0).toStringAsFixed(2),
    );

    DateTime fechaVenc =
        DateTime.tryParse(producto.fechaVencimiento) ?? DateTime.now();
    final formatoFecha = DateFormat('dd/MM/yyyy');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Agregar producto a la compra'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      producto.nombreProducto,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cantidadController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: precioCompraController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Precio de compra (por unidad)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: precioVentaController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Precio de venta (por unidad)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Fecha de vencimiento',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: fechaVenc,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            fechaVenc = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18),
                            const SizedBox(width: 8),
                            Text(formatoFecha.format(fechaVenc)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    final cantidad = int.tryParse(cantidadController.text) ?? 0;
    final precioCompra =
        double.tryParse(precioCompraController.text.replaceAll(',', '.')) ??
        0.0;
    final precioVenta =
        double.tryParse(precioVentaController.text.replaceAll(',', '.')) ?? 0.0;

    if (cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La cantidad debe ser mayor a 0.')),
      );
      return;
    }

    provider.agregarProductoItem(
      ProductoCompraItem.fromProductoDB(
        producto,
        cantidad: cantidad,
        precioCompra: precioCompra,
        precioVenta: precioVenta,
      ).copyWith(fechaVencimiento: fechaVenc.toIso8601String().split('T')[0]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatoFecha = DateFormat('dd/MM/yyyy');

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                              child: DropdownButtonFormField<String>(
                                value: provider.proveedor.isEmpty
                                    ? null
                                    : provider.proveedor,
                                decoration: const InputDecoration(
                                  labelText: 'Proveedor',
                                  border: OutlineInputBorder(),
                                ),
                                items: provider.proveedores
                                    .map(
                                      (p) => DropdownMenuItem<String>(
                                        value: p.nombreProveedor,
                                        child: Text(p.nombreProveedor),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    provider.setProveedor(value);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Nuevo proveedor',
                              icon: const Icon(Icons.add_business),
                              onPressed: () {
                                mostrarAgregarProveedor(context, () {
                                  final compraProvider = context
                                      .read<CompraProvider>();
                                  compraProvider.cargarProveedores();
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
                                            final item =
                                                provider.productos[index];
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
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

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _agregarProductoDialog(context),
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text('Agregar producto a compra'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  mostrarAgregarProducto(context, () {
                                    // Después de crear productos, no hace
                                    // falta recargar nada específico aquí.
                                  });
                                },
                                icon: const Icon(Icons.add_box_outlined),
                                label: const Text('Nuevo producto'),
                              ),
                            ),
                          ],
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
                                        label: const Text(
                                          'Seleccionar empleado',
                                        ),
                                      )
                                    : Row(
                                        children: [
                                          const Icon(Icons.badge, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(provider.empleado),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              size: 18,
                                            ),
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
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          formatoFecha.format(provider.fecha),
                                        ),
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
        ),
      ),
    );
  }
}
