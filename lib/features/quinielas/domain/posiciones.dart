/// Lugares de una tabla con empates compartidos (1, 2, 2, 4).
/// Solo ordena los puntos que vienen de la base; no los calcula.
library;

// Respaldo cuando la vista v_posiciones (migración 02) no existe; también da el lugar en ResumenQuiniela.

/// Lugar de quien tiene [puntos] entre todos los [puntosDeTodos].
int lugarDe(int puntos, Iterable<int> puntosDeTodos) => 1 + puntosDeTodos.where((p) => p > puntos).length;

/// Lugares para una lista YA ordenada de mayor a menor.
List<int> calcularLugares(List<int> puntosOrdenados) {
  final lugares = <int>[];
  for (var i = 0; i < puntosOrdenados.length; i++) {
    final empate = i > 0 && puntosOrdenados[i] == puntosOrdenados[i - 1];
    lugares.add(empate ? lugares[i - 1] : i + 1);
  }
  return lugares;
}
