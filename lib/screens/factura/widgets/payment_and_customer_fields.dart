import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farmacia_desktop/providers/factura_provider.dart';

class PaymentAndCustomerFields extends StatelessWidget {
  const PaymentAndCustomerFields({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FacturaProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            // Método de pago
            Expanded(
              child: Column(
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
                  DropdownButtonFormField<String>(
                    value: provider.metodoPago,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.credit_card),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'EFECTIVO',
                        child: Text('Efectivo'),
                      ),
                      DropdownMenuItem(
                        value: 'TARJETA',
                        child: Text('Tarjeta'),
                      ),
                      DropdownMenuItem(
                        value: 'TRANSFERENCIA',
                        child: Text('Transferencia'),
                      ),
                    ],
                    onChanged: (valor) => provider.setMetodoPago(valor ?? 'EFECTIVO'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Cliente
            Expanded(
              child: Column(
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
                  DropdownButtonFormField<String>(
                    initialValue: provider.cliente.isEmpty ? null : provider.cliente,
                    decoration: InputDecoration(
                      hintText: 'Seleccionar cliente',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'nuevo',
                        child: Text('+ Crear nuevo cliente'),
                      ),
                      DropdownMenuItem(
                        value: 'Cliente 1',
                        child: Text('Cliente 1'),
                      ),
                      DropdownMenuItem(
                        value: 'Cliente 2',
                        child: Text('Cliente 2'),
                      ),
                      DropdownMenuItem(
                        value: 'Cliente 3',
                        child: Text('Cliente 3'),
                      ),
                    ],
                    onChanged: (valor) {
                      if (valor == 'nuevo') {
                        _mostrarDialogNuevoCliente(context);
                      } else {
                        provider.setCliente(valor ?? '');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogNuevoCliente(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Color(0xFF16A34A), size: 28),
              SizedBox(width: 12),
              Text(
                'Nuevo Cliente',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Nombre del cliente',
                  hintText: 'Ingrese el nombre completo',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final nombre = controller.text.trim();
                if (nombre.isNotEmpty) {
                  Navigator.of(dialogContext).pop();
                  // Usar el contexto original para acceder al provider
                  context.read<FacturaProvider>().setCliente(nombre);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
