import 'package:flutter_test/flutter_test.dart';
import 'package:tdsport_app/core/utils/formatos.dart';
import 'package:tdsport_app/features/partidos/domain/partido.dart';
import 'package:tdsport_app/features/perfil/domain/perfil.dart';
import 'package:tdsport_app/features/suscripcion/domain/pasarela_pago.dart';
import 'package:tdsport_app/features/suscripcion/domain/precios.dart';


void main() {
  test('visibilidad de rivales: próximos, en juego y finalizados; nunca suspendidos', () {
    // Misma regla que la RLS (estado_id IN (1, 2, 3)) y que el filtro de la pantalla
    bool visible(EstadoPartido e) => e != EstadoPartido.suspendido;
    expect(EstadoPartido.values.where(visible).map((e) => e.id), [1, 2, 3]);
  });

  group('Plan del perfil', () {
    test('es_pro sin columna plan se interpreta como PRO', () {
      final p = Perfil.fromMap({'id': 'x', 'nombre': 'Ana López', 'es_pro': true});
      expect(p.plan, PlanUsuario.pro);
      expect(p.esPro, isTrue);
      expect(p.primerNombre, 'Ana');
    });

    test('un plan vencido ya no es PRO', () {
      final p = Perfil.fromMap({
        'id': 'x',
        'nombre': 'Ana',
        'es_pro': true,
        'plan': 'VIP',
        'plan_vence_en': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      });
      expect(p.esPro, isFalse);
      expect(p.planVigente, PlanUsuario.gratis);
    });
  });

  test('precios en quetzales', () {
    expect(Formatos.moneda(precioProMensual), 'Q50');
    expect(Formatos.moneda(precioVipMensual), 'Q100');
    expect(precioPorMes(precioProMensual), 'Q50 / mes');
    expect(precioDe(PlanUsuario.vip), 100);
  });

  test('a la base solo llegan marca y últimos 4 dígitos', () {
    const t = DatosTarjeta(titular: 'ANA LOPEZ', numero: '4242 4242 4242 4242', vencimiento: '12/30', cvv: '123');
    expect(t.validar(), isNull);
    expect(t.ultimos4, '4242');
    const mala = DatosTarjeta(titular: 'ANA LOPEZ', numero: '4242 4242 4242 4241', vencimiento: '12/30', cvv: '123');
    expect(mala.validar(), isNotNull);
  });
}
