import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmacia_desktop/models/producto_db.dart';

class ProductoService {
  final _client = Supabase.instance.client;

  /// Busca productos por nombre en la base de datos
  /// Solo retorna productos disponibles
  Future<List<ProductoDB>> buscarProductos(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final response = await _client
          .from('producto')
          .select(
            'id_producto, nombre_producto, id_presentacion, fecha_vencimiento, tipo, medida, estado, precio_venta, precio_compra',
          )
          .eq('estado', 'Disponible')
          .ilike('nombre_producto', '%$query%')
          .order('nombre_producto', ascending: true)
          .limit(20);

      return response.map((json) => ProductoDB.fromJson(json)).toList();
    } catch (e) {
      print('Error al buscar productos: $e');
      return [];
    }
  }

  /// Obtiene un producto por su ID
  Future<ProductoDB?> obtenerProductoPorId(int idProducto) async {
    try {
      final response = await _client
          .from('producto')
          .select(
            'id_producto, nombre_producto, id_presentacion, fecha_vencimiento, tipo, medida, estado, precio_venta, precio_compra',
          )
          .eq('id_producto', idProducto)
          .single();

      return ProductoDB.fromJson(response);
    } catch (e) {
      print('Error al obtener producto: $e');
      return null;
    }
  }

  /// Obtiene todos los productos disponibles
  Future<List<ProductoDB>> obtenerTodosLosProductos() async {
    try {
      final response = await _client
          .from('producto')
          .select(
            'id_producto, nombre_producto, id_presentacion, fecha_vencimiento, tipo, medida, estado, precio_venta, precio_compra',
          )
          .eq('estado', 'Disponible')
          .order('nombre_producto', ascending: true);

      return response.map((json) => ProductoDB.fromJson(json)).toList();
    } catch (e) {
      print('Error al obtener productos: $e');
      return [];
    }
  }
}
