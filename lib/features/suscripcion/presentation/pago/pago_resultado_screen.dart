import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/rutas.dart';
import '../../../../core/theme/tds_colors.dart';
import '../../../../core/theme/tds_text.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/tds_ui.dart';
import '../../domain/pasarela_pago.dart';
import '../../domain/tarjeta.dart';

/// Pago aprobado (/suscripcion/pago/resultado). Recibe el [ResultadoPago] por `extra`.
class PagoResultadoScreen extends StatelessWidget {
  const PagoResultadoScreen({super.key, required this.resultado});

  final ResultadoPago? resultado;

  @override
  Widget build(BuildContext context) {
    final r = resultado;
    if (r == null) {
      // Se entró por URL sin un pago: no hay nada que mostrar
      return Scaffold(
        appBar: const TdsAppBar(titulo: 'PAGO'),
        body: VacioView(
          icono: Icons.receipt_long,
          texto: 'No hay un pago reciente para mostrar.',
          acciones: [
            TdsPillButton(icon: Icons.star_border, label: 'Ver planes', onTap: () => context.go(Rutas.suscripcion)),
          ],
        ),
      );
    }

    Widget fila(String etiqueta, String valor) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(etiqueta, style: TdsText.body(14, color: TdsColors.textoSecundario))),
              Text(valor, style: TdsText.label(14)),
            ],
          ),
        );

    return Scaffold(
      appBar: const TdsAppBar(titulo: 'PAGO APROBADO'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(color: TdsColors.exito.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle, color: TdsColors.exito, size: 56),
                  ),
                ),
                const SizedBox(height: 16),
                Text('¡Pago aprobado!', textAlign: TextAlign.center, style: TdsText.headline(28)),
                const SizedBox(height: 4),
                Text('Tu plan ${r.plan.etiqueta} ya está activo.',
                    textAlign: TextAlign.center, style: TdsText.body(14, color: TdsColors.textoSecundario)),
                const SizedBox(height: 24),
                TdsCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      fila('Referencia', r.referencia),
                      fila('Plan', r.plan.etiqueta),
                      fila('Monto', '${Formatos.moneda(r.monto)} / mes'),
                      fila('Tarjeta', '${nombreMarca(r.marca)} •••• ${r.ultimos4}'),
                      fila('Fecha', '${Formatos.fecha(r.fecha)} ${Formatos.hora(r.fecha)}'),
                      const Divider(height: 24),
                      fila('Próximo cobro', Formatos.fecha(r.venceEn)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.go(Rutas.rivales),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('IR A PRONÓSTICOS DE RIVALES'),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: () => context.go(Rutas.suscripcion), child: const Text('Ver mi suscripción')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
