import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/notificacion.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _nameController = TextEditingController();
  final _telefonoController = TextEditingController();
  
  DateTime? _fechaNacimiento;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('perfiles') 
          .select('nombre, telefono, fecha_nacimiento')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _nameController.text = response['nombre'] ?? '';
          _telefonoController.text = response['telefono'] ?? '';
          
          if (response['fecha_nacimiento'] != null) {
            _fechaNacimiento = DateTime.parse(response['fecha_nacimiento']);
          }
        });
      }
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
    }
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Selecciona tu fecha de nacimiento',
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _acento,
            surface: _superficie,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _fechaNacimiento) {
      setState(() {
        _fechaNacimiento = picked;
      });
    }
  }

  Future<void> _guardarPerfil() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final newName = _nameController.text.trim();
      final newPhone = _telefonoController.text.trim();
      final newDate = _fechaNacimiento != null 
          ? "${_fechaNacimiento!.year}-${_fechaNacimiento!.month.toString().padLeft(2, '0')}-${_fechaNacimiento!.day.toString().padLeft(2, '0')}"
          : null;

      // ACTUALIZAR EN LA BASE DE DATOS (Asegúrate de que 'usuarios' sea el nombre de tu tabla)
      await Supabase.instance.client
          .from('perfiles') 
          .update({
            'nombre': newName,
            'telefono': newPhone,
            'fecha_nacimiento': newDate,
          })
          .eq('id', user.id);

      if (mounted) {
        Notificacion.exito(context, 'Tu perfil se guardó correctamente.', titulo: 'Perfil guardado');
      }
    } catch (e) {
      if (mounted) {
        Notificacion.excepcion(context, e, titulo: 'No se pudo guardar');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cerrarSesion() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  // Colores del dashboard
  static const _fondo = Color(0xFF0F172A);
  static const _superficie = Color(0xFF1E293B);
  static const _acento = Color(0xFF3B82F6);

  // Mismo estilo de campos que el login, con la paleta del dashboard
  InputDecoration _decoracionCampo(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: _fondo,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: _acento),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _superficie,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Mi Perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(30.0),
            decoration: BoxDecoration(
              color: _superficie,
              borderRadius: BorderRadius.circular(35.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.17),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.teal.shade700,
                    child: const Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Editar mi perfil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Text(
                  user?.email ?? 'Desconocido',
                  style: const TextStyle(fontSize: 14, color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // CAMPO: NOMBRE
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoracionCampo('Nombre completo', Icons.badge_outlined),
                ),
                const SizedBox(height: 22),

                // CAMPO: TELÉFONO
                TextField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoracionCampo('Teléfono', Icons.phone_outlined),
                ),
                const SizedBox(height: 22),

                // CAMPO: FECHA DE NACIMIENTO
                InkWell(
                  onTap: _seleccionarFecha,
                  borderRadius: BorderRadius.circular(20),
                  child: InputDecorator(
                    decoration: _decoracionCampo('Fecha de nacimiento', Icons.calendar_today_outlined),
                    child: Text(
                      _fechaNacimiento != null
                          ? "${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}"
                          : "Seleccionar fecha",
                      style: TextStyle(
                        color: _fechaNacimiento != null ? Colors.white : Colors.white54,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: _acento),
                      )
                    : SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _guardarPerfil,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _acento,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'GUARDAR CAMBIOS',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }
}