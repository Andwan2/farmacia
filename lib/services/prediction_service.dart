import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para preparar datos y comunicarse con la API de predicción Prophet
class PredictionService {
  // URL del servidor de predicción (configurar según ambiente)
  static String baseUrl = 'https://abari-ai.onrender.com/'; // Android emulator
  // static String baseUrl = 'http://localhost:8000'; // Web/Desktop

  /// Obtiene y estructura datos históricos de ventas para Prophet
  /// Retorna lista con formato: {ds: fecha, y: cantidad, producto_id, producto_nombre}
}
