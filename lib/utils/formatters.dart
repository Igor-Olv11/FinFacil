import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final DateFormat _data = DateFormat('dd/MM/yyyy');

  static String formatarMoeda(double valor) => _moeda.format(valor);
  static String formatarData(DateTime d) => _data.format(d);
}
