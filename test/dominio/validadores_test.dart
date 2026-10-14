import 'package:flutter_test/flutter_test.dart';
import 'package:tdsport_app/core/utils/validadores.dart';

void main() {
  test('la contraseña exige lo que dice el texto: 8+, número y símbolo (B5)', () {
    expect(validarContrasenaNueva('abc12!'), isNotNull); // 6 caracteres
    expect(validarContrasenaNueva('abcdefg!'), isNotNull); // sin número
    expect(validarContrasenaNueva('abcdefg1'), isNotNull); // sin símbolo
    expect(validarContrasenaNueva('abcdef1!'), isNull);
  });

  test('los espacios son parte de la contraseña (B6)', () {
    expect(validarConfirmacion('Clave12! ', 'Clave12!'), isNotNull);
    expect(validarConfirmacion('Clave12! ', 'Clave12! '), isNull);
  });

  test('el indicador usa las mismas reglas', () {
    expect(nivelContrasena('abc'), NivelContrasena.debil);
    expect(nivelContrasena('abcdefg1'), NivelContrasena.media);
    expect(nivelContrasena('abcdef1!'), NivelContrasena.fuerte);
  });

  test('correo', () {
    expect(validarCorreo('ana@test.com'), isNull);
    expect(validarCorreo(' ana@test.com '), isNull);
    expect(validarCorreo('ana@'), isNotNull);
    expect(validarCorreo(''), isNotNull);
  });
}
