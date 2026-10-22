import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/rutas.dart';
import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/tds_ui.dart';
import '../../domain/pasarela_pago.dart';
import '../../domain/tarjeta.dart';
import '../../providers/suscripcion_providers.dart';
import '../widgets/plan_widgets.dart';

/// Pago del plan con tarjeta (usa [PasarelaPago] a través de SuscripcionController).
/// Nota para el equipo: los datos completos de la tarjeta solo existen en el dispositivo;
/// a la base solo llegan marca y últimos 4 dígitos.
class PagoScreen extends ConsumerStatefulWidget {
  const PagoScreen({super.key, required this.plan});

  /// Id del plan en la tabla planes.
  final String plan;

  @override
  ConsumerState<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends ConsumerState<PagoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titular = TextEditingController();
  final _numero = TextEditingController();
  final _vencimiento = TextEditingController();
  final _cvv = TextEditingController();

  bool _procesando = false;

  /// El plan que se paga (de planesProvider; null mientras carga o si ya no está disponible).
  PlanInfo? get _plan {
    final base = ref.read(planesProvider).valueOrNull?.where((p) => p.id == widget.plan).firstOrNull;
    return base == null ? null : PlanInfo.desde(base);
  }

  @override
  void initState() {
    super.initState();
    for (final c in [_titular, _numero, _vencimiento]) {
      c.addListener(() => setState(() {})); // actualiza la vista previa de la tarjeta
    }
  }

  @override
  void dispose() {
    _titular.dispose();
    _numero.dispose();
    _vencimiento.dispose();
    _cvv.dispose();
    super.dispose();
  }

  Future<void> _pagar() async {
    if (_procesando) return; // evita doble cobro
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      Notificacion.error(context, 'No se pudo procesar el pago. Revisa los datos de tu tarjeta.',
          titulo: 'Pago rechazado');
      return;
    }

    setState(() => _procesando = true);
    try {
      final resultado = await ref.read(suscripcionControllerProvider).pagar(
            plan: _plan!.base!,
            tarjeta: DatosTarjeta(
              titular: _titular.text,
              numero: _numero.text,
              vencimiento: _vencimiento.text,
              cvv: _cvv.text,
            ),
          );
      // Los datos completos de la tarjeta se borran de memoria en cuanto se aprueba
      for (final c in [_titular, _numero, _vencimiento, _cvv]) {
        c.clear();
      }
      if (mounted) context.pushReplacement(Rutas.pagoResultado, extra: resultado);
    } catch (e) {
      if (!mounted) return;
      setState(() => _procesando = false);
      Notificacion.excepcion(context, e, titulo: 'Pago rechazado');
    }
  }

  @override
  Widget build(BuildContext context) {
    final planes = ref.watch(planesProvider);
    if (_plan == null) {
      return Scaffold(
        appBar: const TdsAppBar(titulo: 'PAGO SEGURO'),
        body: planes.isLoading
            ? const CargandoView()
            : planes.hasError
                ? ErrorView.desde(planes.error!, onReintentar: () => ref.invalidate(planesProvider))
                : const VacioView(icono: Icons.workspace_premium_outlined, texto: 'Este plan ya no está disponible'),
      );
    }

    return PopScope(
      canPop: !_procesando,
      child: Scaffold(
        appBar: const TdsAppBar(titulo: 'PAGO SEGURO'),
        body: Stack(
          children: [
            _buildFormulario(),
            if (_procesando) const Positioned.fill(child: ColoredBox(color: TdsColors.fondo, child: _Procesando())),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Formulario
  // ---------------------------------------------------------------------------
  Widget _buildFormulario() {
    final marca = marcaDe(_numero.text);

    return SingleChildScrollView(
      key: const ValueKey('formulario'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ResumenCompra(plan: _plan!),
                const SizedBox(height: 20),
                _VistaTarjeta(
                  numero: _numero.text,
                  titular: _titular.text,
                  vencimiento: _vencimiento.text,
                  marca: marca,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titular,
                  textCapitalization: TextCapitalization.characters,
                  autofillHints: const [AutofillHints.creditCardName],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del titular',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().length < 3) ? 'Escribe el nombre como aparece en la tarjeta' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _numero,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.creditCardNumber],
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, _NumeroTarjetaFormatter()],
                  decoration: InputDecoration(
                    labelText: 'Número de tarjeta',
                    hintText: '0000 0000 0000 0000',
                    prefixIcon: const Icon(Icons.credit_card),
                    suffixIcon: marca == MarcaTarjeta.desconocida
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Center(
                              widthFactor: 1,
                              child: Text(nombreMarca(marca), style: TdsText.label(12, color: TdsColors.primaryContainer)),
                            ),
                          ),
                  ),
                  validator: validarNumeroTarjeta,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _vencimiento,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.creditCardExpirationDate],
                        textInputAction: TextInputAction.next,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, _VencimientoFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Vencimiento',
                          hintText: 'MM/AA',
                          prefixIcon: Icon(Icons.event),
                        ),
                        validator: (v) => validarVencimiento(v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cvv,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        autofillHints: const [AutofillHints.creditCardSecurityCode],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _pagar(),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(largoCvv(marca)),
                        ],
                        decoration: const InputDecoration(labelText: 'CVV', prefixIcon: Icon(Icons.lock_outline)),
                        validator: (v) => validarCvv(v, marca),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  key: const Key('boton-pagar'),
                  onPressed: _procesando ? null : _pagar,
                  icon: const Icon(Icons.lock),
                  label: Text('PAGAR ${precioMensualTexto(_plan!)}'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 16, color: TdsColors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Pago cifrado. No guardamos los datos de tu tarjeta.',
                        textAlign: TextAlign.center,
                        style: TdsText.body(12, color: TdsColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in ['VISA', 'MASTERCARD', 'AMEX'])
                      TdsPill(child: Text(m, style: TdsText.label(10, color: TdsColors.onSurfaceVariant))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Q50"
String precioMensualTexto(PlanInfo plan) => Formatos.moneda(plan.precioMensual);

class _ResumenCompra extends StatelessWidget {
  const _ResumenCompra({required this.plan});

  final PlanInfo plan;

  @override
  Widget build(BuildContext context) {
    return TdsCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: plan.color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(Icons.workspace_premium, color: plan.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.nombre, style: TdsText.label(15)),
                Text('Suscripción mensual', style: TdsText.body(12, color: TdsColors.onSurfaceVariant)),
              ],
            ),
          ),
          Text(precioMensualTexto(plan), style: TdsText.stats(24, color: plan.color)),
          Text(' /mes', style: TdsText.body(12, color: TdsColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Vista previa de la tarjeta mientras se escribe.
class _VistaTarjeta extends StatelessWidget {
  const _VistaTarjeta({
    required this.numero,
    required this.titular,
    required this.vencimiento,
    required this.marca,
  });

  final String numero;
  final String titular;
  final String vencimiento;
  final MarcaTarjeta marca;

  @override
  Widget build(BuildContext context) {
    final digitos = soloDigitos(numero).padRight(largoNumero(marca), '•');
    final grupos = [for (var i = 0; i < digitos.length; i += 4) digitos.substring(i, min(i + 4, digitos.length))];

    return AspectRatio(
      aspectRatio: 1.7,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [TdsColors.surfaceContainerHighest, TdsColors.surfaceContainerLowest],
          ),
          border: Border.all(color: TdsColors.primaryContainer.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(color: TdsColors.primaryContainer.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sports_soccer, color: TdsColors.primaryContainer),
                const SizedBox(width: 6),
                Text('TDS SPORT', style: TdsText.label(13, color: TdsColors.primaryContainer, letterSpacing: 1.5)),
                const Spacer(),
                Text(nombreMarca(marca), style: TdsText.headline(18, weight: FontWeight.w700)),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(grupos.join('  '), style: TdsText.stats(24).copyWith(letterSpacing: 2)),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TITULAR', style: TdsText.label(9, color: TdsColors.onSurfaceVariant)),
                      Text(
                        titular.isEmpty ? 'NOMBRE APELLIDO' : titular.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: TdsText.label(13),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('VENCE', style: TdsText.label(9, color: TdsColors.onSurfaceVariant)),
                    Text(vencimiento.isEmpty ? 'MM/AA' : vencimiento, style: TdsText.label(13)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Procesando extends StatelessWidget {
  const _Procesando();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('procesando'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 56, height: 56, child: CircularProgressIndicator(strokeWidth: 4)),
          const SizedBox(height: 24),
          Text('Procesando tu pago…', style: TdsText.headline(20)),
          const SizedBox(height: 6),
          Text('No cierres esta pantalla.', style: TdsText.body(14, color: TdsColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// "4242424242424242" → "4242 4242 4242 4242" (máximo 16 dígitos).
class _NumeroTarjetaFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digitos = soloDigitos(newValue.text);
    final limite = largoNumero(marcaDe(digitos));
    final recortado = digitos.length > limite ? digitos.substring(0, limite) : digitos;
    final buffer = StringBuffer();
    for (var i = 0; i < recortado.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(recortado[i]);
    }
    final texto = buffer.toString();
    return TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));
  }
}

/// "1228" → "12/28"
class _VencimientoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var d = soloDigitos(newValue.text);
    if (d.length > 4) d = d.substring(0, 4);
    final texto = d.length > 2 ? '${d.substring(0, 2)}/${d.substring(2)}' : d;
    return TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));
  }
}
