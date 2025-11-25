import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:abari/providers/factura_provider.dart';
import 'package:intl/intl.dart';
import 'widgets/add_product_button.dart';
import 'widgets/payment_and_customer_fields.dart';
import 'widgets/invoice_table.dart';
import 'widgets/sale_summary.dart';
import 'package:abari/modal/seleccionar_empleado_modal.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final padding = isMobile ? 16.0 : 64.0;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: isMobile 
            ? _buildMobileLayout(context)
            : _buildDesktopLayout(context),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        const Text(
          'Ventas',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.64,
          ),
        ),

        const SizedBox(height: 16),

        // Campos de método de pago y cliente
        const PaymentAndCustomerFields(),
        const SizedBox(height: 16),

        // Tabla de productos
        _buildProductosTable(context),

        const SizedBox(height: 16),

        // Botón agregar producto
        AddProductButton(
          onProductSelected: (producto) {
            final provider = context.read<FacturaProvider>();
            provider.agregarProducto(producto);
          },
        ),

        const SizedBox(height: 24),

        // Resumen de venta
        _buildSaleSummary(context),

        const SizedBox(height: 16),

        // Campo de empleado y fecha
        _buildEmpleadoYFecha(context),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contenido izquierdo (formulario de factura)
        Expanded(
          flex: 2,
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
                  height: 1.2,
                  letterSpacing: -0.96,
                ),
              ),

              const SizedBox(height: 24),

              // Campos de método de pago y cliente
              const PaymentAndCustomerFields(),
              const SizedBox(height: 16),

              // Tabla de productos
              _buildProductosTable(context),

              const SizedBox(height: 24),

              // Botón agregar producto
              AddProductButton(
                onProductSelected: (producto) {
                  final provider = context.read<FacturaProvider>();
                  provider.agregarProducto(producto);
                },
              ),
            ],
          ),
        ),

        const SizedBox(width: 32),

        // Columna derecha (resumen y empleado)
        Column(
          children: [
            _buildSaleSummary(context),
            const SizedBox(height: 24),
            _buildEmpleadoYFecha(context),
          ],
        ),
      ],
    );
  }

  Widget _buildProductosTable(BuildContext context) {
    return Consumer<FacturaProvider>(
      builder: (context, provider, child) {
        // Agrupar productos por tipo
        final Map<String, List<ProductoFactura>> productosPorTipo = {};
        for (var producto in provider.productos) {
          if (!productosPorTipo.containsKey(producto.presentacion)) {
            productosPorTipo[producto.presentacion] = [];
          }
          productosPorTipo[producto.presentacion]!.add(producto);
        }

        // Crear lista agrupada con cantidad total por tipo
        final productosAgrupados = productosPorTipo.entries.map((entry) {
          final tipo = entry.key;
          final productos = entry.value;
          final cantidadTotal = productos.length;
          final primerProducto = productos.first;

          return ProductoFactura(
            idProducto: primerProducto.idProducto,
            cantidad: cantidadTotal,
            nombre: primerProducto.nombre,
            presentacion: tipo,
            medida: primerProducto.medida,
            fechaVencimiento: primerProducto.fechaVencimiento,
            precio: primerProducto.precio,
          );
        }).toList();

        return InvoiceTable(
          productos: productosAgrupados,
          onDelete: (index) {
            final productoAEliminar = productosAgrupados[index];
            final tipoAEliminar = productoAEliminar.presentacion;
            final indexEnOriginal = provider.productos
                .indexWhere((p) => p.presentacion == tipoAEliminar);
            if (indexEnOriginal != -1) {
              provider.eliminarProducto(indexEnOriginal);
            }
          },
        );
      },
    );
  }

  Widget _buildSaleSummary(BuildContext context) {
    return Consumer<FacturaProvider>(
      builder: (context, provider, child) {
        final isValid = provider.validarFactura() == null;

        return SaleSummary(
          isValid: isValid,
          onReset: () => provider.limpiarFactura(),
          onConfirm: () async {
            final errorValidacion = provider.validarFactura();

            if (errorValidacion != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          errorValidacion,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red[700],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 4),
                ),
              );
              return;
            }

            final error = await provider.guardarVenta();

            if (error != null) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(child: Text(error)),
                      ],
                    ),
                    backgroundColor: Colors.red[700],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            } else {
              provider.limpiarFactura();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(child: Text('¡Venta guardada exitosamente!')),
                      ],
                    ),
                    backgroundColor: Colors.green[700],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  Widget _buildEmpleadoYFecha(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    
    return Consumer<FacturaProvider>(
      builder: (context, provider, child) {
        final formatoFecha = DateFormat('dd/MM/yyyy');

        return Container(
          width: isMobile ? double.infinity : 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EMPLEADO',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              provider.empleado.isEmpty
                  ? OutlinedButton.icon(
                      onPressed: () {
                        mostrarSeleccionarEmpleado(context, (empleado) {
                          provider.setEmpleado(
                            empleado.nombreEmpleado,
                            empleadoId: empleado.idEmpleado,
                          );
                        });
                      },
                      icon: const Icon(Icons.badge),
                      label: const Text('Seleccionar empleado'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                  : Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.badge, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              provider.empleado,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => provider.setEmpleado(''),
                            tooltip: 'Quitar empleado',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () {
                              mostrarSeleccionarEmpleado(context, (empleado) {
                                provider.setEmpleado(
                                  empleado.nombreEmpleado,
                                  empleadoId: empleado.idEmpleado,
                                );
                              });
                            },
                            tooltip: 'Cambiar empleado',
                          ),
                        ],
                      ),
                    ),
              const SizedBox(height: 24),
              Text(
                'FECHA',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
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
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 16),
                      Text(
                        formatoFecha.format(provider.fecha),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
