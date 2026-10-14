import 'package:intl/intl.dart';

/// Formatos de fecha, hora y moneda (español).
class Formatos {
  Formatos._();

  static final _hora = DateFormat('HH:mm');
  static final _diaMes = DateFormat('dd/MM');
  static final _fechaCompleta = DateFormat('dd/MM/yyyy');

  static DateTime _soloFecha(DateTime f) => DateTime(f.year, f.month, f.day);

  /// "21:00"
  static String hora(DateTime? fecha) => fecha == null ? '--:--' : _hora.format(fecha);

  /// "Hoy", "Mañana", "Ayer" o "13/10"
  static String dia(DateTime? fecha) {
    if (fecha == null) return 'Por definir';
    final dif = _soloFecha(fecha).difference(_soloFecha(DateTime.now())).inDays;
    return switch (dif) {
      0 => 'Hoy',
      1 => 'Mañana',
      -1 => 'Ayer',
      _ => _diaMes.format(fecha),
    };
  }

  /// "Hoy 21:00"
  static String diaHora(DateTime? fecha) => '${dia(fecha)} ${hora(fecha)}';

  /// "13/10"
  static String diaMes(DateTime? fecha) => fecha == null ? '--/--' : _diaMes.format(fecha);

  /// "13/10/2026"
  static String fecha(DateTime? fecha) => fecha == null ? '--' : _fechaCompleta.format(fecha);

  /// "Inicia en 1h 45m" si falta menos de un día; si no, null.
  static String? cuentaRegresiva(DateTime? fecha) {
    if (fecha == null) return null;
    final falta = fecha.difference(DateTime.now());
    if (falta.isNegative || falta.inHours >= 24) return null;
    final h = falta.inHours;
    final m = falta.inMinutes % 60;
    return h > 0 ? 'Inicia en ${h}h ${m}m' : 'Inicia en ${m}m';
  }

  /// "hace 5 min", "hace 3 h", "13/10"
  static String relativo(DateTime? fecha) {
    if (fecha == null) return '--';
    final dif = DateTime.now().difference(fecha);
    if (dif.inMinutes < 1) return 'ahora';
    if (dif.inMinutes < 60) return 'hace ${dif.inMinutes} min';
    if (dif.inHours < 24) return 'hace ${dif.inHours} h';
    return diaMes(fecha);
  }

  // intl no trae datos de es_GT (cae en "es", que pone el símbolo al final: "50 Q").
  // El patrón explícito deja el formato guatemalteco: "Q50", "Q1,200".
  static final _moneda =
      NumberFormat.currency(locale: 'en_US', symbol: 'Q', decimalDigits: 0, customPattern: '¤#,##0');

  /// "Q50"
  static String moneda(num monto) => _moneda.format(monto);
}
