import 'package:flutter_test/flutter_test.dart';
import 'package:tdsport_app/features/suscripcion/domain/tarjeta.dart';

void main() {
  test('marca y Luhn', () {
    expect(marcaDe('4242 4242 4242 4242'), MarcaTarjeta.visa);
    expect(marcaDe('5555555555554444'), MarcaTarjeta.mastercard);
    expect(marcaDe('378282246310005'), MarcaTarjeta.amex);
    expect(validarNumeroTarjeta('4242 4242 4242 4242'), isNull);
    expect(validarNumeroTarjeta('4242 4242 4242 4241'), isNotNull); // dígito verificador malo
    expect(validarNumeroTarjeta('6011 1111 1111 1117'), isNotNull); // marca no aceptada
  });

  test('vencimiento', () {
    final hoy = DateTime(2026, 10, 13);
    expect(validarVencimiento('10/26', ahora: hoy), isNull);
    expect(validarVencimiento('09/26', ahora: hoy), isNotNull);
    expect(validarVencimiento('13/27', ahora: hoy), isNotNull);
    expect(validarVencimiento('1227', ahora: hoy), isNotNull);
  });

  test('CVV según marca y enmascarado', () {
    expect(validarCvv('123', MarcaTarjeta.visa), isNull);
    expect(validarCvv('123', MarcaTarjeta.amex), isNotNull);
    expect(enmascarar('4242 4242 4242 4242'), '•••• 4242');
  });
}
