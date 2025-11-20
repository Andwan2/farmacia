class ProductoDB {
  final int idProducto;
  final String nombreProducto;
  final int idPresentacion;
  final String fechaVencimiento;
  final String tipo;
  final String medida;
  final bool esVisible;
  final double? precioVenta;
  final double? precioCompra;

  ProductoDB({
    required this.idProducto,
    required this.nombreProducto,
    required this.idPresentacion,
    required this.fechaVencimiento,
    required this.tipo,
    required this.medida,
    required this.esVisible,
    this.precioVenta,
    this.precioCompra,
  });

  factory ProductoDB.fromJson(Map<String, dynamic> json) {
    return ProductoDB(
      idProducto: json['id_producto'] as int,
      nombreProducto: json['nombre_producto'] as String,
      idPresentacion: json['id_presentacion'] as int,
      fechaVencimiento: json['fecha_vencimiento'] as String,
      tipo: json['tipo'] as String,
      medida: json['medida'] as String,
      esVisible: json['esVisible'] as bool? ?? true,
      precioVenta: (json['precio_venta'] as num?)?.toDouble(),
      precioCompra: (json['precio_compra'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_producto': idProducto,
      'nombre_producto': nombreProducto,
      'id_presentacion': idPresentacion,
      'fecha_vencimiento': fechaVencimiento,
      'tipo': tipo,
      'medida': medida,
      'esVisible': esVisible,
      'precio_venta': precioVenta,
      'precio_compra': precioCompra,
    };
  }
}
