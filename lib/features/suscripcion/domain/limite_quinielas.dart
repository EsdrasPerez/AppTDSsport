import '../../../core/utils/errores.dart';
import 'plan_suscripcion.dart';

/// Plan Gratuito: hasta 5 quinielas activas creadas y hasta 5 de amigos (decisión del dueño).
const limiteGratisCrear = 5;
const limiteGratisUnirse = 5;

/// Cuántas quinielas activas puede tener el usuario según su plan.
/// Gratis: [crear] y [unirse] por separado. Con plan: [total] entre creadas y unidas (planes.limite_quinielas).
class LimiteQuinielas {
  const LimiteQuinielas.gratis()
      : plan = 'Plan Gratuito',
        total = null,
        crear = limiteGratisCrear,
        unirse = limiteGratisUnirse,
        permiteCrear = true,
        esGratis = true;

  LimiteQuinielas.dePlan(PlanSuscripcion p)
      : plan = p.nombre,
        total = p.limiteQuinielas,
        crear = null,
        unirse = null,
        permiteCrear = p.permiteCrearQuinielas,
        esGratis = false;

  final String plan;
  final int? total;
  final int? crear;
  final int? unirse;
  final bool permiteCrear;
  final bool esGratis;

  String get _mejora => esGratis ? ' Mejora tu plan en Suscripción para tener más.' : '';

  /// Lanza [MensajeUsuario] si con [creadas] y [unidas] quinielas activas ya no puede crear otra.
  void validarCrear({required int creadas, required int unidas}) {
    if (!permiteCrear) throw MensajeUsuario('Tu plan $plan no permite crear quinielas.');
    if (crear != null && creadas >= crear!) {
      throw MensajeUsuario('Con el $plan puedes crear hasta $crear quinielas activas y ya tienes $creadas.$_mejora');
    }
    _validarTotal(creadas + unidas);
  }

  /// Lanza [MensajeUsuario] si ya no puede unirse a otra quiniela.
  void validarUnirse({required int creadas, required int unidas}) {
    if (unirse != null && unidas >= unirse!) {
      throw MensajeUsuario(
          'Con el $plan puedes unirte hasta a $unirse quinielas activas de amigos y ya estás en $unidas.$_mejora');
    }
    _validarTotal(creadas + unidas);
  }

  void _validarTotal(int activas) {
    if (total != null && activas >= total!) {
      throw MensajeUsuario('Tu plan $plan permite hasta $total quinielas activas (creadas y de amigos) '
          'y ya tienes $activas.');
    }
  }
}
