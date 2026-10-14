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

/// Recuperar contraseña (/recuperar). El mensaje es neutro: no revela si la cuenta existe.
class RecuperarScreen extends ConsumerStatefulWidget {
  const RecuperarScreen({super.key});

  @override
  ConsumerState<RecuperarScreen> createState() => _RecuperarScreenState();
}

class _RecuperarScreenState extends ConsumerState<RecuperarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _cargando = false;
  bool _enviado = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      // TODO(decision): configurar redirectTo con la URL de la pantalla para cambiar la contraseña.
      await ref.read(authRepositoryProvider).recuperarContrasena(_emailController.text);
      if (mounted) setState(() => _enviado = true);
    } catch (e) {
      if (mounted) Notificacion.excepcion(context, e, titulo: 'No se pudo enviar');
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
            Text('Recuperar contraseña', textAlign: TextAlign.center, style: TdsText.headline(24)),
            const SizedBox(height: 8),
            Text(
              _enviado
                  ? 'Si el correo existe, te enviamos un enlace para restablecer tu contraseña. Revisa también tu carpeta de spam.'
                  : 'Escribe el correo de tu cuenta y te enviaremos un enlace para restablecerla.',
              textAlign: TextAlign.center,
              style: TdsText.body(14, color: TdsColors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            if (!_enviado) ...[
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _enviar(),
                decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.email_outlined)),
                validator: validarCorreo,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _cargando ? null : _enviar,
                child: _cargando
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('ENVIAR ENLACE'),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(onPressed: () => context.go(Rutas.login), child: const Text('Volver a iniciar sesión')),
          ],
        ),
      ),
    );
  }
}
