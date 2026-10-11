enum StatusDivida { pendente, paga, atrasada }

class Divida {
  final int? id;
  final String nome;
  final double valorTotal;
  final double valorPago;
  final DateTime dataVencimento;
  final int parcelasTotal;
  final int parcelasPagas;
  final String categoria;
  final double taxaJuros;

  Divida({
    this.id,
    required this.nome,
    required this.valorTotal,
    this.valorPago = 0,
    required this.dataVencimento,
    this.parcelasTotal = 1,
    this.parcelasPagas = 0,
    this.categoria = 'Outros',
    this.taxaJuros = 0,
  });

  double get valorRestante => (valorTotal - valorPago).clamp(0, double.infinity).toDouble();

  StatusDivida get status {
    if (valorRestante <= 0.009) return StatusDivida.paga;
    final hoje = DateTime.now();
    final hojeData = DateTime(hoje.year, hoje.month, hoje.day);
    final vencimento = DateTime(dataVencimento.year, dataVencimento.month, dataVencimento.day);
    return vencimento.isBefore(hojeData) ? StatusDivida.atrasada : StatusDivida.pendente;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nome': nome,
    'valorTotal': valorTotal,
    'valorPago': valorPago,
    'dataVencimento': dataVencimento.toIso8601String(),
    'parcelasTotal': parcelasTotal,
    'parcelasPagas': parcelasPagas,
    'categoria': categoria,
    'taxaJuros': taxaJuros,
  };

  factory Divida.fromMap(Map<String, dynamic> map) => Divida(
    id: map['id'] as int?,
    nome: map['nome'] as String,
    valorTotal: (map['valorTotal'] as num).toDouble(),
    valorPago: (map['valorPago'] as num).toDouble(),
    dataVencimento: DateTime.parse(map['dataVencimento'] as String),
    parcelasTotal: (map['parcelasTotal'] as num?)?.toInt() ?? 1,
    parcelasPagas: (map['parcelasPagas'] as num?)?.toInt() ?? 0,
    categoria: map['categoria'] as String? ?? 'Outros',
    taxaJuros: (map['taxaJuros'] as num?)?.toDouble() ?? 0,
  );

  Divida copyWith({double? valorPago, int? parcelasPagas}) => Divida(
    id: id,
    nome: nome,
    valorTotal: valorTotal,
    valorPago: valorPago ?? this.valorPago,
    dataVencimento: dataVencimento,
    parcelasTotal: parcelasTotal,
    parcelasPagas: parcelasPagas ?? this.parcelasPagas,
    categoria: categoria,
    taxaJuros: taxaJuros,
  );
}

class PagamentoDivida {
  final int? id;
  final int dividaId;
  final double valor;
  final DateTime data;

  PagamentoDivida({this.id, required this.dividaId, required this.valor, required this.data});

  Map<String, dynamic> toMap() => {
    'id': id,
    'dividaId': dividaId,
    'valor': valor,
    'data': data.toIso8601String(),
  };

  factory PagamentoDivida.fromMap(Map<String, dynamic> map) => PagamentoDivida(
    id: map['id'] as int?,
    dividaId: (map['dividaId'] as num).toInt(),
    valor: (map['valor'] as num).toDouble(),
    data: DateTime.parse(map['data'] as String),
  );
}
