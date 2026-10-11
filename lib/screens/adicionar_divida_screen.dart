import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/financas_provider.dart';
import '../models/divida.dart';
import '../utils/categorias.dart';

class AdicionarDividaScreen extends StatefulWidget {
  final Divida? dividaExistente;
  const AdicionarDividaScreen({super.key, this.dividaExistente});

  bool get editando => dividaExistente != null;

  @override
  State<AdicionarDividaScreen> createState() => _AdicionarDividaScreenState();
}

class _AdicionarDividaScreenState extends State<AdicionarDividaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _valorCtrl;
  late final TextEditingController _parcelasCtrl;
  late final TextEditingController _jurosCtrl;
  late String _categoria;
  late DateTime _vencimento;

  @override
  void initState() {
    super.initState();
    final existente = widget.dividaExistente;
    _nomeCtrl = TextEditingController(text: existente?.nome ?? '');
    _valorCtrl = TextEditingController(
      text: existente != null ? existente.valorTotal.toStringAsFixed(2).replaceAll('.', ',') : '',
    );
    _parcelasCtrl = TextEditingController(text: (existente?.parcelasTotal ?? 1).toString());
    _jurosCtrl = TextEditingController(
      text: existente != null ? existente.taxaJuros.toString() : '0',
    );
    _vencimento = existente?.dataVencimento ?? DateTime.now().add(const Duration(days: 30));

    final provider = context.read<FinancasProvider>();
    final lista = provider.todasCategoriasDivida;
    _categoria = existente != null && lista.contains(existente.categoria) ? existente.categoria : lista.first;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinancasProvider>();
    final categoriasLista = provider.todasCategoriasDivida;

    return Scaffold(
      appBar: AppBar(title: Text(widget.editando ? 'Editar Dívida' : 'Nova Dívida')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nomeCtrl,
              decoration: const InputDecoration(labelText: 'Nome da dívida', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.isEmpty) ? 'Informe um nome' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valorCtrl,
              decoration: const InputDecoration(labelText: 'Valor total (R\$)', border: OutlineInputBorder()),
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
                    await context.read<FinancasProvider>().adicionarCategoriaDivida(nome);
                    setState(() => _categoria = nome);
                  }
                } else if (v != null) {
                  setState(() => _categoria = v);
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _parcelasCtrl,
                    decoration: const InputDecoration(labelText: 'Nº de parcelas', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _jurosCtrl,
                    decoration: const InputDecoration(labelText: 'Juros (% a.m.)', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Próximo vencimento'),
              subtitle: Text(
                '${_vencimento.day.toString().padLeft(2, '0')}/${_vencimento.month.toString().padLeft(2, '0')}/${_vencimento.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final nova = await showDatePicker(
                  context: context,
                  initialDate: _vencimento,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (nova != null) setState(() => _vencimento = nova);
              },
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
    final existente = widget.dividaExistente;
    final divida = Divida(
      id: existente?.id,
      nome: _nomeCtrl.text,
      valorTotal: double.parse(_valorCtrl.text.replaceAll(',', '.')),
      valorPago: existente?.valorPago ?? 0,
      dataVencimento: _vencimento,
      parcelasTotal: int.tryParse(_parcelasCtrl.text) ?? 1,
      parcelasPagas: existente?.parcelasPagas ?? 0,
      categoria: _categoria,
      taxaJuros: double.tryParse(_jurosCtrl.text.replaceAll(',', '.')) ?? 0,
    );
    if (widget.editando) {
      context.read<FinancasProvider>().atualizarDivida(divida);
    } else {
      context.read<FinancasProvider>().adicionarDivida(divida);
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _valorCtrl.dispose();
    _parcelasCtrl.dispose();
    _jurosCtrl.dispose();
    super.dispose();
  }
}
