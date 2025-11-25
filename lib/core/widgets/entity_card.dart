import 'package:flutter/material.dart';

/// Widget card reutilizable para mostrar entidades (empleados, clientes, proveedores, etc.)
class EntityCard extends StatelessWidget {
  /// Nombre principal de la entidad
  final String nombre;
  
  /// Icono a mostrar en el avatar
  final IconData icon;
  
  /// Lista de subtítulos opcionales (ej: teléfono, cargo, RUC)
  final List<String> subtitulos;
  
  /// Callback cuando se presiona el botón de editar
  final VoidCallback onEdit;

  const EntityCard({
    super.key,
    required this.nombre,
    required this.icon,
    this.subtitulos = const [],
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Stack(
        children: [
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(child: Icon(icon)),
                const SizedBox(height: 8),
                Text(
                  nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                ...subtitulos.map(
                  (subtitulo) => Text(
                    subtitulo,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
