import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../../core/theme/tds_colors.dart';
import '../../../core/theme/tds_text.dart';
import '../../../core/utils/validadores.dart';
import '../../../core/widgets/notificacion.dart';
import '../data/auth_repository.dart';
import '../providers/auth_providers.dart';
import 'widgets/auth_layout.dart';

class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> _procesarRegistro() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    try {
      final resultado = await ref.read(authRepositoryProvider).registrarUsuario(
            nombre: _nombreController.text,
            email: _emailController.text,
            password: _passwordController.text, // sin trim
          );
      if (!mounted) return;

      if (resultado == ResultadoRegistro.confirmarCorreo) {
        // Confirmación de correo activa: no hay sesión todavía
        Notificacion.info(
          context,
          'Te enviamos un enlace a ${_emailController.text.trim()}. Confírmalo y luego inicia sesión.',
          titulo: 'Revisa tu correo',
        );
        context.go(Rutas.login);
      } else {
        // Con sesión, el redirect del router lleva a Inicio
        Notificacion.exito(context, '¡Bienvenido a TDS Sport!', titulo: 'Cuenta creada');
      }
    } catch (e) {
      if (mounted) Notificacion.excepcion(context, e, titulo: 'No se pudo crear la cuenta');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Únete a la liga. Domina las predicciones.',
                textAlign: TextAlign.center, style: TdsText.headline(20)),
            const SizedBox(height: 28),
            TextFormField(
              controller: _nombreController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                hintText: 'Ej. Carlos Silva',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => validarRequerido(v, 'El nombre es requerido'),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                hintText: 'atleta@dominio.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: validarCorreo,
            ),
            const SizedBox(height: 20),
            CampoContrasena(
              controller: _passwordController,
              label: 'Contraseña segura',
              textInputAction: TextInputAction.next,
              validator: validarContrasenaNueva,
            ),
            _IndicadorSeguridad(controller: _passwordController),
            const SizedBox(height: 12),
            CampoContrasena(
              controller: _confirmarPasswordController,
              label: 'Confirma tu contraseña',
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _procesarRegistro(),
              validator: (v) => validarConfirmacion(v, _passwordController.text),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _cargando ? null : _procesarRegistro,
              child: _cargando
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text('Registrarse'), SizedBox(width: 8), Icon(Icons.arrow_forward, size: 20)],
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('¿Ya tienes cuenta?', style: TdsText.body(14, color: TdsColors.onSurfaceVariant)),
                TextButton(onPressed: () => context.go(Rutas.login), child: const Text('Inicia sesión')),
              ],
            ),
            // TODO(decision): D5 — botón "Continuar con Google" oculto hasta implementar signInWithOAuth.
            const SizedBox(height: 16),
            Text(
              'Al registrarte, aceptas nuestros Términos de Servicio y Política de Privacidad.',
              textAlign: TextAlign.center,
              style: TdsText.body(12, color: TdsColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indicador visual que usa las MISMAS reglas que el validador.
class _IndicadorSeguridad extends StatelessWidget {
  const _IndicadorSeguridad({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final nivel = nivelContrasena(value.text);
        final (texto, color, progreso) = switch (nivel) {
          NivelContrasena.debil => ('Débil', TdsColors.error, 0.33),
          NivelContrasena.media => ('Media', TdsColors.advertencia, 0.66),
          NivelContrasena.fuerte => ('Fuerte', TdsColors.primaryContainer, 1.0),
        };

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (value.text.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progreso,
                    minHeight: 4,
                    color: color,
                    backgroundColor: TdsColors.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Seguridad de la contraseña: $texto', style: TdsText.label(12, color: color)),
              ],
              Text(textoReglasContrasena, style: TdsText.body(11, color: TdsColors.onSurfaceVariant)),
            ],
          ),
        );
      },
    );
  }
}
