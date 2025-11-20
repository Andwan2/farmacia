import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});
  @override
  State<ProductosScreen> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<ProductosScreen> {
  List<dynamic> productos = [];
  Map<int, Map<String, dynamic>> presentaciones =
      {}; // id_presentacion -> {descripcion, unidad_medida}
  Map<String, int> stockPorTipo = {};
  String busqueda = '';
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() => cargando = true);
    final client = Supabase.instance.client;

    // 1) Productos
    final resProd = await client
        .from('producto')
        .select(
          'id_producto,nombre_producto,id_presentacion,fecha_vencimiento,tipo,medida,esVisible',
        )
        .eq('esVisible', true)
        .order('nombre_producto', ascending: true);

    final dataProd = (resProd is List) ? resProd : <dynamic>[];

    // 2) Presentaciones para mapear id_presentacion -> descripcion/unidad_medida
    final resPres = await client
        .from('presentacion')
        .select('id_presentacion,descripcion,unidad_medida')
        .order('id_presentacion', ascending: true);

    final dataPres = (resPres is List) ? resPres : <dynamic>[];
    final Map<int, Map<String, dynamic>> presMap = {};
    for (final p in dataPres) {
      final id = p['id_presentacion'] as int;
      presMap[id] = {
        'descripcion': p['descripcion'],
        'unidad_medida': p['unidad_medida'],
      };
    }

    // 3) Stock por tipo (conteo)
    final Map<String, int> stock = {};
    for (final item in dataProd) {
      final tipo = item['tipo'] as String;
      stock[tipo] = (stock[tipo] ?? 0) + 1;
    }

    setState(() {
      productos = dataProd;
      presentaciones = presMap;
      stockPorTipo = stock;
      cargando = false;
    });
  }

  Future<void> eliminarProducto(int idProducto) async {
    await Supabase.instance.client
        .from('producto')
        .update({'esVisible': false})
        .eq('id_producto', idProducto);
    await cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    // Agrupar productos por tipo
    final Map<String, dynamic> productosPorTipo = {};
    for (final p in productos) {
      final tipo = p['tipo'] as String;
      if (!productosPorTipo.containsKey(tipo)) {
        productosPorTipo[tipo] = p;
      }
    }

    // Filtrar por búsqueda
    final listaFiltrada = productosPorTipo.values.where((p) {
      final nombre = p['nombre_producto']?.toString() ?? '';
      final tipo = p['tipo']?.toString() ?? '';
      return nombre.toLowerCase().contains(busqueda.toLowerCase()) ||
          tipo.toLowerCase().contains(busqueda.toLowerCase());
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar producto',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => busqueda = value),
            ),
          ),
          Expanded(
            child: cargando
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: listaFiltrada.length,
                    itemBuilder: (context, index) {
                      final p = listaFiltrada[index];
                      final idProducto = p['id_producto'] as int;
                      final nombre = p['nombre_producto'] as String;
                      final idPres = p['id_presentacion'] as int;
                      final tipo = p['tipo'] as String;
                      final medida = p['medida']?.toString() ?? '';
                      final presentacion =
                          presentaciones[idPres]?['descripcion'] ?? '—';
                      final unidad =
                          presentaciones[idPres]?['unidad_medida'] ?? '';
                      final fechaStr = p['fecha_vencimiento'] as String;
                      final fecha = DateTime.parse(fechaStr);
                      final diasRestantes = fecha
                          .difference(DateTime.now())
                          .inDays;
                      final stockTipo = stockPorTipo[tipo] ?? 0;
                      final color = diasRestantes < 30 ? Colors.red[100] : null;

                      return Card(
                        color: color,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(nombre),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$presentacion • $tipo'),
                              Text(
                                'Medida: $medida $unidad • Stock por tipo: $stockTipo',
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Vence: ${fecha.toIso8601String().split('T').first}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    diasRestantes < 30
                                        ? '⚠️ $diasRestantes días'
                                        : '$diasRestantes días',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: diasRestantes < 30
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  // TODO: Navegar a formulario de edición (usar id_producto)
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => eliminarProducto(idProducto),
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
          // TODO: Navegar a formulario de agregar
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
