import 'package:flutter/foundation.dart';
import 'package:farmacia_desktop/models/producto_db.dart';
import 'package:farmacia_desktop/models/payment_method.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo simple para representar un proveedor
class ProveedorCompra {
  final int idProveedor;
  final String nombreProveedor;
  final String? rucProveedor;

  ProveedorCompra({
    required this.idProveedor,
    required this.nombreProveedor,
    this.rucProveedor,
  });

  factory ProveedorCompra.fromJson(Map<String, dynamic> json) {
    return ProveedorCompra(
      idProveedor: json['id_proveedor'] as int,
      nombreProveedor: json['nombre_proveedor'] as String,
      rucProveedor: json['ruc_proveedor'] as String?,
    );
  }
}

/// Item de producto dentro de una compra
class ProductoCompraItem {
  final int? idProductoBase; // Puede ser null si es un producto totalmente nuevo
  final int idPresentacion;
  final String nombre;
  final String tipo;
  final String medida;
  final String fechaVencimiento; // YYYY-MM-DD
  final double precioCompra;
  final double precioVenta;
  final int cantidad;

  const ProductoCompraItem({
    this.idProductoBase,
    required this.idPresentacion,
    required this.nombre,
    required this.tipo,
    required this.medida,
    required this.fechaVencimiento,
    required this.precioCompra,
    required this.precioVenta,
    required this.cantidad,
  });

  ProductoCompraItem copyWith({
    int? idProductoBase,
    int? idPresentacion,
    String? nombre,
    String? tipo,
    String? medida,
    String? fechaVencimiento,
    double? precioCompra,
    double? precioVenta,
    int? cantidad,
  }) {
    return ProductoCompraItem(
      idProductoBase: idProductoBase ?? this.idProductoBase,
      idPresentacion: idPresentacion ?? this.idPresentacion,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      medida: medida ?? this.medida,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      precioCompra: precioCompra ?? this.precioCompra,
      precioVenta: precioVenta ?? this.precioVenta,
      cantidad: cantidad ?? this.cantidad,
    );
  }

  factory ProductoCompraItem.fromProductoDB(ProductoDB producto,
      {required int cantidad, required double precioCompra, required double precioVenta}) {
    return ProductoCompraItem(
      idProductoBase: producto.idProducto,
      idPresentacion: producto.idPresentacion,
      nombre: producto.nombreProducto,
      tipo: producto.tipo,
      medida: producto.medida,
      fechaVencimiento: producto.fechaVencimiento,
      precioCompra: precioCompra,
      precioVenta: precioVenta,
      cantidad: cantidad,
    );
  }
}

class CompraProvider extends ChangeNotifier {
  DateTime _fecha = DateTime.now();
  String _metodoPago = '';
  int? _metodoPagoId;

  String _proveedor = '';
  int? _proveedorId;

  String _empleado = '';
  int? _empleadoId;

  int _formKey = 0; // Para forzar reconstrucciones en la UI si hiciera falta

  final List<ProductoCompraItem> _productos = [];

  List<PaymentMethod> _metodosPago = [];
  bool _isLoadingMetodosPago = false;
  bool _metodosPagoCargados = false;

  List<ProveedorCompra> _proveedores = [];
  bool _isLoadingProveedores = false;
  bool _proveedoresCargados = false;

  // Getters
  DateTime get fecha => _fecha;
  String get metodoPago => _metodoPago;
  int? get metodoPagoId => _metodoPagoId;

  String get proveedor => _proveedor;
  int? get proveedorId => _proveedorId;

  String get empleado => _empleado;
  int? get empleadoId => _empleadoId;

  int get formKey => _formKey;

  List<ProductoCompraItem> get productos => List.unmodifiable(_productos);
  List<PaymentMethod> get metodosPago => List.unmodifiable(_metodosPago);
  bool get isLoadingMetodosPago => _isLoadingMetodosPago;
  bool get metodosPagoCargados => _metodosPagoCargados;

  List<ProveedorCompra> get proveedores => List.unmodifiable(_proveedores);
  bool get isLoadingProveedores => _isLoadingProveedores;
  bool get proveedoresCargados => _proveedoresCargados;

  /// Total invertido (suma de costo)
  double get totalCosto {
    return _productos.fold(
      0.0,
      (sum, p) => sum + (p.precioCompra * p.cantidad),
    );
  }

  /// Total de venta esperable (usando precioVenta)
  double get totalVentaEsperable {
    return _productos.fold(
      0.0,
      (sum, p) => sum + (p.precioVenta * p.cantidad),
    );
  }

  /// Ganancia esperable
  double get gananciaEsperable => totalVentaEsperable - totalCosto;

  // Setters básicos
  void setFecha(DateTime fecha) {
    _fecha = fecha;
    notifyListeners();
  }

  void setMetodoPago(String metodoPago) {
    _metodoPago = metodoPago;
    if (_metodosPago.isNotEmpty) {
      final metodo = _metodosPago.firstWhere(
        (m) => m.name == metodoPago,
        orElse: () => _metodosPago.first,
      );
      _metodoPagoId = metodo.id;
    }
    notifyListeners();
  }

  void setProveedor(String proveedorNombre) {
    _proveedor = proveedorNombre;
    if (_proveedores.isNotEmpty) {
      final prov = _proveedores.firstWhere(
        (p) => p.nombreProveedor == proveedorNombre,
        orElse: () => _proveedores.first,
      );
      _proveedorId = prov.idProveedor;
    }
    notifyListeners();
  }

  void setEmpleado(String empleado, {int? empleadoId}) {
    _empleado = empleado;
    _empleadoId = empleadoId;
    notifyListeners();
  }

  // Gestión de productos en la compra
  void agregarProductoItem(ProductoCompraItem item) {
    _productos.add(item);
    notifyListeners();
  }

  void eliminarProducto(int index) {
    if (index >= 0 && index < _productos.length) {
      _productos.removeAt(index);
      notifyListeners();
    }
  }

  void actualizarProducto(int index, ProductoCompraItem itemActualizado) {
    if (index >= 0 && index < _productos.length) {
      _productos[index] = itemActualizado;
      notifyListeners();
    }
  }

  void limpiarCompra() {
    _fecha = DateTime.now();
    _metodoPago = '';
    _metodoPagoId = null;
    _proveedor = '';
    _proveedorId = null;
    _empleado = '';
    _empleadoId = null;
    _productos.clear();
    _formKey++;
    notifyListeners();
  }

  // Carga de métodos de pago (igual que en ventas)
  Future<void> cargarMetodosPago() async {
    if (_isLoadingMetodosPago || _metodosPagoCargados) {
      return;
    }

    _isLoadingMetodosPago = true;
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('payment_method')
          .select('id, name, provider, created_at')
          .order('name');

      _metodosPago = (response as List)
          .map((json) => PaymentMethod.fromJson(json))
          .toList();

      _metodosPagoCargados = true;
    } catch (e, stackTrace) {
      debugPrint('Error cargando métodos de pago (compra): $e');
      debugPrint(stackTrace.toString());
      _metodosPago = [];
    } finally {
      _isLoadingMetodosPago = false;
      notifyListeners();
    }
  }

  // Carga de proveedores desde la tabla proveedor
  Future<void> cargarProveedores() async {
    if (_isLoadingProveedores || _proveedoresCargados) {
      return;
    }

    _isLoadingProveedores = true;
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('proveedor')
          .select('id_proveedor, nombre_proveedor, ruc_proveedor')
          .order('nombre_proveedor');

      _proveedores = (response as List)
          .map((json) => ProveedorCompra.fromJson(json))
          .toList();

      _proveedoresCargados = true;
    } catch (e, stackTrace) {
      debugPrint('Error cargando proveedores (compra): $e');
      debugPrint(stackTrace.toString());
      _proveedores = [];
    } finally {
      _isLoadingProveedores = false;
      notifyListeners();
    }
  }

  // Validación básica de la compra
  String? validarCompra() {
    if (_proveedor.isEmpty) {
      return 'Debe seleccionar un proveedor';
    }
    if (_empleado.isEmpty) {
      return 'Debe seleccionar un empleado';
    }
    if (_metodoPago.isEmpty) {
      return 'Debe seleccionar un método de pago';
    }
    if (_productos.isEmpty) {
      return 'Debe agregar al menos un producto a la compra';
    }
    return null;
  }

  /// Guarda la compra en la base de datos.
  /// Flujo inverso a guardarVenta:
  /// - Inserta en `compra` (con payment_method_id)
  /// - Inserta N filas en `producto` por cada unidad comprada (estado Disponible)
  /// - Inserta relaciones en `producto_a_comprar`.
  Future<String?> guardarCompra() async {
    try {
      if (_proveedorId == null) {
        return 'Error: ID de proveedor no encontrado';
      }
      if (_empleadoId == null) {
        return 'Error: ID de empleado no encontrado';
      }
      if (_metodoPagoId == null) {
        return 'Error: ID de método de pago no encontrado';
      }

      // 1. Insertar en tabla compra (total = totalCosto pagado al proveedor)
      final compraResponse = await Supabase.instance.client
          .from('compra')
          .insert({
            'fecha': _fecha.toIso8601String().split('T')[0],
            'total': totalCosto,
            'id_proveedor': _proveedorId,
            'id_empleado': _empleadoId,
            'payment_method_id': _metodoPagoId,
          })
          .select('id_compras')
          .single();

      final idCompra = compraResponse['id_compras'] as int;

      // 2. Para cada producto en la compra, crear N unidades en tabla producto
      for (final item in _productos) {
        if (item.cantidad <= 0) continue;

        // Construimos la lista de filas a insertar en producto
        final List<Map<String, dynamic>> filasProducto = List.generate(
          item.cantidad,
          (_) => {
            'nombre_producto': item.nombre,
            'id_presentacion': item.idPresentacion,
            'fecha_vencimiento': item.fechaVencimiento,
            'tipo': item.tipo,
            'medida': item.medida,
            'estado': 'Disponible',
            'precio_venta': item.precioVenta,
            'precio_compra': item.precioCompra,
          },
        );

        final productosInsertados = await Supabase.instance.client
            .from('producto')
            .insert(filasProducto)
            .select('id_producto');

        final idsProductos = (productosInsertados as List)
            .map((p) => p['id_producto'] as int)
            .toList();

        // 3. Insertar relaciones en producto_a_comprar
        final filasRelacion = idsProductos
            .map((idProducto) => {
                  'id_compra': idCompra,
                  'id_producto': idProducto,
                })
            .toList();

        await Supabase.instance.client
            .from('producto_a_comprar')
            .insert(filasRelacion);
      }

      return null; // éxito
    } catch (e, stackTrace) {
      debugPrint('Error guardando compra: $e');
      debugPrint(stackTrace.toString());
      return 'Error al guardar la compra: $e';
    }
  }
}
