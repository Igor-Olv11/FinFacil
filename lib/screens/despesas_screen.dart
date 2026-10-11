import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/financas_provider.dart';
import '../models/transacao.dart';
import '../utils/formatters.dart';
import '../utils/categorias.dart';
import 'adicionar_transacao_screen.dart';

class DespesasScreen extends StatefulWidget {
  const DespesasScreen({super.key});
  @override State<DespesasScreen> createState() => _DespesasScreenState();
}

class _DespesasScreenState extends State<DespesasScreen> {
  DateTime? _inicio, _fim;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _inicio = DateTime(now.year, now.month, 1);
    _fim = DateTime(now.year, now.month + 1, 0);
  }

  List<Transacao> _filtrar(List<Transacao> l) => l.where((t) {
    final d = DateTime(t.data.year, t.data.month, t.data.day);
    final ini = _inicio == null ? null : DateTime(_inicio!.year, _inicio!.month, _inicio!.day);
    final fim = _fim == null ? null : DateTime(_fim!.year, _fim!.month, _fim!.day);
    return (ini == null || !d.isBefore(ini)) && (fim == null || !d.isAfter(fim));
  }).toList();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinancasProvider>();
    final despesas = _filtrar(p.despesas);
    final dividas = p.dividas.where((d) {
      final x = DateTime(d.dataVencimento.year, d.dataVencimento.month, d.dataVencimento.day);
      final i = _inicio == null ? null : DateTime(_inicio!.year, _inicio!.month, _inicio!.day);
      final f = _fim == null ? null : DateTime(_fim!.year, _fim!.month, _fim!.day);
      return d.valorRestante > 0 && (i == null || !x.isBefore(i)) && (f == null || !x.isAfter(f));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Despesas'),
        actions: [IconButton(icon: Icon((_inicio != null || _fim != null) ? Icons.filter_alt : Icons.filter_alt_outlined), tooltip: 'Filtrar por data', onPressed: _abrirFiltro)],
      ),
      body: Column(children: [
        if (_inicio != null || _fim != null) _chipFiltro(),
        Expanded(
          child: (despesas.isEmpty && dividas.isEmpty)
              ? const Center(child: Text('Nenhuma despesa encontrada.'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 120),
                  children: [
                    if (despesas.isNotEmpty) ...[
                      const Padding(padding: EdgeInsets.fromLTRB(8, 8, 8, 6), child: Text('Despesas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      ...despesas.map((t) => _card(context, t)),
                    ],
                    if (dividas.isNotEmpty) ...[
                      const Padding(padding: EdgeInsets.fromLTRB(8, 16, 8, 6), child: Text('Dívidas do período', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      ...dividas.map((d) => _dividaCard(context, d)),
                    ],
                  ],
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdicionarTransacaoScreen(tipo: TipoTransacao.despesa))),
        icon: const Icon(Icons.add),
        label: const Text('Nova despesa'),
      ),
    );
  }

  Widget _card(BuildContext context, Transacao t) {
    final paga = t.status == StatusTransacao.paga;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
        child: Column(children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdicionarTransacaoScreen(tipo: TipoTransacao.despesa, transacaoExistente: t))),
            leading: CircleAvatar(backgroundColor: Colors.red.withValues(alpha: .15), child: Icon(iconesCategorias[t.categoria] ?? Icons.category, color: Colors.red)),
            title: Text(t.descricao),
            subtitle: Text('${t.categoria} • ${Formatters.formatarData(t.data)}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(Formatters.formatarMoeda(t.valor), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Excluir despesa', onPressed: () => _confirmarExcluir(context, t)),
            ]),
          ),
          const Divider(height: 1),
          SizedBox(width: double.infinity, child: paga
              ? OutlinedButton.icon(onPressed: () => context.read<FinancasProvider>().reverterDespesa(t), icon: const Icon(Icons.undo), label: const Text('Reverter pagamento'))
              : FilledButton.icon(onPressed: () => context.read<FinancasProvider>().pagarDespesa(t), icon: const Icon(Icons.check_circle_outline), label: const Text('Pagar despesa'))),
        ]),
      ),
    );
  }

  Widget _dividaCard(BuildContext context, dynamic d) => Card(child: ListTile(
    leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
    title: Text(d.nome),
    subtitle: Text('Dívida • vence ${Formatters.formatarData(d.dataVencimento)}'),
    trailing: FilledButton(onPressed: () => _pagarDivida(context, d), child: const Text('Pagar')),
  ));

  Future<void> _confirmarExcluir(BuildContext context, Transacao t) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Excluir despesa?'),
      content: Text('A despesa "${t.descricao}" será removida dos registros.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir'))],
    ));
    if (ok == true && t.id != null && context.mounted) await context.read<FinancasProvider>().excluirTransacao(t.id!);
  }

  void _pagarDivida(BuildContext context, dynamic d) {
    final c = TextEditingController(text: d.valorRestante.toStringAsFixed(2));
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Pagar ${d.nome}'),
      content: TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor (R\$)')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(onPressed: () async {
          final v = double.tryParse(c.text.replaceAll(',', '.')) ?? 0;
          if (v <= 0) return;
          Navigator.pop(ctx);
          await context.read<FinancasProvider>().registrarPagamentoDivida(d, v);
          c.dispose();
        }, child: const Text('Pagar')),
      ],
    ));
  }

  Widget _chipFiltro() => Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 0), child: Align(alignment: Alignment.centerLeft, child: Chip(label: Text(_textoFiltro()), onDeleted: () => setState(() { _inicio = null; _fim = null; }))));
  String _textoFiltro() => _inicio != null && _fim != null ? '${Formatters.formatarData(_inicio!)} até ${Formatters.formatarData(_fim!)}' : _inicio != null ? 'A partir de ${Formatters.formatarData(_inicio!)}' : 'Até ${Formatters.formatarData(_fim!)}';

  Future<void> _abrirFiltro() async {
    final range = await showDateRangePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2100), initialDateRange: _inicio != null && _fim != null ? DateTimeRange(start: _inicio!, end: _fim!) : null, helpText: 'Selecione o período');
    if (range != null && mounted) setState(() { _inicio = range.start; _fim = range.end; });
  }
}
