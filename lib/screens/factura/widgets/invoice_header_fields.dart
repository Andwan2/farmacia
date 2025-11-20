import 'package:flutter/material.dart';

class InvoiceHeaderFields extends StatelessWidget {
  final String fecha;
  final String metodoPago;
  final String cliente;
  final String empleado;
  final String total;

  const InvoiceHeaderFields({
    super.key,
    required this.fecha,
    required this.metodoPago,
    required this.cliente,
    required this.empleado,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _HeaderField(
              label: 'FECHA',
              value: fecha,
              icon: Icons.calendar_today,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _HeaderField(
              label: 'MÉTODO DE PAGO',
              value: metodoPago,
              icon: Icons.credit_card,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _HeaderField(
              label: 'CLIENTE',
              value: cliente,
              icon: Icons.person,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _HeaderField(
              label: 'EMPLEADO',
              value: empleado,
              icon: Icons.person,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _HeaderField(
              label: 'TOTAL',
              value: total,
              icon: Icons.credit_card,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeaderField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: Color(0xFF49454F),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    color: Color(0xFF1D1B20),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Icon(
                icon,
                size: 20,
                color: const Color(0xFF1E1E1E),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
