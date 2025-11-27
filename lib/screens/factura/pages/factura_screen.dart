import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:abari/providers/factura_provider.dart';
import 'package:intl/intl.dart';
import '../widgets/add_product_button.dart';
import '../widgets/payment_and_customer_fields.dart';
import '../widgets/invoice_table.dart';
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

class _FacturaScreenContent extends StatefulWidget {
  const _FacturaScreenContent();

  @override
  State<_FacturaScreenContent> createState() => _FacturaScreenContentState();
}

class _FacturaScreenContentState extends State<_FacturaScreenContent> {
  late PageController _pageController;
  int _currentStep = 0;
  static const int _totalSteps = 3;

  final List<String> _stepTitles = [
    'Productos',
    'Datos de Pago',
    'Confirmación',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_currentStep > 0) {
      // Si está en un paso mayor a 0, preguntar si quiere retroceder
      final shouldGoBack = await _showExitConfirmationDialog();
      if (shouldGoBack == true) {
        _goToPreviousStep();
      }
      return false;
    } else {
      // Si está en el primer paso, preguntar si quiere salir
      final shouldExit = await _showExitConfirmationDialog(isExiting: true);
      return shouldExit ?? false;
    }
  }

  Future<bool?> _showExitConfirmationDialog({bool isExiting = false}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isExiting ? '¿Salir de la venta?' : '¿Volver al paso anterior?'),
        content: Text(
          isExiting
              ? 'Si sales ahora, perderás todos los datos ingresados.'
              : '¿Estás seguro de que deseas volver al paso anterior?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: isExiting ? Colors.red : null,
            ),
            child: Text(isExiting ? 'Salir' : 'Volver'),
          ),
        ],
      ),
    );
  }

  void _goToNextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Barra de progreso
              _buildProgressBar(context, isMobile),
              // Contenido del PageView
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  children: [
                    _buildStep1Products(context, isMobile),
                    _buildStep2PaymentData(context, isMobile),
                    _buildStep3Confirmation(context, isMobile),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, bool isMobile) {
    final progress = (_currentStep + 1) / _totalSteps;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 64,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Indicador de paso actual
          Text(
            '${_currentStep + 1}/$_totalSteps',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 16),
          // Barra de progreso
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Botón de cerrar
          IconButton(
            onPressed: () async {
              final shouldExit =
                  await _showExitConfirmationDialog(isExiting: true);
              if (shouldExit == true && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.close, size: 28),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Products(BuildContext context, bool isMobile) {
    final padding = isMobile ? 16.0 : 64.0;

    return Column(
      children: [
        // Contenido scrollable
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _stepTitles[0],
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isMobile ? 28 : 36,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.64,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Agrega los productos que deseas vender',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // Tabla de productos
                _buildProductosTable(context),
                const SizedBox(height: 24),

                // Botón agregar producto
                Consumer<FacturaProvider>(
                  builder: (context, provider, child) {
                    return AddProductButton(
                      cantidadesEnCarrito: provider.cantidadesPorCodigo,
                      onProductSelected: (producto, cantidad, stockTotal) {
                        provider.agregarProducto(
                          producto,
                          cantidad: cantidad,
                          stockMaximo: stockTotal,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        // Botones fijos en la parte inferior
        _buildBottomNavigationBar(
          context,
          isMobile: isMobile,
          showBack: false,
          onNext: () {
            final provider = context.read<FacturaProvider>();
            if (provider.productos.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Agrega al menos un producto'),
                    ],
                  ),
                  backgroundColor: Colors.orange[700],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
              return;
            }
            _goToNextStep();
          },
        ),
      ],
    );
  }

  Widget _buildStep2PaymentData(BuildContext context, bool isMobile) {
    final padding = isMobile ? 16.0 : 64.0;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _stepTitles[1],
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isMobile ? 28 : 36,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.64,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresa los datos del cliente y método de pago',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // Campos de método de pago y cliente
                const PaymentAndCustomerFields(),
                const SizedBox(height: 24),

                // Campo de empleado y fecha
                _buildEmpleadoYFecha(context),
              ],
            ),
          ),
        ),
        _buildBottomNavigationBar(
          context,
          isMobile: isMobile,
          showBack: true,
          onBack: () async {
            final shouldGoBack = await _showExitConfirmationDialog();
            if (shouldGoBack == true) {
              _goToPreviousStep();
            }
          },
          onNext: _goToNextStep,
        ),
      ],
    );
  }

  Widget _buildStep3Confirmation(BuildContext context, bool isMobile) {
    final padding = isMobile ? 16.0 : 64.0;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _stepTitles[2],
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isMobile ? 28 : 36,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.64,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Revisa los detalles de la venta antes de confirmar',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Resumen de productos (solo lectura)
                _buildProductosSummary(context),
                const SizedBox(height: 24),

                // Resumen de venta
                _buildSaleSummary(context),
              ],
            ),
          ),
        ),
        _buildBottomNavigationBar(
          context,
          isMobile: isMobile,
          showBack: true,
          onBack: () async {
            final shouldGoBack = await _showExitConfirmationDialog();
            if (shouldGoBack == true) {
              _goToPreviousStep();
            }
          },
          isLastStep: true,
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(
    BuildContext context, {
    required bool isMobile,
    required bool showBack,
    VoidCallback? onBack,
    VoidCallback? onNext,
    bool isLastStep = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 64,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (showBack) ...[
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Anterior'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: isLastStep
                  ? _buildConfirmButton(context)
                  : FilledButton.icon(
                      onPressed: onNext,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Continuar'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return Consumer<FacturaProvider>(
      builder: (context, provider, child) {
        return FilledButton.icon(
          onPressed: () async {
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
                Navigator.of(context).pop();
              }
            }
          },
          icon: const Icon(Icons.check),
          label: const Text('Confirmar Venta'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green[600],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductosSummary(BuildContext context) {
    return Consumer<FacturaProvider>(
      builder: (context, provider, child) {
        if (provider.productos.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Productos (${provider.productos.length})',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.productos.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final producto = provider.productos[index];
                  return ListTile(
                    title: Text(
                      producto.presentacion,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text('Cantidad: ${producto.cantidad}'),
                    trailing: Text(
                      'C\$${(producto.precio * producto.cantidad).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductosTable(BuildContext context) {
    return Consumer<FacturaProvider>(
      builder: (context, provider, child) {
        return InvoiceTable(
          productos: provider.productos,
          onCantidadChanged: (index, nuevaCantidad) {
            final producto = provider.productos[index];
            provider.actualizarCantidadPorCodigo(
              producto.presentacion,
              nuevaCantidad,
            );
          },
        );
      },
    );
  }

  Widget _buildSaleSummary(BuildContext context) {
    return Consumer<FacturaProvider>(
      builder: (context, provider, child) {
        final subtotal = provider.total;
        final cantidadTotal = provider.productos.fold<int>(
          0,
          (sum, producto) => sum + producto.cantidad,
        );
        final textTheme = Theme.of(context).textTheme;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Resumen de Venta',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      context,
                      'Productos:',
                      '${provider.productos.length} tipos',
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      context,
                      'Cantidad Total:',
                      '$cantidadTotal unidades',
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      context,
                      'Método de Pago:',
                      provider.metodoPago.isEmpty
                          ? 'No especificado'
                          : provider.metodoPago,
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      context,
                      'Cliente:',
                      provider.cliente.isEmpty
                          ? 'No especificado'
                          : provider.cliente,
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      context,
                      'Empleado:',
                      provider.empleado.isEmpty
                          ? 'No especificado'
                          : provider.empleado,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL:',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'C\$${subtotal.toStringAsFixed(2)}',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyLarge?.copyWith(
            color: color,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
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
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
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
