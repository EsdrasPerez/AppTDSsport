/// Minúsculas y sin acentos, para buscar sin distinguir "Máquina" de "maquina".
String sinAcentos(String s) {
  const de = 'áéíóúüñ';
  const a = 'aeiouun';
  final minus = s.toLowerCase();
  return String.fromCharCodes(minus.runes.map((r) {
    final i = de.indexOf(String.fromCharCode(r));
    return i < 0 ? r : a.codeUnitAt(i);
  }));
}
