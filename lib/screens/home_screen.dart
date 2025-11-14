import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Farmacia R')),
      drawer: const SideMenu(),
      body: const Center(child: Text('Selecciona una opción del menú')),
    );
  }
}

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  final Map<String, bool> expanded = {
    'Inventario': false,
    'Ventas': false,
    'Compras': false,
    'Proveedores': false,
    'Clientes': false,
    'Empleados': false,
    'Reportes': false,
  };

  void toggle(String key) {
    setState(() {
      expanded[key] = !(expanded[key] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          const DrawerHeader(child: Text('Menú Principal')),
          buildSection('Inventario', [
            ('Ver inventario', '/inventario'),
          ]),
          buildSection('Ventas', [
            ('Nueva venta', '/venta'),
          ]),
          buildSection('Compras', [
            ('Nueva compra', '/compra'),
          ]),
          buildSection('Proveedores', [
            ('Registrar proveedor', '/proveedores'),
          ]),
          buildSection('Clientes', [
            ('Registrar cliente', '/clientes'),
          ]),
          buildSection('Empleados', [
            ('Empleados', '/empleados'),
          ]),
          buildSection('Reportes', [
            ('Reporte de venta', '/reporteVenta'),
            ('Reporte de compras', '/reporteCompra'),
          ]),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.pop(context); // Cierra el Drawer
              context.go('/login');   // Redirige al login
            },
          ),
        ],
      ),
    );
  }

  Widget buildSection(String title, List<(String, String)> items) {
    final isOpen = expanded[title] ?? false;
    return ExpansionTile(
      
      title: Text(title),
      initiallyExpanded: isOpen,
      onExpansionChanged: (_) => toggle(title),
      children: items.map((item) {
        final (label, route) = item;
        return ListTile(
          title: Text(label),
          onTap: () {
            Navigator.pop(context); // Cierra el Drawer
            context.push(route);      // Navega a la ruta    
          },
        );
      }).toList(),
    );
  }
}
