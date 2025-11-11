import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<void> registrarUsuario(String email, String password, String rol, String idEmpleado) async {
    final response = await supabase.auth.signUp(email: email, password: password);
    final userId = response.user?.id;

    if (userId != null) {
      await supabase.from('usuarios').insert({
        'id_usuario': userId,
        'email': email,
        'rol': rol,
        'id_empleado': idEmpleado,
      });
    }
  }

  Future<Map<String, dynamic>> obtenerUsuarioActual() async {
    final userId = supabase.auth.currentUser?.id;
    return await supabase.from('usuarios').select().eq('id_usuario', userId as Object).single();
  }
}
