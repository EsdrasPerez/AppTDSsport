import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../../core/theme/tds_colors.dart';
import '../../../core/theme/tds_text.dart';
import '../../../core/widgets/tds_ui.dart';
import '../data/quinielas_repository.dart';
import '../providers/quinielas_acciones.dart';

/// Hoja "Unirse con código" (/quinielas/unirse?codigo=XXXX).
class UnirseQuinielaSheet extends ConsumerStatefulWidget {
  const UnirseQuinielaSheet({super.key, this.codigoInicial});

  final String? codigoInicial;

  @override
  ConsumerState<UnirseQuinielaSheet> createState() => _UnirseQuinielaSheetState();
}

class _UnirseQuinielaSheetState extends ConsumerState<UnirseQuinielaSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _codigoController = TextEditingController(text: _normalizar(widget.codigoInicial ?? ''));
  bool _uniendo = false;

  static String _normalizar(String texto) => texto
      .toUpperCase()
      .split('')
      .where(QuinielasRepository.alfabetoCodigo.contains)
      .take(QuinielasRepository.largoCodigo)
      .join();

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _unirse() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _uniendo = true);

    try {
      final id = await ref.read(quinielasAccionesProvider).unirse(_codigoController.text);
      if (!mounted) return;
      Notificacion.exito(context, 'Ya puedes hacer tus pronósticos.', titulo: '¡Te uniste a la quiniela!');
      context.go(Rutas.quiniela(id));
    } catch (e) {
      if (!mounted) return;
      setState(() => _uniendo = false);
      Notificacion.excepcion(context, e, titulo: 'No se pudo unir');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Unirse con código', style: TdsText.headline(22)),
              const SizedBox(height: 4),
              Text('Escribe el código de 5 dígitos que te compartieron.',
                  style: TdsText.body(13, color: TdsColors.onSurfaceVariant)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _codigoController,
                autofocus: widget.codigoInicial == null,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                style: TdsText.stats(28, color: TdsColors.primaryContainer).copyWith(letterSpacing: 6),
                inputFormatters: [_CodigoFormatter(_normalizar)],
                decoration: const InputDecoration(hintText: '12345'),
                validator: (v) =>
                    (v?.length ?? 0) == QuinielasRepository.largoCodigo ? null : 'El código debe tener 5 dígitos',
                onFieldSubmitted: (_) => _unirse(),
              ),
              const SizedBox(height: 24),
              TdsPillButton(
                icon: Icons.group_add_outlined,
                label: 'Unirme',
                primary: true,
                cargando: _uniendo,
                onTap: _unirse,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mayúsculas automáticas, sin espacios y solo con el alfabeto de los códigos.
class _CodigoFormatter extends TextInputFormatter {
  _CodigoFormatter(this._normalizar);

  final String Function(String) _normalizar;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final texto = _normalizar(newValue.text);
    return TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));
  }
}
