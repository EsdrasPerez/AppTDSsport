import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../../core/theme/tds_colors.dart';
import '../../../core/theme/tds_text.dart';
import '../../../core/utils/validadores.dart';
import '../../../core/widgets/notificacion.dart';
import '../providers/auth_providers.dart';
import 'widgets/auth_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _cargando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _procesarLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    try {
      // La contraseña va tal cual (sin trim). Al iniciar sesión, el redirect del router
      // lleva a Inicio (o a la ruta de ?desde=): esta pantalla no navega a mano.
      await ref.read(authRepositoryProvider).iniciarSesion(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } catch (e) {
      if (mounted) Notificacion.excepcion(context, e, titulo: 'No se pudo iniciar sesión');
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
            Text('Bienvenido', textAlign: TextAlign.center, style: TdsText.headline(26)),
            const SizedBox(height: 30),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.email_outlined)),
              validator: validarCorreo,
            ),
            const SizedBox(height: 22),
            CampoContrasena(
              controller: _passwordController,
              label: 'Contraseña',
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _procesarLogin(),
              validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(Rutas.recuperar),
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargando ? null : _procesarLogin,
              child: _cargando
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('ENTRAR'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('¿No tienes cuenta?', style: TdsText.body(14, color: TdsColors.onSurfaceVariant)),
                TextButton(onPressed: () => context.go(Rutas.registro), child: const Text('Regístrate')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
