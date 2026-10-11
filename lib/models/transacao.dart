enum TipoTransacao { receita, despesa }

enum StatusTransacao { pendente, paga, recebida }

class Transacao {
  final int? id;
  final String descricao;
  final double valor;
  final TipoTransacao tipo;
  final String categoria;
  final DateTime data;
  final bool recorrente;
  final StatusTransacao status;
  final DateTime? dataPagamento;

  Transacao({
    this.id,
    required this.descricao,
    required this.valor,
    required this.tipo,
    required this.categoria,
    required this.data,
    this.recorrente = false,
    StatusTransacao? status,
    this.dataPagamento,
  }) : status = status ?? (tipo == TipoTransacao.receita ? StatusTransacao.recebida : StatusTransacao.pendente);

  bool get efetivada => tipo == TipoTransacao.receita
      ? status == StatusTransacao.recebida
      : status == StatusTransacao.paga;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': descricao,
      'valor': valor,
      'tipo': tipo == TipoTransacao.receita ? 'receita' : 'despesa',
      'categoria': categoria,
      'data': data.toIso8601String(),
      'recorrente': recorrente ? 1 : 0,
      'status': status.name,
      'dataPagamento': dataPagamento?.toIso8601String(),
    };
  }

  factory Transacao.fromMap(Map<String, dynamic> map) {
    final tipo = map['tipo'] == 'receita' ? TipoTransacao.receita : TipoTransacao.despesa;
    final statusString = map['status'] as String?;
    final status = statusString == null
        ? (tipo == TipoTransacao.receita ? StatusTransacao.recebida : StatusTransacao.paga)
        : StatusTransacao.values.firstWhere(
            (s) => s.name == statusString,
            orElse: () => tipo == TipoTransacao.receita ? StatusTransacao.recebida : StatusTransacao.paga,
          );
    return Transacao(
      id: map['id'] as int?,
      descricao: map['descricao'] as String,
      valor: (map['valor'] as num).toDouble(),
      tipo: tipo,
      categoria: map['categoria'] as String,
      data: DateTime.parse(map['data'] as String),
      recorrente: (map['recorrente'] as int? ?? 0) == 1,
      status: status,
      dataPagamento: map['dataPagamento'] != null ? DateTime.tryParse(map['dataPagamento'] as String) : null,
    );
  }

  Transacao copyWith({
    String? descricao,
    double? valor,
    String? categoria,
    DateTime? data,
    bool? recorrente,
    StatusTransacao? status,
    DateTime? dataPagamento,
  }) {
    return Transacao(
      id: id,
      descricao: descricao ?? this.descricao,
      valor: valor ?? this.valor,
      tipo: tipo,
      categoria: categoria ?? this.categoria,
      data: data ?? this.data,
      recorrente: recorrente ?? this.recorrente,
      status: status ?? this.status,
      dataPagamento: dataPagamento ?? this.dataPagamento,
    );
  }
}
