import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para preparar datos y comunicarse con la API de predicción Prophet
class PredictionService {
  // URL del servidor de predicción (configurar según ambiente)
  static String baseUrl = 'http://10.0.2.2:8000'; // Android emulator
  // static String baseUrl = 'http://localhost:8000'; // Web/Desktop

  /// Obtiene y estructura datos históricos de ventas para Prophet
  /// Retorna lista con formato: {ds: fecha, y: cantidad, producto_id, producto_nombre}
  static Future<List<Map<String, dynamic>>> obtenerDatosHistoricos() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Obtener todas las ventas
      final ventasResponse = await supabase
          .from('venta')
          .select('id_venta, fecha')
          .order('fecha');

      final ventas = List<Map<String, dynamic>>.from(ventasResponse);
      if (ventas.isEmpty) return [];

      // 2. Obtener todos los productos vendidos con su información
      final productosEnVenta = await supabase.from('producto_en_venta').select(
        '''
            id_venta,
            producto:id_producto (
              id_producto,
              nombre_producto,
              cantidad,
              presentacion:id_presentacion (descripcion),
              unidad_medida:id_unidad_medida (nombre, abreviatura)
            )
          ''',
      );

      // 3. Indexar productos por id_venta para acceso O(1)
      final productosPorVenta = <int, List<Map<String, dynamic>>>{};
      for (var pv in productosEnVenta) {
        final idVenta = pv['id_venta'] as int?;
        if (idVenta != null) {
          productosPorVenta.putIfAbsent(idVenta, () => []).add(pv);
        }
      }

      // 4. Construir datos estructurados para Prophet
      final datosHistoricos = <Map<String, dynamic>>[];

      for (var venta in ventas) {
        final idVenta = venta['id_venta'] as int;
        final fecha = venta['fecha'] as String;
        final productosDeVenta = productosPorVenta[idVenta] ?? [];

        for (var pv in productosDeVenta) {
          final producto = pv['producto'] as Map<String, dynamic>?;
          if (producto == null) continue;

          final presentacion =
              producto['presentacion'] as Map<String, dynamic>?;
          final unidadMedida =
              producto['unidad_medida'] as Map<String, dynamic>?;

          final descripcionPres = (presentacion?['descripcion'] ?? '')
              .toString();
          final abreviatura = (unidadMedida?['abreviatura'] ?? '').toString();
          final cantidadProducto =
              (producto['cantidad'] as num?)?.toDouble() ?? 0;

          // Detectar si es a granel
          final esAGranel =
              descripcionPres.toLowerCase().contains('granel') ||
              descripcionPres.toLowerCase() == 'agranel';

          // Cantidad vendida:
          // - A granel: usar campo 'cantidad' (ej: 5.5 libras)
          // - Unitario: contar como 1 unidad
          final cantidadVendida = esAGranel ? cantidadProducto : 1.0;

          datosHistoricos.add({
            'ds': fecha,
            'y': cantidadVendida,
            'producto_id': producto['id_producto'],
            'producto_nombre': producto['nombre_producto'],
            'presentacion': descripcionPres,
            'cantidad_producto': cantidadProducto,
            'unidad_abreviatura': abreviatura,
            'es_granel': esAGranel,
          });
        }
      }

      return datosHistoricos;
    } catch (e) {
      throw Exception('Error al obtener datos históricos: $e');
    }
  }

  /// Agrupa datos por fecha (suma todas las cantidades por día)
  /// Formato requerido por Prophet: [{ds: 'YYYY-MM-DD', y: cantidad}]
  static List<Map<String, dynamic>> agruparPorFecha(
    List<Map<String, dynamic>> datos,
  ) {
    final agrupado = <String, double>{};

    for (var d in datos) {
      final fecha = d['ds'] as String;
      final cantidad = (d['y'] as num).toDouble();
      agrupado[fecha] = (agrupado[fecha] ?? 0) + cantidad;
    }

    final resultado =
        agrupado.entries.map((e) => {'ds': e.key, 'y': e.value}).toList()
          ..sort((a, b) => (a['ds'] as String).compareTo(b['ds'] as String));

    return resultado;
  }

  /// Agrupa datos por producto y fecha
  static Map<int, List<Map<String, dynamic>>> agruparPorProducto(
    List<Map<String, dynamic>> datos,
  ) {
    final porProducto = <int, List<Map<String, dynamic>>>{};

    for (var d in datos) {
      final productoId = d['producto_id'] as int;
      porProducto.putIfAbsent(productoId, () => []).add({
        'ds': d['ds'],
        'y': d['y'],
      });
    }

    // Agrupar por fecha dentro de cada producto
    final resultado = <int, List<Map<String, dynamic>>>{};
    for (var entry in porProducto.entries) {
      resultado[entry.key] = agruparPorFecha(entry.value);
    }

    return resultado;
  }

  /// Obtiene productos más vendidos
  static List<Map<String, dynamic>> obtenerTopProductos(
    List<Map<String, dynamic>> datos, {
    int limite = 10,
  }) {
    final porProducto = <int, Map<String, dynamic>>{};

    for (var d in datos) {
      final id = d['producto_id'] as int;
      final cantidad = (d['y'] as num).toDouble();

      if (porProducto.containsKey(id)) {
        porProducto[id]!['total'] =
            (porProducto[id]!['total'] as double) + cantidad;
        porProducto[id]!['ventas'] = (porProducto[id]!['ventas'] as int) + 1;
      } else {
        porProducto[id] = {
          'producto_id': id,
          'nombre': d['producto_nombre'],
          'presentacion': d['presentacion'],
          'cantidad_producto': d['cantidad_producto'],
          'unidad_abreviatura': d['unidad_abreviatura'],
          'total': cantidad,
          'ventas': 1,
          'es_granel': d['es_granel'],
        };
      }
    }

    final lista = porProducto.values.toList()
      ..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));

    return lista.take(limite).toList();
  }

  /// Envía datos al backend y obtiene predicciones
  static Future<PredictionResult> obtenerPredicciones({
    required List<Map<String, dynamic>> datosAgrupados,
    int periodos = 30,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'historical_data': datosAgrupados,
              'periods': periodos,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return PredictionResult.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al conectar con servidor de predicción: $e');
    }
  }

  /// Verifica conexión con el servidor
  static Future<bool> verificarConexion() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Resultado de predicción
class PredictionResult {
  final List<PredictionPoint> predicciones;
  final String? mensaje;

  PredictionResult({required this.predicciones, this.mensaje});

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    final forecast = json['forecast'] as List? ?? [];
    return PredictionResult(
      predicciones: forecast
          .map((p) => PredictionPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      mensaje: json['message'] as String?,
    );
  }

  /// Predicciones para los próximos 7 días
  List<PredictionPoint> get proximaSemana => predicciones.take(7).toList();

  /// Predicciones para los próximos 30 días
  List<PredictionPoint> get proximo30Dias => predicciones.take(30).toList();

  /// Demanda total predicha para la semana
  double get demandaSemana => proximaSemana.fold(0.0, (sum, p) => sum + p.yhat);

  /// Demanda total predicha para 30 días
  double get demanda30Dias => proximo30Dias.fold(0.0, (sum, p) => sum + p.yhat);
}

/// Punto de predicción individual
class PredictionPoint {
  final DateTime fecha;
  final double yhat;
  final double yhatLower;
  final double yhatUpper;

  PredictionPoint({
    required this.fecha,
    required this.yhat,
    required this.yhatLower,
    required this.yhatUpper,
  });

  factory PredictionPoint.fromJson(Map<String, dynamic> json) {
    return PredictionPoint(
      fecha: DateTime.parse(json['ds'] as String),
      yhat: (json['yhat'] as num).toDouble(),
      yhatLower: (json['yhat_lower'] as num?)?.toDouble() ?? 0,
      yhatUpper: (json['yhat_upper'] as num?)?.toDouble() ?? 0,
    );
  }
}
