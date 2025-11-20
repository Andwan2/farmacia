import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  List<dynamic> productos = [];
  Map<String, int> stockPorTipo = {};
  String busqueda = '';

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    final client = Supabase.instance.client;

    final response = await client.from('producto').select();
    final data = response as List;

    final Map<String, int> stock = {};
    for (var item in data) {
      final tipo = item['tipo'];
      stock[tipo] = (stock[tipo] ?? 0) + 1;
    }

    setState(() {
      productos = data;
      stockPorTipo = stock;
    });
  }

  void eliminarProducto(String nombre) async {
    await Supabase.instance.client.from('producto').delete().eq('nombre', nombre);
    cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = productos.where((p) =>
      p['nombre'].toLowerCase().contains(busqueda.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Inventario')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar producto',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => busqueda = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtrados.length,
              itemBuilder: (context, index) {
                final p = filtrados[index];
                final stock = stockPorTipo[p['tipo']] ?? 0;
                final fecha = DateTime.parse(p['fecha_vencimiento']);
                final dias = fecha.difference(DateTime.now()).inDays;
                final color = dias < 30 ? Colors.red[100] : null;

                return Card(
                  color: color,
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(p['nombre']),
                    subtitle: Text('${p['presentacion']} • Stock: $stock • \$${p['precio']}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Vence: ${fecha.toLocal().toString().split(' ')[0]}'),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                // Aquí iría la lógica para editar
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => eliminarProducto(p['nombre']),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Aquí iría la lógica para agregar producto
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
