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
            MenuItem(label: 'Ver inventario', route: '/inventario/ver'),
            MenuItem(label: 'Agregar productos', route: '/inventario/agregar'),
            MenuItem(label: 'Actualizar stock', route: '/inventario/actualizar'),
          ]),
          buildSection('Ventas', [
            MenuItem(label: 'Movimientos de venta', route: '/ventas/movimientos'),
            MenuItem(label: 'Nueva venta', route: '/ventas/nueva'),
          ]),
          buildSection('Compras', [
            MenuItem(label: 'Historial de compras', route: '/compras/historial'),
            MenuItem(label: 'Nueva compra', route: '/compras/nueva'),
          ]),
          buildSection('Proveedores', [
            MenuItem(label: 'Detalles de proveedor', route: '/proveedores/detalles'),
            MenuItem(label: 'Historial de compras', route: '/proveedores/historial'),
          ]),
          buildSection('Clientes', [
            MenuItem(label: 'Registrar cliente', route: '/clientes/registrar'),
            MenuItem(label: 'Editar cliente', route: '/clientes/editar'),
            MenuItem(label: 'Historial de compras', route: '/clientes/historial'),
          ]),
          buildSection('Empleados', [
            MenuItem(label: 'Registrar empleado', route: '/empleados/registrar'),
            MenuItem(label: 'Editar empleado', route: '/empleados/editar'),
            MenuItem(label: 'Control de accesos', route: '/empleados/accesos'),
          ]),
          buildSection('Reportes', [
            MenuItem(label: 'Reporte de venta', route: '/reportes/ventas'),
            MenuItem(label: 'Reporte de compras', route: '/reportes/compras'),
            MenuItem(label: 'Alertas de stock bajo', route: '/reportes/stock'),
            MenuItem(label: 'Alertas generales', route: '/reportes/alertas'),
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

  Widget buildSection(String title, List<MenuItem> items) {
    final isOpen = expanded[title] ?? false;
    return ExpansionTile(
      title: Text(title),
      initiallyExpanded: isOpen,
      onExpansionChanged: (_) => toggle(title),
      children: items.map((item) {
        return ListTile(
          title: Text(item.label),
          onTap: () {
            Navigator.pop(context); // Cierra el Drawer
            context.go(item.route);      // Navega a la ruta
          },
        );
      }).toList(),
    );
  }
}

class MenuItem {
  final String label;
  final String route;

  MenuItem({required this.label, required this.route});
}

