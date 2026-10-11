import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';
import '../models/transacao.dart';
import '../models/divida.dart';
import '../utils/categorias.dart';

class FinancasProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<Transacao> _transacoes = [];
  List<Divida> _dividas = [];
  List<PagamentoDivida> _pagamentosDivida = [];
  bool carregando = true;

  String nomeUsuario = '';
  double salarioBase = 0;
  int salarioDiaRecebimento = 5;
  DateTime? _salarioInicio;
  double ajusteSaldo = 0;
  String tema = 'sistema';
  ThemeMode get themeMode => switch (tema) { 'claro' => ThemeMode.light, 'escuro' => ThemeMode.dark, _ => ThemeMode.system };

  List<String> _categoriasReceitaExtras = [];
  List<String> _categoriasDespesaExtras = [];
  List<String> _categoriasDividaExtras = [];

  List<String> get todasCategoriasReceita => [...categoriasReceita, ..._categoriasReceitaExtras];
  List<String> get todasCategoriasDespesa => [...categoriasDespesa, ..._categoriasDespesaExtras];
  List<String> get todasCategoriasDivida => [...categoriasDivida, ..._categoriasDividaExtras];
  List<Transacao> get transacoes => List.unmodifiable(_transacoes);
  List<Divida> get dividas => List.unmodifiable(_dividas);
  List<PagamentoDivida> get pagamentosDivida => List.unmodifiable(_pagamentosDivida);


  List<Transacao> get receitas => _transacoes.where((t) => t.tipo == TipoTransacao.receita).toList();
  List<Transacao> get despesas => _transacoes.where((t) => t.tipo == TipoTransacao.despesa).toList();
  List<Transacao> get despesasPendentes => despesas.where((t) => t.status == StatusTransacao.pendente).toList();
  List<Transacao> get despesasPagas => despesas.where((t) => t.status == StatusTransacao.paga).toList();
  List<Transacao> get receitasRecebidas => receitas.where((t) => t.status == StatusTransacao.recebida).toList();

  DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);
  bool _mes(DateTime d, DateTime mes) => d.year == mes.year && d.month == mes.month;

  bool get salarioRecebidoEsteMes {
    if (salarioBase <= 0) return false;
    final hoje = DateTime.now();
    return hoje.day >= salarioDiaRecebimento;
  }

  DateTime get dataSalarioEsteMes {
    final hoje = DateTime.now();
    final ultimoDia = DateTime(hoje.year, hoje.month + 1, 0).day;
    return DateTime(hoje.year, hoje.month, salarioDiaRecebimento.clamp(1, ultimoDia).toInt());
  }

  /// Salários virtuais desde o mês em que o salário foi configurado.
  List<Transacao> salariosGerados({DateTime? ate}) {
    if (salarioBase <= 0 || _salarioInicio == null) return [];
    final fim = _dia(ate ?? DateTime.now());
    var cursor = DateTime(_salarioInicio!.year, _salarioInicio!.month, 1);
    final lista = <Transacao>[];
    while (!cursor.isAfter(fim)) {
      final ultimoDia = DateTime(cursor.year, cursor.month + 1, 0).day;
      final dia = salarioDiaRecebimento.clamp(1, ultimoDia).toInt();
      final data = DateTime(cursor.year, cursor.month, dia);
      if (!data.isAfter(fim)) {
        lista.add(Transacao(
          id: -((cursor.year * 100) + cursor.month),
          descricao: 'Salário',
          valor: salarioBase,
          tipo: TipoTransacao.receita,
          categoria: 'Salário',
          data: data,
          recorrente: true,
          status: StatusTransacao.recebida,
        ));
      }
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return lista;
  }

  List<Transacao> receitasDoMes(DateTime mes) {
    final extras = receitas.where((t) => _mes(t.data, mes) && t.status == StatusTransacao.recebida);
    final hoje = _dia(DateTime.now());
    final fimMes = DateTime(mes.year, mes.month + 1, 0);
    final limite = fimMes.isAfter(hoje) ? hoje : fimMes;
    final salario = salariosGerados(ate: limite).where((t) => _mes(t.data, mes));
    return [...extras, ...salario];
  }

  List<Transacao> despesasDoMes(DateTime mes) => despesas.where((t) => _mes(t.data, mes)).toList();

  double get totalReceitasExtras => receitasRecebidas.fold(0.0, (s, t) => s + t.valor);
  double get totalSalariosRecebidos => salariosGerados().fold(0.0, (s, t) => s + t.valor);
  double get totalReceitas => totalReceitasExtras + totalSalariosRecebidos;
  double get totalDespesas => despesasPagas.fold(0.0, (s, t) => s + t.valor);
  double get totalPagamentosDividas => _pagamentosDivida.fold(0.0, (s, p) => s + p.valor);
  double get totalDespesasPendentes => despesasPendentes.fold(0.0, (s, t) => s + t.valor);
  double get totalDividasRestante => _dividas.fold(0.0, (s, d) => s + d.valorRestante);

  /// Soma o valor que ainda falta pagar das dívidas.
  /// Quando [mes] é informado, considera somente as dívidas com vencimento
  /// naquele mês. Quando não é informado, considera todas as dívidas abertas.
  double totalDividasEmAberto({DateTime? mes}) {
    final lista = mes == null
        ? _dividas
        : _dividas.where((d) => _mes(d.dataVencimento, mes));
    return lista
        .where((d) => d.valorRestante > 0)
        .fold(0.0, (s, d) => s + d.valorRestante);
  }
  double get saldoBaseCalculado => totalReceitas - totalDespesas - totalPagamentosDividas;
  double get saldoCalculado => saldoBaseCalculado + ajusteSaldo;
  double get saldo => saldoCalculado;

  double saldoMes(DateTime mes) {
    final r = receitasDoMes(mes).fold(0.0, (s, t) => s + t.valor);
    final d = despesasDoMes(mes).where((t) => t.status == StatusTransacao.paga).fold(0.0, (s, t) => s + t.valor);
    final p = totalPagamentosDividasDoMes(mes);
    return r - d - p;
  }

  double totalPagamentosDividasDoMes(DateTime mes) => _pagamentosDivida.where((x) => _mes(x.data, mes)).fold(0.0, (s, x) => s + x.valor);

  double saldoPrevisto(DateTime mes) {
    final r = receitasDoMes(mes).fold(0.0, (s, t) => s + t.valor);
    final despesasPendentes = despesasDoMes(mes).where((t) => t.status == StatusTransacao.pendente).fold(0.0, (s, t) => s + t.valor);
    final pagamentos = totalPagamentosDividasDoMes(mes);
    final dividas = dividasDoMes(mes).where((d) => d.valorRestante > 0).fold(0.0, (s, d) => s + d.valorRestante);
    return r - despesasPendentes - pagamentos - dividas;
  }

  List<Divida> dividasDoMes(DateTime mes) => _dividas.where((d) => _mes(d.dataVencimento, mes)).toList();

  List<Divida> get dividasAtrasadas => _dividas.where((d) => d.status == StatusDivida.atrasada).toList();
  List<Divida> get dividasPendentes => _dividas.where((d) => d.status != StatusDivida.paga).toList();

  Future<void> inicializar() async {
    await carregarPerfil();
    await carregarCategorias();
    await carregarTudo();
  }

  Future<void> carregarTudo() async {
    carregando = true;
    _transacoes = await _db.listarTransacoes();
    _dividas = await _db.listarDividas();
    final pagamentos = <PagamentoDivida>[];
    for (final d in _dividas) {
      if (d.id != null) pagamentos.addAll(await _db.listarPagamentosDivida(d.id!));
    }
    _pagamentosDivida = pagamentos;
    await _processarDatasAutomaticamente();
    carregando = false;
    notifyListeners();
  }

  Future<void> _processarDatasAutomaticamente() async {
    final hoje = _dia(DateTime.now());
    for (final t in _transacoes) {
      if (t.tipo == TipoTransacao.receita && t.status == StatusTransacao.pendente && !_dia(t.data).isAfter(hoje)) {
        await _db.atualizarTransacao(t.copyWith(status: StatusTransacao.recebida));
      }
    }
    _transacoes = await _db.listarTransacoes();
  }

  Future<void> carregarPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    nomeUsuario = prefs.getString('nome_usuario') ?? '';
    salarioBase = prefs.getDouble('salario_base') ?? 0;
    salarioDiaRecebimento = prefs.getInt('salario_dia') ?? 5;
    final inicio = prefs.getString('salario_inicio');
    _salarioInicio = inicio == null ? (salarioBase > 0 ? _dia(DateTime.now()) : null) : DateTime.tryParse(inicio);
    if (inicio == null && _salarioInicio != null) await prefs.setString('salario_inicio', _salarioInicio!.toIso8601String());
    ajusteSaldo = prefs.getDouble('ajuste_saldo') ?? 0;
    tema = prefs.getString('tema_app') ?? 'sistema';
    notifyListeners();
  }

  Future<void> definirTema(String novoTema) async {
    if (!{'sistema','claro','escuro'}.contains(novoTema)) return;
    tema = novoTema;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tema_app', novoTema);
    notifyListeners();
  }

  Future<void> salvarPerfil({required String nome, required double salario, required int diaRecebimento}) async {
    final prefs = await SharedPreferences.getInstance();
    final salarioAnterior = salarioBase;
    await prefs.setString('nome_usuario', nome);
    await prefs.setDouble('salario_base', salario);
    await prefs.setInt('salario_dia', diaRecebimento);
    if (_salarioInicio == null || salarioAnterior != salario) {
      _salarioInicio = _dia(DateTime.now());
      await prefs.setString('salario_inicio', _salarioInicio!.toIso8601String());
    }
    nomeUsuario = nome;
    salarioBase = salario;
    salarioDiaRecebimento = diaRecebimento;
    notifyListeners();
  }

  Future<void> editarSaldo(double valor) async {
    final prefs = await SharedPreferences.getInstance();
    // O valor informado vira um ajuste relativo ao saldo dos registros.
    ajusteSaldo = valor - saldoBaseCalculado;
    await prefs.setDouble('ajuste_saldo', ajusteSaldo);
    notifyListeners();
  }

  Future<void> recalcularSaldo() async {
    ajusteSaldo = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ajuste_saldo', 0);
    notifyListeners();
  }

  Future<void> adicionarCategoriaReceita(String nome) async { if (todasCategoriasReceita.contains(nome)) return; _categoriasReceitaExtras.add(nome); final p = await SharedPreferences.getInstance(); await p.setStringList('cat_receita_extra', _categoriasReceitaExtras); notifyListeners(); }
  Future<void> adicionarCategoriaDespesa(String nome) async { if (todasCategoriasDespesa.contains(nome)) return; _categoriasDespesaExtras.add(nome); final p = await SharedPreferences.getInstance(); await p.setStringList('cat_despesa_extra', _categoriasDespesaExtras); notifyListeners(); }
  Future<void> adicionarCategoriaDivida(String nome) async { if (todasCategoriasDivida.contains(nome)) return; _categoriasDividaExtras.add(nome); final p = await SharedPreferences.getInstance(); await p.setStringList('cat_divida_extra', _categoriasDividaExtras); notifyListeners(); }

  Future<void> carregarCategorias() async {
    final p = await SharedPreferences.getInstance();
    _categoriasReceitaExtras = p.getStringList('cat_receita_extra') ?? [];
    _categoriasDespesaExtras = p.getStringList('cat_despesa_extra') ?? [];
    _categoriasDividaExtras = p.getStringList('cat_divida_extra') ?? [];
  }

  Future<void> adicionarTransacao(Transacao t) async {
    final status = t.tipo == TipoTransacao.receita && !_dia(t.data).isAfter(_dia(DateTime.now())) ? StatusTransacao.recebida : t.status;
    await _db.inserirTransacao(t.copyWith(status: status));
    await carregarTudo();
  }
  Future<void> atualizarTransacao(Transacao t) async {
    if (t.tipo == TipoTransacao.receita) {
      final hoje = _dia(DateTime.now());
      final status = _dia(t.data).isAfter(hoje) ? StatusTransacao.pendente : StatusTransacao.recebida;
      t = t.copyWith(status: status);
    }
    await _db.atualizarTransacao(t);
    await carregarTudo();
  }
  Future<void> excluirTransacao(int id) async { await _db.excluirTransacao(id); await carregarTudo(); }

  Future<void> pagarDespesa(Transacao t) async {
    if (t.id == null || t.status == StatusTransacao.paga) return;
    await _db.atualizarTransacao(t.copyWith(status: StatusTransacao.paga, dataPagamento: DateTime.now()));
    await carregarTudo();
  }

  Future<void> reverterDespesa(Transacao t) async {
    if (t.id == null || t.status != StatusTransacao.paga) return;
    await _db.atualizarTransacao(Transacao(id: t.id, descricao: t.descricao, valor: t.valor, tipo: t.tipo, categoria: t.categoria, data: t.data, recorrente: t.recorrente, status: StatusTransacao.pendente));
    await carregarTudo();
  }


  Future<void> adicionarDivida(Divida d) async { await _db.inserirDivida(d); await carregarTudo(); }
  Future<void> atualizarDivida(Divida d) async { await _db.atualizarDivida(d); await carregarTudo(); }
  Future<void> excluirDivida(int id) async { await _db.excluirDivida(id); await carregarTudo(); }

  Future<void> registrarPagamentoDivida(Divida d, double valorPago) async {
    if (d.id == null || valorPago <= 0 || d.valorRestante <= 0) return;
    final valor = valorPago > d.valorRestante ? d.valorRestante : valorPago;
    final parcelas = (d.parcelasPagas + 1).clamp(0, d.parcelasTotal).toInt();
    await _db.inserirPagamentoDivida(PagamentoDivida(dividaId: d.id!, valor: valor, data: DateTime.now()));
    await _db.atualizarDivida(d.copyWith(valorPago: d.valorPago + valor, parcelasPagas: parcelas));
    await carregarTudo();
  }

  Future<bool> reverterUltimoPagamentoDivida(Divida d) async {
    if (d.id == null) return false;
    final ultimo = await _db.ultimoPagamentoDivida(d.id!);
    if (ultimo == null) return false;
    final novoPago = (d.valorPago - ultimo.valor).clamp(0, d.valorTotal).toDouble();
    final parcelas = (d.parcelasPagas - 1).clamp(0, d.parcelasTotal).toInt();
    await _db.excluirPagamentoDivida(ultimo.id!);
    await _db.atualizarDivida(d.copyWith(valorPago: novoPago, parcelasPagas: parcelas));
    await carregarTudo();
    return true;
  }

  Future<List<PagamentoDivida>> pagamentosDaDivida(int id) => _db.listarPagamentosDivida(id);

  Map<String, double> despesasPorCategoriaDoMes(DateTime mes) {
    final mapa = <String, double>{};
    for (final t in despesasDoMes(mes).where((t) => t.status == StatusTransacao.paga)) {
      mapa[t.categoria] = (mapa[t.categoria] ?? 0) + t.valor;
    }
    for (final d in dividasDoMes(mes).where((d) => d.valorRestante > 0 && d.status != StatusDivida.paga)) {
      mapa[d.categoria] = (mapa[d.categoria] ?? 0) + d.valorRestante;
    }
    return mapa;
  }

  Map<String, double> get despesasPorCategoria => despesasPorCategoriaDoMes(DateTime.now());

  List<String> problemasFinanceirosPara(DateTime mes) {
    final problemas = <String>[];
    final receitasMes = receitasDoMes(mes).fold(0.0, (s, t) => s + t.valor);
    final despesasMes = despesasDoMes(mes).where((t) => t.status == StatusTransacao.paga).fold(0.0, (s, t) => s + t.valor) + _pagamentosDivida.where((x) => _mes(x.data, mes)).fold(0.0, (s, x) => s + x.valor);
    if (dividasAtrasadas.isNotEmpty) problemas.add('Você tem ${dividasAtrasadas.length} dívida(s) atrasada(s).');
    final categorias = despesasPorCategoriaDoMes(mes);
    if (categorias.isNotEmpty && despesasMes > 0) {
      final maior = categorias.entries.reduce((a, b) => a.value > b.value ? a : b);
      final pct = (maior.value / despesasMes) * 100;
      if (pct > 40) problemas.add('${pct.toStringAsFixed(0)}% das despesas estão concentradas em "${maior.key}".');
    }
    if (problemas.isEmpty) problemas.add('Nenhum ponto crítico identificado neste mês.');
    return problemas;
  }

  List<String> get problemasFinanceiros => problemasFinanceirosPara(DateTime.now());
}
