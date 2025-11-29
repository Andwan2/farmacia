import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para obtener predicciones desde Supabase Edge Function
class PredictionService {
  static final _client = Supabase.instance.client;

  /// Llama a la edge function 'get-predict' y retorna el resultado
  static Future<PredictionResult> obtenerPredicciones() async {
    try {
      final response = await _client.functions.invoke(
        'get-predict',
        method: HttpMethod.post,
        body: {'name': 'predict'}, // Body requerido por la edge function
      );

      if (response.status != 200) {
        throw Exception('Error ${response.status}: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['status'] != 'success') {
        throw Exception(data['error'] ?? 'Error desconocido');
      }

      return PredictionResult.fromJson(data);
    } catch (e) {
      throw Exception('Error al obtener predicciones: $e');
    }
  }
}

/// Resultado de predicción desde la edge function
class PredictionResult {
  final List<PredictionPoint> predictions;
  final int periods;

  PredictionResult({required this.predictions, required this.periods});

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    final predictions = (json['predictions'] as List? ?? [])
        .map((p) => PredictionPoint.fromJson(p as Map<String, dynamic>))
        .toList();

    return PredictionResult(
      predictions: predictions,
      periods: json['periods'] as int? ?? 30,
    );
  }

  /// Total predicho para los próximos 7 días
  double get totalSemana {
    final semana = predictions.take(7);
    return semana.fold(0.0, (sum, p) => sum + (p.yhat > 0 ? p.yhat : 0));
  }

  /// Total predicho para los 30 días
  double get total30Dias {
    return predictions.fold(0.0, (sum, p) => sum + (p.yhat > 0 ? p.yhat : 0));
  }

  /// Promedio diario predicho
  double get promedioDiario {
    if (predictions.isEmpty) return 0;
    return total30Dias / predictions.length;
  }
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

  /// Día de la semana abreviado
  String get diaSemana {
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return dias[fecha.weekday - 1];
  }

  /// Fecha formateada corta (dd/MM)
  String get fechaCorta {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}';
  }
}
