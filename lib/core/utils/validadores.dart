/// Validaciones de formularios. Una sola fuente de verdad para login, registro y recuperar.
library;

enum NivelContrasena { debil, media, fuerte }

final _regexCorreo = RegExp(r'^[\w\-.+]+@([\w-]+\.)+[\w-]{2,}$');
final _regexNumero = RegExp(r'[0-9]');
final _regexSimbolo = RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=;'/\\\[\]~`]''');

const minimoContrasena = 8;
const textoReglasContrasena = 'Mínimo 8 caracteres, al menos un número y un símbolo.';

String? validarCorreo(String? valor) {
  final v = valor?.trim() ?? '';
  if (v.isEmpty) return 'El correo es requerido';
  if (!_regexCorreo.hasMatch(v)) return 'Ingresa un correo válido';
  return null;
}

String? validarRequerido(String? valor, String mensaje) =>
    (valor == null || valor.trim().isEmpty) ? mensaje : null;

/// Exige lo mismo que dice [textoReglasContrasena]. No recorta espacios.
String? validarContrasenaNueva(String? valor) {
  final v = valor ?? '';
  if (v.isEmpty) return 'La contraseña es requerida';
  if (v.length < minimoContrasena) return 'Mínimo $minimoContrasena caracteres';
  if (!_regexNumero.hasMatch(v)) return 'Debe contener al menos un número';
  if (!_regexSimbolo.hasMatch(v)) return 'Debe contener al menos un símbolo';
  return null;
}

String? validarConfirmacion(String? valor, String original) {
  if (valor == null || valor.isEmpty) return 'Confirma tu contraseña';
  if (valor != original) return 'Las contraseñas no coinciden';
  return null;
}

/// Indicador visual. "Fuerte" solo si cumple todas las reglas de [validarContrasenaNueva].
NivelContrasena nivelContrasena(String v) {
  if (validarContrasenaNueva(v) == null) return NivelContrasena.fuerte;
  final cumple = [
    v.length >= minimoContrasena,
    _regexNumero.hasMatch(v),
    _regexSimbolo.hasMatch(v),
  ].where((c) => c).length;
  return cumple >= 2 ? NivelContrasena.media : NivelContrasena.debil;
}
