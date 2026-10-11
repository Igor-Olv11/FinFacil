import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/financas_provider.dart';
import '../models/divida.dart';
import '../utils/formatters.dart';
import '../utils/categorias.dart';
import 'adicionar_divida_screen.dart';

class DividasScreen extends StatefulWidget {
  const DividasScreen({super.key});
  @override State<DividasScreen> createState() => _DividasScreenState();
}

class _DividasScreenState extends State<DividasScreen> {
  DateTime? _inicio, _fim;

  List<Divida> _filtrar(List<Divida> l) => l.where((d) {
    final x = DateTime(d.dataVencimento.year, d.dataVencimento.month, d.dataVencimento.day);
    final i = _inicio == null ? null : DateTime(_inicio!.year, _inicio!.month, _inicio!.day);
    final f = _fim == null ? null : DateTime(_fim!.year, _fim!.month, _fim!.day);
    return (i == null || !x.isBefore(i)) && (f == null || !x.isAfter(f));
  }).toList();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinancasProvider>();
    final ds = _filtrar(p.dividas);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dívidas'),
        actions: [IconButton(icon: Icon((_inicio != null || _fim != null) ? Icons.filter_alt : Icons.filter_alt_outlined), tooltip: 'Filtrar por data', onPressed: _abrirFiltro)],
      ),
      body: Column(children: [
        if (_inicio != null || _fim != null) _chip(),
        Expanded(
          child: ds.isEmpty
              ? const Center(child: Text('Nenhuma dívida cadastrada.'))
              : ListView(padding: const EdgeInsets.fromLTRB(8, 8, 8, 110), children: ds.map((d) => _card(context, d)).toList()),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdicionarDividaScreen())),
        icon: const Icon(Icons.add), label: const Text('Nova dívida'),
      ),
    );
  }

  Widget _card(BuildContext context, Divida d) {
    final cor = _cor(d.status);
    return Card(child: ListTile(
      contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      leading: CircleAvatar(backgroundColor: cor.withValues(alpha: .15), child: Icon(iconesCategorias[d.categoria] ?? Icons.receipt_long_outlined, color: cor)),
      title: Text(d.nome),
      subtitle: Text('${d.categoria} • Vence ${Formatters.formatarData(d.dataVencimento)}\nPago: ${Formatters.formatarMoeda(d.valorPago)} • ${d.parcelasPagas}/${d.parcelasTotal} parcelas'),
      isThreeLine: true,
      trailing: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(Formatters.formatarMoeda(d.valorRestante), style: TextStyle(color: cor, fontWeight: FontWeight.bold)),
        Text(_status(d.status), style: TextStyle(fontSize: 11, color: cor)),
      ]),
      onTap: () => _opcoes(context, d),
    ));
  }

  void _opcoes(BuildContext context, Divida d) {
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Wrap(children: [
      if (d.status != StatusDivida.paga) ListTile(leading: const Icon(Icons.payment, color: Colors.green), title: const Text('Pagar dívida / parcela'), subtitle: const Text('Pode pagar antecipadamente'), onTap: () { Navigator.pop(ctx); _pagar(context, d); }),
      if (d.valorPago > 0) ListTile(leading: const Icon(Icons.undo, color: Colors.orange), title: const Text('Reverter último pagamento'), onTap: () { Navigator.pop(ctx); _reverter(context, d); }),
      ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Editar dívida'), onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => AdicionarDividaScreen(dividaExistente: d))); }),
      ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('Excluir dívida'), onTap: () { Navigator.pop(ctx); context.read<FinancasProvider>().excluirDivida(d.id!); }),
    ])));
  }

  void _pagar(BuildContext context, Divida d) {
    final c = TextEditingController(text: d.valorRestante.toStringAsFixed(2));
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Pagar ${d.nome}'),
      content: TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor do pagamento (R\$)')),
      actions: [
        TextButton(onPressed: () { c.dispose(); Navigator.pop(ctx); }, child: const Text('Cancelar')),
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

  Future<void> _reverter(BuildContext context, Divida d) async {
    final ok = await context.read<FinancasProvider>().reverterUltimoPagamentoDivida(d);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Último pagamento revertido.' : 'Nenhum pagamento encontrado para reverter.')));
  }

  Color _cor(StatusDivida s) => switch (s) { StatusDivida.paga => Colors.green, StatusDivida.atrasada => Colors.red, StatusDivida.pendente => Colors.orange };
  String _status(StatusDivida s) => switch (s) { StatusDivida.paga => 'PAGA', StatusDivida.atrasada => 'ATRASADA', StatusDivida.pendente => 'PENDENTE' };

  Widget _chip() => Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 0), child: Align(alignment: Alignment.centerLeft, child: Chip(label: Text(_textoFiltro()), onDeleted: () => setState(() { _inicio = null; _fim = null; }))));
  String _textoFiltro() {
    String fmt(DateTime? d) => d == null ? '' : Formatters.formatarData(d);
    if (_inicio != null && _fim != null) return '${fmt(_inicio)} até ${fmt(_fim)}';
    if (_inicio != null) return 'A partir de ${fmt(_inicio)}';
    return 'Até ${fmt(_fim)}';
  }

  Future<void> _abrirFiltro() async {
    final r = await showDateRangePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2100), initialDateRange: _inicio != null && _fim != null ? DateTimeRange(start: _inicio!, end: _fim!) : null, helpText: 'Filtrar dívidas por vencimento');
    if (r != null && mounted) setState(() { _inicio = r.start; _fim = r.end; });
  }
}
