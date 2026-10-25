import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../../core/theme/tds_colors.dart';
import '../../../core/theme/tds_text.dart';
import '../../../core/widgets/tds_ui.dart';
import '../../auth/providers/auth_providers.dart';
import '../domain/perfil.dart';
import '../providers/perfil_providers.dart';
import 'widgets/historial_resumen.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  final _nameController = TextEditingController();
  final _telefonoController = TextEditingController();

  DateTime? _fechaNacimiento;
  bool _tieneFechaNacimiento = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosUsuario() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await ref.read(perfilRepositoryProvider).obtenerDatosEditables(user.id);

      if (response != null && mounted) {
        setState(() {
          _tieneFechaNacimiento = response.containsKey('fecha_nacimiento');
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
            primary: TdsColors.acento,
            surface: TdsColors.superficie,
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
      await ref.read(perfilRepositoryProvider).actualizarPerfil(
            usuarioId: user.id,
            nombre: _nameController.text.trim(),
            telefono: _telefonoController.text.trim(),
            fechaNacimiento: _fechaNacimiento,
            conFechaNacimiento: _tieneFechaNacimiento,
          );
      ref.invalidate(perfilActualProvider);

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
    await ref.read(authRepositoryProvider).cerrarSesion();
    if (mounted) {
      context.go(Rutas.login);
    }
  }

  Future<void> _confirmarCerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TdsColors.superficie,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Cerrar sesión?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Tendrás que volver a iniciar sesión para acceder a tus quinielas y pronósticos.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión', style: TextStyle(color: TdsColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      _cerrarSesion();
    }
  }

  void _mostrarDialogoCambiarContrasena(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: const _ModalCambiarContrasena(),
        ),
      ),
    );
  }

  String _obtenerIniciales(String? nombre, String? email) {
    final texto = (nombre != null && nombre.trim().isNotEmpty) ? nombre.trim() : (email ?? 'U');
    final partes = texto.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return 'U';
    if (partes.length == 1) return partes.first.substring(0, partes.first.length >= 2 ? 2 : 1).toUpperCase();
    return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
  }

  InputDecoration _decoracionCampo(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: TdsColors.fondo,
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
        borderSide: const BorderSide(color: TdsColors.acento),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final perfil = ref.watch(perfilActualProvider).valueOrNull;

    return Scaffold(
      backgroundColor: TdsColors.fondo,
      appBar: AppBar(
        backgroundColor: TdsColors.superficie,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Mi Perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: TdsColors.error),
            tooltip: 'Cerrar sesión',
            onPressed: _confirmarCerrarSesion,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TARJETA PRINCIPAL: DATOS PERSONALES
                Container(
                  padding: const EdgeInsets.all(28.0),
                  decoration: BoxDecoration(
                    color: TdsColors.superficie,
                    borderRadius: BorderRadius.circular(32.0),
                    border: Border.all(color: TdsColors.borde.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar con Iniciales y Borde Lima
                      Center(
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: TdsColors.superficieAlta,
                            shape: BoxShape.circle,
                            border: Border.all(color: TdsColors.acento, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: TdsColors.acento.withValues(alpha: 0.15),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _obtenerIniciales(
                              _nameController.text.isNotEmpty ? _nameController.text : perfil?.nombre,
                              user?.email,
                            ),
                            style: const TextStyle(
                              color: TdsColors.acento,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _nameController.text.isNotEmpty ? _nameController.text : (perfil?.nombre ?? 'Mi Perfil'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(fontSize: 13, color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),

                      // Insignia del Plan
                      if (perfil != null) ...[
                        const SizedBox(height: 10),
                        Center(
                          child: TdsPill(
                            color: perfil.plan == PlanUsuario.vip
                                ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                                : (perfil.plan == PlanUsuario.pro
                                    ? TdsColors.acento.withValues(alpha: 0.2)
                                    : TdsColors.surfaceContainerHigh),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  perfil.plan == PlanUsuario.vip
                                      ? Icons.stars
                                      : (perfil.plan == PlanUsuario.pro ? Icons.verified : Icons.account_circle_outlined),
                                  size: 13,
                                  color: perfil.plan == PlanUsuario.vip
                                      ? const Color(0xFFFFD700)
                                      : (perfil.plan == PlanUsuario.pro ? TdsColors.acento : TdsColors.textoSecundario),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'PLAN ${perfil.plan.etiqueta.toUpperCase()}',
                                  style: TdsText.label(
                                    11,
                                    color: perfil.plan == PlanUsuario.vip
                                        ? const Color(0xFFFFD700)
                                        : (perfil.plan == PlanUsuario.pro ? TdsColors.acento : TdsColors.textoSecundario),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => _mostrarDialogoCambiarContrasena(context),
                          icon: const Icon(Icons.lock_reset, size: 16, color: TdsColors.acento),
                          label: const Text(
                            'Cambiar contraseña',
                            style: TextStyle(
                              color: TdsColors.acento,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            backgroundColor: TdsColors.acento.withValues(alpha: 0.12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // CAMPO: NOMBRE
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _decoracionCampo('Nombre completo', Icons.badge_outlined),
                      ),
                      const SizedBox(height: 18),

                      // CAMPO: TELÉFONO
                      TextField(
                        controller: _telefonoController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: _decoracionCampo('Teléfono', Icons.phone_outlined),
                      ),
                      const SizedBox(height: 18),

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

                      const SizedBox(height: 26),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator(color: TdsColors.acento))
                          : SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _guardarPerfil,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TdsColors.acento,
                                  foregroundColor: TdsColors.sobreAcento,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: const Text(
                                  'GUARDAR CAMBIOS',
                                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // TARJETA DE SEGURIDAD Y ACCESO
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: TdsColors.superficie,
                    borderRadius: BorderRadius.circular(28.0),
                    border: Border.all(color: TdsColors.borde.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: TdsColors.acento, size: 20),
                          const SizedBox(width: 8),
                          Text('Cuenta y Sesión', style: TdsText.headline(16, weight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.logout, size: 18, color: TdsColors.error),
                        label: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TdsColors.error,
                          side: BorderSide(color: TdsColors.error.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: _confirmarCerrarSesion,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // HISTORIAL DE QUINIELAS
                const HistorialResumen(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal inferior para cambiar la contraseña con validaciones.
class _ModalCambiarContrasena extends ConsumerStatefulWidget {
  const _ModalCambiarContrasena();

  @override
  ConsumerState<_ModalCambiarContrasena> createState() => _ModalCambiarContrasenaState();
}

class _ModalCambiarContrasenaState extends ConsumerState<_ModalCambiarContrasena> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _cambiar() async {
    final pass = _passwordController.text;
    final confirm = _confirmController.text;

    if (pass.length < 6) {
      Notificacion.advertencia(
        context,
        'La nueva contraseña debe tener al menos 6 caracteres.',
        titulo: 'Contraseña muy corta',
      );
      return;
    }

    if (pass != confirm) {
      Notificacion.advertencia(
        context,
        'Las contraseñas no coinciden. Por favor verifica ambos campos.',
        titulo: 'No coinciden',
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await ref.read(authRepositoryProvider).cambiarContrasena(pass);
      if (mounted) {
        Navigator.pop(context);
        Notificacion.exito(
          context,
          'Tu contraseña se actualizó correctamente.',
          titulo: 'Contraseña cambiada',
        );
      }
    } catch (e) {
      if (mounted) {
        Notificacion.excepcion(context, e, titulo: 'Error al cambiar');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TdsColors.superficie,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: TdsColors.borde.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TdsColors.acento.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset, color: TdsColors.acento, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cambiar contraseña', style: TdsText.headline(18, weight: FontWeight.w700)),
                    Text(
                      'Ingresa tu nueva contraseña para proteger tu cuenta',
                      style: TdsText.body(12, color: TdsColors.textoSecundario),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                tooltip: 'Cerrar',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePass,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Nueva contraseña',
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white70,
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
              filled: true,
              fillColor: TdsColors.fondo,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: TdsColors.acento),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Confirmar nueva contraseña',
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white70,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              filled: true,
              fillColor: TdsColors.fondo,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: TdsColors.acento),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _loading
              ? const Center(child: CircularProgressIndicator(color: TdsColors.acento))
              : SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _cambiar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TdsColors.acento,
                      foregroundColor: TdsColors.sobreAcento,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: const Text(
                      'ACTUALIZAR CONTRASEÑA',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}