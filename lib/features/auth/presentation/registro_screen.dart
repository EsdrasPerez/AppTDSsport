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
  bool _aceptoTerminos = false;

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
    if (!_aceptoTerminos) {
      Notificacion.advertencia(
        context,
        'Debes aceptar los Términos y Condiciones para crear tu cuenta.',
        titulo: 'Términos requeridos',
      );
      return;
    }
    setState(() => _cargando = true);

    try {
      final emailLimpio = _emailController.text.trim();
      final resultado = await ref.read(authRepositoryProvider).registrarUsuario(
            nombre: _nombreController.text,
            email: emailLimpio,
            password: _passwordController.text, // sin trim
          );
      if (!mounted) return;

      Notificacion.exito(
        context,
        'Cuenta creada exitosamente',
        titulo: '¡Bienvenido!',
      );

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: TdsColors.superficieAlta,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TdsColors.exito.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, color: TdsColors.exito, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¡Cuenta Creada!',
                  style: TdsText.headline(20),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resultado == ResultadoRegistro.confirmarCorreo
                    ? 'Te hemos enviado un enlace de confirmación a $emailLimpio. Por favor revisa tu bandeja de entrada o spam para activar tu cuenta antes de iniciar sesión.'
                    : 'Tu cuenta ha sido creada exitosamente. ¡Bienvenido a TDS Sport!',
                style: TdsText.body(14, color: TdsColors.onSurfaceVariant),
              ),
            ],
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: TdsColors.acento,
                foregroundColor: TdsColors.sobreAcento,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (resultado == ResultadoRegistro.confirmarCorreo && mounted) {
                  context.go(Rutas.login);
                }
              },
              child: Text(
                resultado == ResultadoRegistro.confirmarCorreo ? 'Ir a Iniciar Sesión' : 'Continuar',
                style: TdsText.label(14, color: TdsColors.sobreAcento),
              ),
            ),
          ],
        ),
      );

      if (mounted && resultado == ResultadoRegistro.confirmarCorreo) {
        context.go(Rutas.login);
      }
    } catch (e) {
      if (!mounted) return;
      final razon = Notificacion.mensajeDeExcepcion(e);

      Notificacion.error(
        context,
        'No se pudo crear la cuenta: $razon',
        titulo: 'Error al registrar',
      );

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: TdsColors.superficieAlta,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TdsColors.error.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline, color: TdsColors.error, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error al registrar',
                  style: TdsText.headline(18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TdsColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TdsColors.error.withValues(alpha: 0.3)),
                ),
                child: Text(
                  razon,
                  style: TdsText.body(13, color: TdsColors.onSurface),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Entendido', style: TdsText.label(14, color: TdsColors.acento)),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarTerminosYCondiciones() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: TdsColors.superficieAlta,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: TdsColors.acento.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.description_outlined, color: TdsColors.acento, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Términos y Condiciones', style: TdsText.headline(18)),
                          const SizedBox(height: 2),
                          Text('TDS Sport • Reglas y Políticas', style: TdsText.body(12, color: TdsColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: TdsColors.borde, height: 1),
              // Contenido scrollable
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _seccionTerminos(
                        '1. Naturaleza y Propósito del Servicio',
                        'TDS Sport es una plataforma deportiva enfocada en el entretenimiento, la creación y participación en quinielas comunitarias y el seguimiento de resultados de fútbol. Fomentamos una competencia sana, justa y transparente.',
                      ),
                      _seccionTerminos(
                        '2. Registro y Cuidado de la Cuenta',
                        'Al registrarte, te comprometes a proporcionar información veraz. Eres el único responsable de la seguridad de tus credenciales. Queda prohibida la creación de múltiples cuentas por un mismo usuario con fines de manipulación de tablas o abuso de beneficios.',
                      ),
                      _seccionTerminos(
                        '3. Reglas de Pronósticos y Cierre',
                        'Cada usuario puede ingresar sus pronósticos antes del pitazo inicial oficial de cada encuentro. Una vez iniciado el partido, el sistema bloquea automáticamente cualquier intento de edición para garantizar la equidad de todos los participantes.',
                      ),
                      _seccionTerminos(
                        '4. Planes y Membresías PRO / VIP',
                        'Las funciones avanzadas como quinielas ilimitadas, comparativas históricas y métricas detalladas están sujetas a los términos del plan adquirido. Las renovaciones y cancelaciones se gestionan desde el centro de suscripciones.',
                      ),
                      _seccionTerminos(
                        '5. Privacidad y Protección de Datos',
                        'Tus datos personales se encuentran protegidos mediante estándares de cifrado. No compartimos ni comercializamos tu información personal con terceros bajo ningún concepto.',
                      ),
                      _seccionTerminos(
                        '6. Conducta y Convivencia',
                        'Nos reservamos el derecho de sancionar o cancelar cuentas con comportamientos tóxicos, lenguaje inapropiado en apodos de quinielas o intentos de alteración de la plataforma.',
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(color: TdsColors.borde, height: 1),
              // Botones de acción
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: TdsColors.borde),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text('Cerrar', style: TdsText.label(13, color: TdsColors.onSurfaceVariant)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: TdsColors.acento,
                          foregroundColor: TdsColors.sobreAcento,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          setState(() => _aceptoTerminos = true);
                          Navigator.of(dialogContext).pop();
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: Text('Aceptar Términos', style: TdsText.label(13, color: TdsColors.sobreAcento)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccionTerminos(String titulo, String cuerpo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: TdsText.headline(14, color: TdsColors.acento)),
          const SizedBox(height: 4),
          Text(
            cuerpo,
            style: TdsText.body(13, color: TdsColors.onSurfaceVariant).copyWith(height: 1.4),
          ),
        ],
      ),
    );
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
              onSubmitted: (_) {
                if (_aceptoTerminos) _procesarRegistro();
              },
              validator: (v) => validarConfirmacion(v, _passwordController.text),
            ),
            const SizedBox(height: 20),
            // Checkbox para Términos y Condiciones
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _cargando
                  ? null
                  : () {
                      setState(() => _aceptoTerminos = !_aceptoTerminos);
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _aceptoTerminos,
                          activeColor: TdsColors.acento,
                          checkColor: TdsColors.sobreAcento,
                          side: const BorderSide(color: TdsColors.borde, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: _cargando
                              ? null
                              : (valor) {
                                  setState(() => _aceptoTerminos = valor ?? false);
                                },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'He leído y acepto los ',
                            style: TdsText.body(13, color: TdsColors.onSurfaceVariant),
                          ),
                          InkWell(
                            onTap: _mostrarTerminosYCondiciones,
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Términos y Condiciones',
                              style: TdsText.label(13, color: TdsColors.acento).copyWith(
                                decoration: TextDecoration.underline,
                                decorationColor: TdsColors.acento,
                              ),
                            ),
                          ),
                          Text(
                            ' de la plataforma.',
                            style: TdsText.body(13, color: TdsColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (_cargando || !_aceptoTerminos) ? null : _procesarRegistro,
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
