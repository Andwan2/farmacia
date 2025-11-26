class ProductoDB {
  final int idProducto;
  final String nombreProducto;
  final int? idPresentacion;
  final int? idUnidadMedida;
  final String? nombrePresentacion;
  final String? nombreUnidadMedida;
  final String? abreviaturaUnidad;
  final String? fechaVencimiento;
  final String codigo;
  final double cantidad;
  final String estado;
  final double? precioVenta;
  final double? precioCompra;

  ProductoDB({
    required this.idProducto,
    required this.nombreProducto,
    this.idPresentacion,
    this.idUnidadMedida,
    this.nombrePresentacion,
    this.nombreUnidadMedida,
    this.abreviaturaUnidad,
    this.fechaVencimiento,
    required this.codigo,
    required this.cantidad,
    required this.estado,
    this.precioVenta,
    this.precioCompra,
  });

  factory ProductoDB.fromJson(Map<String, dynamic> json) {
    // Extraer nombres de presentación y unidad de medida si vienen anidados
    String? nombrePres;
    String? nombreUnidad;
    String? abrevUnidad;

    if (json['presentacion'] is Map) {
      nombrePres = json['presentacion']['descripcion'] as String?;
    }
    if (json['unidad_medida'] is Map) {
      nombreUnidad = json['unidad_medida']['nombre'] as String?;
      abrevUnidad = json['unidad_medida']['abreviatura'] as String?;
    }

    return ProductoDB(
      idProducto: json['id_producto'] as int,
      nombreProducto: json['nombre_producto'] as String? ?? '',
      idPresentacion: json['id_presentacion'] as int?,
      idUnidadMedida: json['id_unidad_medida'] as int?,
      nombrePresentacion: nombrePres,
      nombreUnidadMedida: nombreUnidad,
      abreviaturaUnidad: abrevUnidad,
      fechaVencimiento: json['fecha_vencimiento'] as String?,
      codigo: json['codigo'] as String? ?? '',
      cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0,
      estado: json['estado'] as String? ?? 'Disponible',
      precioVenta: (json['precio_venta'] as num?)?.toDouble(),
      precioCompra: (json['precio_compra'] as num?)?.toDouble(),
    );
  }

  /// Obtiene la presentación formateada (ej: "2 Lb - Bolsa")
  String get presentacionFormateada {
    final partes = <String>[];
    if (cantidad > 0) {
      final cantidadStr = cantidad == cantidad.toInt()
          ? cantidad.toInt().toString()
          : cantidad.toString();
      partes.add(cantidadStr);
    }
    if (abreviaturaUnidad != null && abreviaturaUnidad!.isNotEmpty) {
      partes.add(abreviaturaUnidad!);
    }
    if (nombrePresentacion != null && nombrePresentacion!.isNotEmpty) {
      if (partes.isNotEmpty) {
        return '${partes.join(' ')} - $nombrePresentacion';
      }
      return nombrePresentacion!;
    }
    return partes.join(' ');
  }

  Map<String, dynamic> toJson() {
    return {
      'id_producto': idProducto,
      'nombre_producto': nombreProducto,
      'id_presentacion': idPresentacion,
      'id_unidad_medida': idUnidadMedida,
      'fecha_vencimiento': fechaVencimiento,
      'codigo': codigo,
      'cantidad': cantidad,
      'estado': estado,
      'precio_venta': precioVenta,
      'precio_compra': precioCompra,
    };
  }

  /// Verifica si el producto está disponible (no Vendido ni Removido)
  bool get estaDisponible => estado != 'Vendido' && estado != 'Removido';
}

/// Representa un grupo de productos con el mismo código
class ProductoAgrupado {
  final String codigo;
  final String nombreProducto;
  final double cantidad;
  final String? nombrePresentacion;
  final String? abreviaturaUnidad;
  final double? precioVenta;
  final double? precioCompra;
  final int stock; // Cantidad de unidades disponibles
  final List<ProductoDB> productos; // Lista de productos individuales

  ProductoAgrupado({
    required this.codigo,
    required this.nombreProducto,
    required this.cantidad,
    this.nombrePresentacion,
    this.abreviaturaUnidad,
    this.precioVenta,
    this.precioCompra,
    required this.stock,
    required this.productos,
  });

  /// Obtiene el primer producto disponible del grupo
  ProductoDB? get primerProducto =>
      productos.isNotEmpty ? productos.first : null;

  /// Obtiene la presentación formateada (ej: "2 Lb - Bolsa")
  String get presentacionFormateada {
    final partes = <String>[];
    if (cantidad > 0) {
      final cantidadStr = cantidad == cantidad.toInt()
          ? cantidad.toInt().toString()
          : cantidad.toString();
      partes.add(cantidadStr);
    }
    if (abreviaturaUnidad != null && abreviaturaUnidad!.isNotEmpty) {
      partes.add(abreviaturaUnidad!);
    }
    if (nombrePresentacion != null && nombrePresentacion!.isNotEmpty) {
      if (partes.isNotEmpty) {
        return '${partes.join(' ')} - $nombrePresentacion';
      }
      return nombrePresentacion!;
    }
    return partes.join(' ');
  }
}
