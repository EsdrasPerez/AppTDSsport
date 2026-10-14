/// Rutas de la app. Nunca escribir rutas como strings sueltos.
class Rutas {
  Rutas._();

  static const login = '/login';
  static const registro = '/registro';
  static const recuperar = '/recuperar';

  static const inicio = '/inicio';
  static const partidos = '/partidos';
  static const calendario = '/calendario';
  static const quinielas = '/quinielas';
  static const quinielaNueva = '/quinielas/nueva';
  static const quinielaUnirse = '/quinielas/unirse';
  static const misPronosticos = '/mis-pronosticos';
  static const rivales = '/rivales';
  static const perfil = '/perfil';
  static const historial = '/perfil/historial';
  static const suscripcion = '/suscripcion';
  static const pagoResultado = '/suscripcion/pago/resultado';

  static const admin = '/admin';
  static const adminTorneos = '/admin/torneos';
  static const adminEquipos = '/admin/equipos';
  static const adminPartidos = '/admin/partidos';

  /// Con [partidoId] abre Pendientes en ese partido, resaltado y listo para poner los goles.
  static String quiniela(String id, {bool soloLectura = false, String? partidoId}) => Uri(
        path: '/quinielas/$id',
        queryParameters: {if (soloLectura) 'lectura': '1', 'partido': ?partidoId},
      ).toString();

  static String participante(String quinielaId, String usuarioId) =>
      '/quinielas/$quinielaId/participante/$usuarioId';

  static String unirseConCodigo(String codigo) => '$quinielaUnirse?codigo=$codigo';

  /// Las quinielas siempre son de un torneo; con [torneoId] llega preseleccionado.
  static String crearQuiniela({String? torneoId}) =>
      Uri(path: quinielaNueva, queryParameters: {'torneo': ?torneoId}).toString();

  static String partidosEnVivo() => '$partidos?tab=envivo';

  static String misPronosticosPendientes() => '$misPronosticos?filtro=pendientes';

  static String rivalesDe({String? quinielaId, String? partidoId}) =>
      Uri(path: rivales, queryParameters: {'quiniela': ?quinielaId, 'partido': ?partidoId}).toString();

  /// Pantalla de pago con tarjeta. [plan]: 'pro' o 'vip'.
  static String pago(String plan) => '/suscripcion/pago?plan=$plan';

  /// Rutas a las que se puede entrar sin sesión.
  static const publicas = {login, registro, recuperar};
}
