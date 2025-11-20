import 'package:flutter/foundation.dart';
import 'package:farmacia_desktop/models/producto_db.dart';
import 'package:farmacia_desktop/screens/factura/widgets/invoice_table.dart';

class FacturaProvider extends ChangeNotifier {
  DateTime _fecha = DateTime.now();
  String _metodoPago = 'EFECTIVO';
  String _cliente = '';
  String _empleado = '';
  
  final List<ProductoFactura> _productos = [];
  
  DateTime get fecha => _fecha;
  String get metodoPago => _metodoPago;
  String get cliente => _cliente;
  String get empleado => _empleado;
  List<ProductoFactura> get productos => List.unmodifiable(_productos);
  
  double get total {
    return _productos.fold(0.0, (sum, item) => sum + (item.precio * item.cantidad));
  }
  
  void setFecha(DateTime fecha) {
    _fecha = fecha;
    notifyListeners();
  }
  
  void setMetodoPago(String metodoPago) {
    _metodoPago = metodoPago;
    notifyListeners();
  }
  
  void setCliente(String cliente) {
    _cliente = cliente;
    notifyListeners();
  }
  
  void setEmpleado(String empleado) {
    _empleado = empleado;
    notifyListeners();
  }
  
  // Métodos para productos
  void agregarProducto(ProductoDB producto, {int cantidad = 1}) {
    _productos.add(ProductoFactura(
      cantidad: cantidad,
      nombre: producto.nombreProducto,
      presentacion: producto.tipo,
      medida: producto.medida,
      fechaVencimiento: producto.fechaVencimiento,
      precio: producto.precioVenta ?? 0.0,
    ));
    notifyListeners();
  }
  
  void eliminarProducto(int index) {
    if (index >= 0 && index < _productos.length) {
      _productos.removeAt(index);
      notifyListeners();
    }
  }
  
  void actualizarCantidad(int index, int cantidad) {
    if (index >= 0 && index < _productos.length && cantidad > 0) {
      final producto = _productos[index];
      _productos[index] = ProductoFactura(
        cantidad: cantidad,
        nombre: producto.nombre,
        presentacion: producto.presentacion,
        medida: producto.medida,
        fechaVencimiento: producto.fechaVencimiento,
        precio: producto.precio,
      );
      notifyListeners();
    }
  }
  
  void limpiarFactura() {
    _fecha = DateTime.now();
    _metodoPago = 'EFECTIVO';
    _cliente = '';
    _empleado = '';
    _productos.clear();
    notifyListeners();
  }
}
