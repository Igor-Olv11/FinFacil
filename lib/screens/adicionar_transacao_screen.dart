import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/financas_provider.dart';
import '../models/transacao.dart';
import '../utils/categorias.dart';

class AdicionarTransacaoScreen extends StatefulWidget {
  final TipoTransacao tipo;
  final Transacao? transacaoExistente;

  const AdicionarTransacaoScreen({
    super.key,
    required this.tipo,
    this.transacaoExistente,
  });

  bool get editando => transacaoExistente != null;

  @override
  State<AdicionarTransacaoScreen> createState() => _AdicionarTransacaoScreenState();
}

class _AdicionarTransacaoScreenState extends State<AdicionarTransacaoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descricaoCtrl;
  late final TextEditingController _valorCtrl;
  late String _categoria;
  late DateTime _data;
  late bool _recorrente;

  @override
  void initState() {
    super.initState();
    final existente = widget.transacaoExistente;
    _descricaoCtrl = TextEditingController(text: existente?.descricao ?? '');
    _valorCtrl = TextEditingController(
      text: existente != null ? existente.valor.toStringAsFixed(2).replaceAll('.', ',') : '',
    );
    _data = existente?.data ?? DateTime.now();
    _recorrente = existente?.recorrente ?? false;

    final provider = context.read<FinancasProvider>();
    final lista =
        widget.tipo == TipoTransacao.receita ? provider.todasCategoriasReceita : provider.todasCategoriasDespesa;
    _categoria = existente != null && lista.contains(existente.categoria) ? existente.categoria : lista.first;
  }

  @override
  Widget build(BuildContext context) {
    final ehReceita = widget.tipo == TipoTransacao.receita;
    final provider = context.watch<FinancasProvider>();
    final categoriasLista = ehReceita ? provider.todasCategoriasReceita : provider.todasCategoriasDespesa;

    final tituloBase = ehReceita ? 'Receita' : 'Despesa';
    final titulo = widget.editando ? 'Editar $tituloBase' : 'Nova $tituloBase';

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _descricaoCtrl,
              decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.isEmpty) ? 'Informe uma descrição' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valorCtrl,
              decoration: const InputDecoration(labelText: 'Valor (R\$)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe um valor';
                final n = double.tryParse(v.replaceAll(',', '.'));
                if (n == null || n <= 0) return 'Valor inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _categoria,
              decoration: const InputDecoration(labelText: 'Categoria', border: OutlineInputBorder()),
              items: [
                ...categoriasLista.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                const DropdownMenuItem(
                  value: opcaoNovaCategoria,
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 18),
                      SizedBox(width: 6),
                      Text('Nova categoria...'),
                    ],
                  ),
                ),
              ],
              onChanged: (v) async {
                if (v == opcaoNovaCategoria) {
                  final nome = await mostrarDialogNovaCategoria(context);
                  if (nome != null && mounted) {
                    if (ehReceita) {
                      await context.read<FinancasProvider>().adicionarCategoriaReceita(nome);
                    } else {
                      await context.read<FinancasProvider>().adicionarCategoriaDespesa(nome);
                    }
                    setState(() => _categoria = nome);
                  }
                } else if (v != null) {
                  setState(() => _categoria = v);
                }
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data'),
              subtitle: Text(
                '${_data.day.toString().padLeft(2, '0')}/${_data.month.toString().padLeft(2, '0')}/${_data.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final novaData = await showDatePicker(
                  context: context,
                  initialDate: _data,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (novaData != null) setState(() => _data = novaData);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Recorrente (todo mês)'),
              value: _recorrente,
              onChanged: (v) => setState(() => _recorrente = v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _salvar,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(widget.editando ? 'Salvar alterações' : 'Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    final valor = double.parse(_valorCtrl.text.replaceAll(',', '.'));
    final existente = widget.transacaoExistente;
    final hoje = DateTime.now();
    final dataNormalizada = DateTime(_data.year, _data.month, _data.day);
    final hojeNormalizado = DateTime(hoje.year, hoje.month, hoje.day);
    final status = existente?.status ?? (widget.tipo == TipoTransacao.receita && !dataNormalizada.isAfter(hojeNormalizado) ? StatusTransacao.recebida : StatusTransacao.pendente);
    final transacao = Transacao(
      id: existente?.id,
      descricao: _descricaoCtrl.text,
      valor: valor,
      tipo: widget.tipo,
      categoria: _categoria,
      data: _data,
      recorrente: _recorrente,
      status: status,
      dataPagamento: existente?.dataPagamento,
    );
    if (widget.editando) {
      context.read<FinancasProvider>().atualizarTransacao(transacao);
    } else {
      context.read<FinancasProvider>().adicionarTransacao(transacao);
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }
}
