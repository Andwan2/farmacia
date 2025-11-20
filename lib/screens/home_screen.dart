// ===============================
// DEPRECATED: Este archivo ya no se usa
// ===============================
// La navegación ahora se maneja con go_router y ShellRoute.
// El AppBar y Drawer están en lib/widgets/app_shell.dart
// Las rutas están definidas en lib/router.dart
// ===============================

import 'package:farmacia_desktop/screens/about.dart';
import 'package:farmacia_desktop/screens/clientes.dart';
import 'package:farmacia_desktop/screens/compras.dart';
import 'package:farmacia_desktop/screens/productos.dart';
import 'package:farmacia_desktop/screens/proveedores.dart';
import 'package:farmacia_desktop/screens/ventas.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ===============================
// HOME SCREEN CON BODY DINÁMICO (DEPRECATED)
// ===============================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Widget _currentPage = const Center(
    child: Text('Selecciona una opción del menú'),
  );

  void changeScreen(Widget screen) {
    setState(() {
      _currentPage = screen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de inventario de farmacia André'),
      ),
      drawer: SideMenu(onSelectPage: changeScreen),
      body: _currentPage,
    );
  }
}

// ===============================
// SIDE MENU
// ===============================

class SideMenu extends StatefulWidget {
  final void Function(Widget) onSelectPage;

  const SideMenu({super.key, required this.onSelectPage});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          const DrawerHeader(
            child: Text('Menú Principal', style: TextStyle(fontSize: 18)),
          ),

          buildSection("Inventario", [
            ('Productos', '/productos', Icons.inventory),
          ]),

          const Divider(),

          buildSection("Recursos humanos", [
            ('Proveedores', '/proveedores', Icons.corporate_fare),
            ('Clientes', '/clientes', Icons.verified_user),
          ]),

          const Divider(),

          buildSection("Transacciones", [
            ('Ventas', '/ventas', Icons.point_of_sale),
            ('Compras', '/compras', Icons.attach_money),
          ]),

          const Divider(),

          buildSection("Info", [('Acerca de', '/about', Icons.info)]),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.pop(context);
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  // ======================
  // SECCIONES DEL DRAWER
  // ======================
  Widget buildSection(String title, List<(String, String, IconData?)> items) {
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

              switch (route) {
                case '/productos':
                  widget.onSelectPage(ProductosScreen());
                  break;
                case '/proveedores':
                  widget.onSelectPage(const ProveedoresScreen());
                  break;
                case '/clientes':
                  widget.onSelectPage(const ClientesScreen());
                  break;
                case '/ventas':
                  widget.onSelectPage(const VentasScreen());
                  break;
                case '/compras':
                  widget.onSelectPage(const ComprasScreen());
                  break;
                case '/about':
                  widget.onSelectPage(const AboutScreen());
                  break;
              }
            },
          );
        }),
      ],
    );
  }
}
