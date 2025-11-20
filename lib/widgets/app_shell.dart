import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shell que contiene el AppBar y Drawer persistentes
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de inventario de farmacia André'),
      ),
      drawer: const AppDrawer(),
      body: child,
    );
  }
}

/// Drawer de navegación principal
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          const DrawerHeader(
            child: Text('Menú Principal', style: TextStyle(fontSize: 18)),
          ),

          _buildSection("Inventario", [
            ('Productos', '/productos', Icons.inventory),
          ], context),

          const Divider(),

          _buildSection("Recursos humanos", [
            ('Proveedores', '/proveedores', Icons.corporate_fare),
            ('Clientes', '/clientes', Icons.verified_user),
          ], context),

          const Divider(),

          _buildSection("Transacciones", [
            ('Ventas', '/ventas', Icons.point_of_sale),
            ('Compras', '/compras', Icons.attach_money),
          ], context),

          const Divider(),

          _buildSection("Info", [('Acerca de', '/about', Icons.info)], context),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pop(context);
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<(String, String, IconData?)> items,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),

        ...items.map((item) {
          final (label, route, icon) = item;

          return ListTile(
            leading: icon != null ? Icon(icon) : null,
            title: Text(label),
            onTap: () {
              Navigator.pop(context);
              context.go(route);
            },
          );
        }),
      ],
    );
  }
}
