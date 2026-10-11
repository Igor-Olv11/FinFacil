import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/financas_provider.dart';
import '../models/transacao.dart';
import '../utils/formatters.dart';
import '../utils/categorias.dart';
import 'adicionar_transacao_screen.dart';

class ReceitasScreen extends StatefulWidget {
  const ReceitasScreen({super.key});

  @override
  State<ReceitasScreen> createState() => _ReceitasScreenState();
}

class _ReceitasScreenState extends State<ReceitasScreen> {
  DateTime? _dataInicio;
  DateTime? _dataFim;

  List<Transacao> _aplicarFiltro(List<Transacao> lista) {
    if (_dataInicio == null && _dataFim == null) return lista;
    return lista.where((t) {
      if (_dataInicio != null && t.data.isBefore(_dataInicio!)) return false;
      if (_dataFim != null && t.data.isAfter(_dataFim!)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinancasProvider>();
    final receitas = _aplicarFiltro(provider.receitas);
    final filtroAtivo = _dataInicio != null || _dataFim != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receitas'),
        actions: [
          IconButton(
            icon: Icon(filtroAtivo ? Icons.filter_alt : Icons.filter_alt_outlined),
            tooltip: 'Filtrar por data',
            onPressed: () => _abrirFiltro(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (filtroAtivo) _chipFiltro(),
          Expanded(
            child: receitas.isEmpty
                ? const Center(child: Text('Nenhuma receita encontrada.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: receitas.length,
                    itemBuilder: (context, i) {
                      final t = receitas[i];
                      return Dismissible(
                        key: ValueKey(t.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmarExclusao(context, t),
                        onDismissed: (_) => context.read<FinancasProvider>().excluirTransacao(t.id!),
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: ListTile(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdicionarTransacaoScreen(
                                  tipo: TipoTransacao.receita,
                                  transacaoExistente: t,
                                ),
                              ),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.withValues(alpha: 0.15),
                              child: Icon(iconesCategorias[t.categoria] ?? Icons.category, color: Colors.green),
                            ),
                            title: Text(t.descricao),
                            subtitle: Text('${t.categoria} • ${Formatters.formatarData(t.data)}'),
                            trailing: Text(
                              Formatters.formatarMoeda(t.valor),
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdicionarTransacaoScreen(tipo: TipoTransacao.receita)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nova receita'),
      ),
    );
  }

  Widget _chipFiltro() {
    final texto = _dataInicio != null && _dataFim != null
        ? '${Formatters.formatarData(_dataInicio!)} até ${Formatters.formatarData(_dataFim!)}'
        : _dataInicio != null
            ? 'A partir de ${Formatters.formatarData(_dataInicio!)}'
            : 'Até ${Formatters.formatarData(_dataFim!)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Chip(
          label: Text(texto),
          onDeleted: () => setState(() {
            _dataInicio = null;
            _dataFim = null;
          }),
        ),
      ),
    );
  }

  Future<bool> _confirmarExclusao(BuildContext context, Transacao t) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir receita'),
        content: Text('Deseja excluir "${t.descricao}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }

  Future<void> _abrirFiltro(BuildContext context) async {
    DateTime? inicio = _dataInicio;
    DateTime? fim = _dataFim;
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filtrar por data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('De'),
                  subtitle: Text(inicio != null ? Formatters.formatarData(inicio!) : 'Sem início'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: inicio ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setModalState(() => inicio = d);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Até'),
                  subtitle: Text(fim != null ? Formatters.formatarData(fim!) : 'Sem fim'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: fim ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setModalState(() => fim = d);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _dataInicio = null;
                            _dataFim = null;
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Ver todas'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _dataInicio = inicio;
                            _dataFim = fim;
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
