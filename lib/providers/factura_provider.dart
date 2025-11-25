import 'package:flutter/foundation.dart';
import 'package:abari/models/producto_db.dart';
import 'package:abari/models/payment_method.dart';
import 'package:abari/models/cliente.dart';
import 'package:abari/screens/factura/widgets/invoice_table.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FacturaProvider extends ChangeNotifier {
  DateTime _fecha = DateTime.now();
  String _metodoPago = '';
  int? _metodoPagoId;
  String _cliente = '';
  int? _clienteId;
  String _empleado = '';
  int? _empleadoId;
  int _formKey = 0; // Key para forzar reconstrucción de widgets

  final List<ProductoFactura> _productos = [];
  List<PaymentMethod> _metodosPago = [];
  bool _isLoadingMetodosPago = false;
  bool _metodosPagoCargados = false;

  List<Cliente> _clientes = [];
  bool _isLoadingClientes = false;
  bool _clientesCargados = false;

  DateTime get fecha => _fecha;
  String get metodoPago => _metodoPago;
  int? get metodoPagoId => _metodoPagoId;
  String get cliente => _cliente;
  int? get clienteId => _clienteId;
  String get empleado => _empleado;
  int? get empleadoId => _empleadoId;
  List<ProductoFactura> get productos => List.unmodifiable(_productos);
  List<PaymentMethod> get metodosPago => List.unmodifiable(_metodosPago);
  bool get isLoadingMetodosPago => _isLoadingMetodosPago;
  bool get metodosPagoCargados => _metodosPagoCargados;
  List<Cliente> get clientes => List.unmodifiable(_clientes);
  bool get isLoadingClientes => _isLoadingClientes;
  bool get clientesCargados => _clientesCargados;
  int get formKey => _formKey;

  double get total {
    return _productos.fold(
      0.0,
      (sum, item) => sum + (item.precio * item.cantidad),
    );
  }

  void setFecha(DateTime fecha) {
    _fecha = fecha;
    notifyListeners();
  }

  void setMetodoPago(String metodoPago) {
    _metodoPago = metodoPago;
    // Buscar el ID del método de pago
    if (_metodosPago.isNotEmpty) {
      final metodo = _metodosPago.firstWhere(
        (m) => m.name == metodoPago,
        orElse: () => _metodosPago.first,
      );
      _metodoPagoId = metodo.id;
    }
    notifyListeners();
  }

  void setCliente(String cliente) {
    _cliente = cliente;
    // Buscar el ID del cliente
    if (_clientes.isNotEmpty) {
      final clienteObj = _clientes.firstWhere(
        (c) => c.nombreCliente == cliente,
        orElse: () => _clientes.first,
      );
      _clienteId = clienteObj.idCliente;
    }
    notifyListeners();
  }

  void setEmpleado(String empleado, {int? empleadoId}) {
    _empleado = empleado;
    _empleadoId = empleadoId;
    notifyListeners();
  }

  // Métodos para productos
  void agregarProducto(ProductoDB producto, {int cantidad = 1}) {
    _productos.add(
      ProductoFactura(
        idProducto: producto.idProducto,
        cantidad: cantidad,
        nombre: producto.nombreProducto,
        presentacion: producto.codigo,
        medida: producto.cantidad.toString(),
        fechaVencimiento: producto.fechaVencimiento,
        precio: producto.precioVenta ?? 0.0,
      ),
    );
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
        idProducto: producto.idProducto,
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
    _metodoPago = '';
    _metodoPagoId = null;
    _cliente = '';
    _clienteId = null;
    _empleado = '';
    _empleadoId = null;
    _productos.clear();
    _formKey++; // Incrementar key para forzar reconstrucción
    notifyListeners();
  }

  // Cargar métodos de pago desde la base de datos
  Future<void> cargarMetodosPago() async {
    print('============================================');
    print('cargarMetodosPago INICIADO');
    print('_isLoadingMetodosPago: $_isLoadingMetodosPago');
    print('_metodosPagoCargados: $_metodosPagoCargados');
    print('============================================');

    if (_isLoadingMetodosPago || _metodosPagoCargados) {
      print('⚠️ SALIENDO - Ya está cargando o ya fue cargado');
      return;
    }

    print('✅ Iniciando carga...');
    _isLoadingMetodosPago = true;
    notifyListeners();

    try {
      print('📡 Consultando Supabase tabla: payment_method');

      final response = await Supabase.instance.client
          .from('payment_method')
          .select('id, name, provider, created_at')
          .order('name');

      print('📦 Respuesta recibida: $response');
      print('📦 Tipo de respuesta: ${response.runtimeType}');

      _metodosPago = (response as List)
          .map((json) => PaymentMethod.fromJson(json))
          .toList();

      print('✅ ${_metodosPago.length} métodos cargados exitosamente');
      for (var metodo in _metodosPago) {
        print('   • ${metodo.name} (provider: ${metodo.provider})');
      }

      // Sincronizar el método de pago ANTES de marcar como cargado
      // Solo si hay un método seleccionado que ya no existe
      if (_metodosPago.isNotEmpty && _metodoPago.isNotEmpty) {
        if (!_metodosPago.any((m) => m.name == _metodoPago)) {
          final viejoMetodo = _metodoPago;
          _metodoPago = _metodosPago.first.name;
          print('🔄 Método actualizado de "$viejoMetodo" a "$_metodoPago"');
        }
      }

      _metodosPagoCargados = true;
      print('✅ Marcado como cargado');
    } catch (e, stackTrace) {
      print('❌ ERROR cargando métodos de pago:');
      print('   Error: $e');
      print('   Stack: $stackTrace');
      _metodosPago = [];
    } finally {
      _isLoadingMetodosPago = false;
      print('🏁 Finalizando carga, notificando listeners...');
      notifyListeners();
      print('============================================');
    }
  }

  // Cargar clientes desde la base de datos
  Future<void> cargarClientes() async {
    print('============================================');
    print('cargarClientes INICIADO');
    print('_isLoadingClientes: $_isLoadingClientes');
    print('_clientesCargados: $_clientesCargados');
    print('============================================');

    if (_isLoadingClientes || _clientesCargados) {
      print('⚠️ SALIENDO - Ya está cargando o ya fue cargado');
      return;
    }

    print('✅ Iniciando carga...');
    _isLoadingClientes = true;
    notifyListeners();

    try {
      print('📡 Consultando Supabase tabla: cliente');

      final response = await Supabase.instance.client
          .from('cliente')
          .select('id_cliente, nombre_cliente, numero_telefono')
          .order('nombre_cliente');

      print('📦 Respuesta recibida: $response');
      print('📦 Tipo de respuesta: ${response.runtimeType}');

      _clientes = (response as List)
          .map((json) => Cliente.fromJson(json))
          .toList();

      print('✅ ${_clientes.length} clientes cargados exitosamente');
      for (var cliente in _clientes) {
        print(
          '   • ${cliente.nombreCliente} (tel: ${cliente.numeroTelefono ?? "N/A"})',
        );
      }

      _clientesCargados = true;
      print('✅ Marcado como cargado');
    } catch (e, stackTrace) {
      print('❌ ERROR cargando clientes:');
      print('   Error: $e');
      print('   Stack: $stackTrace');
      _clientes = [];
    } finally {
      _isLoadingClientes = false;
      print('🏁 Finalizando carga, notificando listeners...');
      notifyListeners();
      print('============================================');
    }
  }

  // Validar que todos los campos requeridos estén completos
  String? validarFactura() {
    if (_cliente.isEmpty) {
      return 'Debe seleccionar un cliente';
    }
    if (_empleado.isEmpty) {
      return 'Debe seleccionar un empleado';
    }
    if (_metodoPago.isEmpty) {
      return 'Debe seleccionar un método de pago';
    }
    if (_productos.isEmpty) {
      return 'Debe agregar al menos un producto';
    }
    // La fecha siempre tendrá un valor (DateTime.now() por defecto)
    return null; // Todo válido
  }

  // Guardar venta en la base de datos
  Future<String?> guardarVenta() async {
    print('============================================');
    print('GUARDANDO VENTA');
    print('============================================');

    try {
      // 1. Verificar que tenemos todos los IDs necesarios
      if (_clienteId == null) {
        return 'Error: ID de cliente no encontrado';
      }
      if (_empleadoId == null) {
        return 'Error: ID de empleado no encontrado';
      }
      if (_metodoPagoId == null) {
        return 'Error: ID de método de pago no encontrado';
      }

      // 2. Verificar stock disponible para cada tipo de producto
      print('📦 Verificando stock disponible...');
      for (var producto in _productos) {
        final stockDisponible = await Supabase.instance.client
            .from('producto')
            .select('id_producto')
            .eq('codigo', producto.presentacion)
            .eq('estado', 'Disponible')
            .count(CountOption.exact);

        final count = stockDisponible.count;
        print(
          '   • ${producto.presentacion}: ${producto.cantidad} requeridos, $count disponibles',
        );

        if (count < producto.cantidad) {
          return 'Stock insuficiente para ${producto.presentacion}. Disponibles: $count, Requeridos: ${producto.cantidad}';
        }
      }

      print('✅ Stock verificado correctamente');

      // 3. Insertar en tabla venta
      print('💾 Insertando venta...');
      final ventaResponse = await Supabase.instance.client
          .from('venta')
          .insert({
            'fecha': _fecha.toIso8601String().split(
              'T',
            )[0], // Solo la fecha YYYY-MM-DD
            'total': total,
            'id_cliente': _clienteId,
            'id_empleado': _empleadoId,
            'payment_method_id': _metodoPagoId,
          })
          .select('id_venta')
          .single();

      final idVenta = ventaResponse['id_venta'] as int;
      print('✅ Venta creada con ID: $idVenta');

      // 4. Para cada tipo de producto, seleccionar productos individuales y marcarlos como vendidos
      print('🔄 Procesando productos...');
      for (var producto in _productos) {
        print(
          '   📦 Procesando: ${producto.presentacion} x${producto.cantidad}',
        );

        // Seleccionar N productos disponibles de este tipo (FIFO por fecha_vencimiento)
        final productosDisponibles = await Supabase.instance.client
            .from('producto')
            .select('id_producto')
            .eq('codigo', producto.presentacion)
            .eq('estado', 'Disponible')
            .order('fecha_vencimiento', ascending: true)
            .limit(producto.cantidad);

        final idsProductos = (productosDisponibles as List)
            .map((p) => p['id_producto'] as int)
            .toList();

        print('      • IDs seleccionados: $idsProductos');

        // Actualizar estado a 'Vendido'
        await Supabase.instance.client
            .from('producto')
            .update({'estado': 'Vendido'})
            .inFilter('id_producto', idsProductos);

        print(
          '      ✅ ${idsProductos.length} productos marcados como Vendidos',
        );

        // Insertar en producto_en_venta
        final productosEnVenta = idsProductos
            .map(
              (idProducto) => {'id_producto': idProducto, 'id_venta': idVenta},
            )
            .toList();

        await Supabase.instance.client
            .from('producto_en_venta')
            .insert(productosEnVenta);

        print('      ✅ Relaciones creadas en producto_en_venta');
      }

      print('============================================');
      print('✅ VENTA GUARDADA EXITOSAMENTE - ID: $idVenta');
      print('============================================');

      return null; // Sin errores
    } catch (e, stackTrace) {
      print('❌ ERROR guardando venta:');
      print('   Error: $e');
      print('   Stack: $stackTrace');
      return 'Error al guardar la venta: $e';
    }
  }
}
