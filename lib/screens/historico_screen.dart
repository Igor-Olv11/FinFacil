import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/financas_provider.dart';
import '../models/transacao.dart';
import '../utils/formatters.dart';

class HistoricoScreen extends StatelessWidget {
  const HistoricoScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinancasProvider>();
    final itens = <Transacao>[...p.receitasRecebidas, ...p.despesasPagas, ...p.salariosGerados()];
    final dividasMap = {for (final d in p.dividas) d.id: d};
    for (final pg in p.pagamentosDivida) {
      final d = dividasMap[pg.dividaId];
      itens.add(Transacao(id: -1000000 - (pg.id ?? 0), descricao: 'Pagamento: ${d?.nome ?? 'Dívida'}', valor: pg.valor, tipo: TipoTransacao.despesa, categoria: d?.categoria ?? 'Dívidas', data: pg.data, status: StatusTransacao.paga, dataPagamento: pg.data));
    }
    itens.sort((a, b) => (b.dataPagamento ?? b.data).compareTo(a.dataPagamento ?? a.data));
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: itens.isEmpty
          ? const Center(child: Text('Nenhuma movimentação realizada.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: itens.length,
              itemBuilder: (_, i) {
                final t = itens[i];
                final receita = t.tipo == TipoTransacao.receita;
                final data = t.dataPagamento ?? t.data;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (receita ? Colors.green : Colors.red).withValues(alpha: .12),
                      child: Icon(receita ? Icons.arrow_upward : Icons.arrow_downward, color: receita ? Colors.green : Colors.red),
                    ),
                    title: Text(t.descricao),
                    subtitle: Text('${t.categoria} • ${Formatters.formatarData(data)}${t.dataPagamento != null ? ' • pago' : t.recorrente ? ' • salário' : ''}'),
                    trailing: Text('${receita ? '+' : '-'} ${Formatters.formatarMoeda(t.valor)}', style: TextStyle(color: receita ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
    );
  }
}
