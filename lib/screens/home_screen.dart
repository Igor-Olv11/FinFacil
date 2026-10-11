import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/financas_provider.dart';
import '../utils/formatters.dart';
import '../widgets/card_resumo.dart';
import '../widgets/grafico_categorias.dart';
import 'perfil_screen.dart';
import 'historico_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _mesSelecionado;
  final _meses = const ['Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'];

  DateTime get _mesAtual => DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinancasProvider>();
    if (provider.carregando) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final todos = _mesSelecionado == null;
    final mes = _mesSelecionado ?? _mesAtual;
    final receitas = todos
        ? provider.totalReceitas
        : provider.receitasDoMes(mes).fold(0.0, (s, t) => s + t.valor);
    final despesasManuais = todos
        ? provider.totalDespesas + provider.totalPagamentosDividas
        : provider.despesasDoMes(mes).where((t) => t.status.name == 'paga').fold(0.0, (s, t) => s + t.valor) + provider.totalPagamentosDividasDoMes(mes);
    final gastos = despesasManuais;
    final dividasAbertas = provider.totalDividasEmAberto(mes: todos ? null : mes);
    final corSaldo = provider.saldo >= 0 ? Colors.green : Colors.red;
    final titulo = provider.nomeUsuario.isNotEmpty ? 'Olá, ${provider.nomeUsuario}' : 'FinanFacil';

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [
          IconButton(icon: const Icon(Icons.history), tooltip: 'Histórico', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoricoScreen()))),
          IconButton(icon: const Icon(Icons.person_outline), tooltip: 'Meu perfil', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilScreen()))),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.carregarTudo,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
          children: [
            _filtroPeriodo(context),
            const SizedBox(height: 12),
            Card(
              color: corSaldo.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  const Text('Saldo atual', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(Formatters.formatarMoeda(provider.saldo), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: corSaldo)),
                  const SizedBox(height: 6),
                  Text('Saldo atual com base nas receitas, despesas e pagamentos registrados.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: CardResumo(titulo: 'Receitas', valor: receitas, cor: Colors.green, icone: Icons.arrow_upward)),
              const SizedBox(width: 10),
              Expanded(child: CardResumo(titulo: 'Gastos', valor: gastos, cor: Colors.red, icone: Icons.arrow_downward)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: CardResumo(titulo: 'Dívidas em aberto', valor: dividasAbertas, cor: Colors.orange, icone: Icons.receipt_long_outlined)),
              const SizedBox(width: 10),
              Expanded(child: CardResumo(titulo: 'Saldo previsto', valor: todos ? provider.saldo : provider.saldoPrevisto(mes), cor: Colors.blue, icone: Icons.account_balance_wallet_outlined)),
            ]),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(todos ? 'Visão geral de todos os meses' : 'Resumo de ${_meses[mes.month - 1]} de ${mes.year}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 10),
                  _linhaResumo('Despesas e dívidas pagas', despesasManuais),
                  _linhaResumo('Total de gastos', gastos, destaque: true),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            if (provider.salarioBase == 0)
              Card(
                color: Colors.blue.withValues(alpha: 0.08),
                child: ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.blue),
                  title: const Text('Cadastre seu salário no perfil'),
                  subtitle: const Text('Assim ele entra automaticamente todo mês nas receitas.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilScreen())),
                ),
              ),
            if (provider.salarioBase > 0) ...[
              CardResumo(titulo: 'Salário base (perfil)', valor: provider.salarioBase, cor: Colors.teal, icone: Icons.badge_outlined, largo: true),
              const SizedBox(height: 12),
            ],
            if (provider.despesasPorCategoria.isNotEmpty && todos == false) ...[
              const Text('Despesas por categoria', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GraficoCategorias(dados: provider.despesasPorCategoriaDoMes(mes)),
              const SizedBox(height: 24),
            ],
            const Text('Principais pontos de atenção', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ... (todos ? provider.problemasFinanceiros : provider.problemasFinanceirosPara(mes)).take(4).map((p) => Card(child: ListTile(leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange), title: Text(p)))),
          ],
        ),
      ),
    );
  }

  Widget _filtroPeriodo(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.calendar_month_outlined),
      title: const Text('Período da visão inicial', style: TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(_mesSelecionado == null ? 'Todos os meses' : '${_meses[_mesSelecionado!.month - 1]} de ${_mesSelecionado!.year}'),
      trailing: const Icon(Icons.tune_outlined),
      onTap: _abrirPeriodo,
    ),
  );

  Widget _linhaResumo(String texto, double valor, {bool destaque = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [Expanded(child: Text(texto, style: TextStyle(fontWeight: destaque ? FontWeight.w700 : FontWeight.normal))), Text(Formatters.formatarMoeda(valor), style: TextStyle(fontWeight: destaque ? FontWeight.w800 : FontWeight.w600))]),
  );

  Future<void> _abrirPeriodo() async {
    final opcao = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const ListTile(title: Text('Mostrar no início', style: TextStyle(fontWeight: FontWeight.w800))),
        ListTile(leading: const Icon(Icons.all_inclusive), title: const Text('Todos os meses'), selected: _mesSelecionado == null, onTap: () => Navigator.pop(ctx, 'todos')),
        ListTile(leading: const Icon(Icons.today_outlined), title: const Text('Mês atual'), selected: _mesSelecionado != null && _mesSelecionado == _mesAtual, onTap: () => Navigator.pop(ctx, 'atual')),
        ListTile(leading: const Icon(Icons.calendar_month_outlined), title: const Text('Escolher outro mês'), onTap: () => Navigator.pop(ctx, 'escolher')),
        const SizedBox(height: 8),
      ])),
    );
    if (!mounted || opcao == null) return;
    if (opcao == 'todos') setState(() => _mesSelecionado = null);
    if (opcao == 'atual') setState(() => _mesSelecionado = _mesAtual);
    if (opcao == 'escolher') {
      final d = await showDatePicker(context: context, initialDate: _mesSelecionado ?? _mesAtual, firstDate: DateTime(2000), lastDate: DateTime(2100), helpText: 'Escolha o mês');
      if (d != null && mounted) setState(() => _mesSelecionado = DateTime(d.year, d.month, 1));
    }
  }
}
