/// Validación de datos de tarjeta (solo en el dispositivo).
/// IMPORTANTE (equipo): el cobro es simulado. Los datos de la tarjeta NUNCA se guardan
/// ni se envían a ningún servidor; solo se validan aquí y en el recibo se muestran los últimos 4 dígitos.
library;

enum MarcaTarjeta { visa, mastercard, amex, desconocida }

String soloDigitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');

MarcaTarjeta marcaDe(String numero) {
  final n = soloDigitos(numero);
  if (n.startsWith('4')) return MarcaTarjeta.visa;
  if (RegExp(r'^3[47]').hasMatch(n)) return MarcaTarjeta.amex;
  if (RegExp(r'^5[1-5]').hasMatch(n)) return MarcaTarjeta.mastercard;
  if (n.length >= 4) {
    final prefijo = int.parse(n.substring(0, 4));
    if (prefijo >= 2221 && prefijo <= 2720) return MarcaTarjeta.mastercard;
  }
  return MarcaTarjeta.desconocida;
}

String nombreMarca(MarcaTarjeta m) => switch (m) {
      MarcaTarjeta.visa => 'VISA',
      MarcaTarjeta.mastercard => 'MASTERCARD',
      MarcaTarjeta.amex => 'AMEX',
      MarcaTarjeta.desconocida => '',
    };

int largoNumero(MarcaTarjeta m) => m == MarcaTarjeta.amex ? 15 : 16;
int largoCvv(MarcaTarjeta m) => m == MarcaTarjeta.amex ? 4 : 3;

/// Algoritmo de Luhn (dígito verificador de las tarjetas).
bool pasaLuhn(String numero) {
  final n = soloDigitos(numero);
  if (n.isEmpty) return false;
  var suma = 0;
  var doble = false;
  for (var i = n.length - 1; i >= 0; i--) {
    var d = int.parse(n[i]);
    if (doble) {
      d *= 2;
      if (d > 9) d -= 9;
    }
    suma += d;
    doble = !doble;
  }
  return suma % 10 == 0;
}

String? validarNumeroTarjeta(String? valor) {
  final n = soloDigitos(valor ?? '');
  if (n.isEmpty) return 'Ingresa el número de la tarjeta';
  final marca = marcaDe(n);
  if (marca == MarcaTarjeta.desconocida) return 'Aceptamos Visa, Mastercard y American Express';
  if (n.length != largoNumero(marca) || !pasaLuhn(n)) return 'Número de tarjeta inválido';
  return null;
}

/// "MM/AA", no vencida.
String? validarVencimiento(String? valor, {DateTime? ahora}) {
  final m = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(valor ?? '');
  if (m == null) return 'Usa el formato MM/AA';
  final mes = int.parse(m.group(1)!);
  final anio = 2000 + int.parse(m.group(2)!);
  if (mes < 1 || mes > 12) return 'Mes inválido';
  final hoy = ahora ?? DateTime.now();
  // Vale hasta el último día del mes indicado
  if (anio < hoy.year || (anio == hoy.year && mes < hoy.month)) return 'La tarjeta está vencida';
  return null;
}

String? validarCvv(String? valor, MarcaTarjeta marca) {
  final n = soloDigitos(valor ?? '');
  return n.length == largoCvv(marca) ? null : 'CVV de ${largoCvv(marca)} dígitos';
}

/// "•••• 4242"
String enmascarar(String numero) {
  final n = soloDigitos(numero);
  return n.length < 4 ? '••••' : '•••• ${n.substring(n.length - 4)}';
}
