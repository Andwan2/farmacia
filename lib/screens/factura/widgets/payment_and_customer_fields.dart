import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:abari/providers/factura_provider.dart';

class PaymentAndCustomerFields extends StatefulWidget {
  const PaymentAndCustomerFields({super.key});

  @override
  State<PaymentAndCustomerFields> createState() =>
      _PaymentAndCustomerFieldsState();
}

class _PaymentAndCustomerFieldsState extends State<PaymentAndCustomerFields> {
  @override
  void initState() {
    super.initState();
    // Cargar métodos de pago y clientes al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('PaymentAndCustomerFields: Llamando cargarMetodosPago...');
      context.read<FacturaProvider>().cargarMetodosPago();
      print('PaymentAndCustomerFields: Llamando cargarClientes...');
      context.read<FacturaProvider>().cargarClientes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    
    return Consumer<FacturaProvider>(
      builder: (context, provider, child) {
        final metodoPagoField = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MÉTODO DE PAGO',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            provider.isLoadingMetodosPago
                ? _buildShimmerLoader()
                : provider.metodosPagoCargados &&
                      provider.metodosPago.isNotEmpty
                ? _buildAutocompleteConDatos(provider)
                : _buildAutocompleteFallback(provider),
          ],
        );

        final clienteField = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CLIENTE',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            provider.isLoadingClientes
                ? _buildShimmerLoader()
                : provider.clientesCargados &&
                      provider.clientes.isNotEmpty
                ? _buildAutocompleteClientesConDatos(provider)
                : _buildAutocompleteClientesFallback(provider),
          ],
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              metodoPagoField,
              const SizedBox(height: 16),
              clienteField,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: metodoPagoField),
            const SizedBox(width: 16),
            Expanded(child: clienteField),
          ],
        );
      },
    );
  }

  Widget _buildAutocompleteConDatos(FacturaProvider provider) {
    // Obtener todos los métodos de pago de la DB
    final opciones = provider.metodosPago.map((metodo) => metodo.name).toList();

    return Autocomplete<String>(
      key: ValueKey('metodo_pago_${provider.formKey}'),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return opciones;
        }
        return opciones.where((String option) {
          return option.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          );
        });
      },
      onSelected: (String selection) {
        provider.setMetodoPago(selection);
      },
      fieldViewBuilder:
          (
            BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.credit_card),
                hintText: 'Método de pago',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onSubmitted: (String value) {
                onFieldSubmitted();
              },
            );
          },
    );
  }

  Widget _buildAutocompleteFallback(FacturaProvider provider) {
    // Opciones por defecto si no hay conexión a BD
    const opciones = ['EFECTIVO', 'TARJETA', 'TRANSFERENCIA'];

    return Autocomplete<String>(
      key: ValueKey('metodo_pago_fallback_${provider.formKey}'),
      initialValue: TextEditingValue(text: provider.metodoPago),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return opciones;
        }
        return opciones.where((String option) {
          return option.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          );
        });
      },
      onSelected: (String selection) {
        provider.setMetodoPago(selection);
      },
      fieldViewBuilder:
          (
            BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.credit_card),
                hintText: 'Método de pago',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onSubmitted: (String value) {
                onFieldSubmitted();
              },
            );
          },
    );
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
      ),
    );
  }

  Widget _buildAutocompleteClientesConDatos(FacturaProvider provider) {
    // Obtener todos los clientes de la DB
    final opciones = provider.clientes
        .map((cliente) => cliente.nombreCliente)
        .toList();

    return Autocomplete<String>(
      key: ValueKey('cliente_${provider.formKey}'),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return opciones;
        }
        return opciones.where((String option) {
          return option.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          );
        });
      },
      onSelected: (String selection) {
        provider.setCliente(selection);
      },
      fieldViewBuilder:
          (
            BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person),
                hintText: 'Seleccionar cliente',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onSubmitted: (String value) {
                onFieldSubmitted();
              },
            );
          },
    );
  }

  Widget _buildAutocompleteClientesFallback(FacturaProvider provider) {
    // Opciones por defecto si no hay conexión a BD
    const opciones = ['Cliente General', 'Cliente Frecuente'];

    return Autocomplete<String>(
      key: ValueKey('cliente_fallback_${provider.formKey}'),
      initialValue: TextEditingValue(text: provider.cliente),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return opciones;
        }
        return opciones.where((String option) {
          return option.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          );
        });
      },
      onSelected: (String selection) {
        provider.setCliente(selection);
      },
      fieldViewBuilder:
          (
            BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person),
                hintText: 'Seleccionar cliente',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onSubmitted: (String value) {
                onFieldSubmitted();
              },
            );
          },
    );
  }
}
