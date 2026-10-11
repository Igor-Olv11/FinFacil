import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/financas_provider.dart';
import '../utils/formatters.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _salarioCtrl;
  late int _dia;

  @override
  void initState() {
    super.initState();
    final p = context.read<FinancasProvider>();
    _nomeCtrl = TextEditingController(text: p.nomeUsuario);
    _salarioCtrl = TextEditingController(text: p.salarioBase > 0 ? p.salarioBase.toStringAsFixed(2).replaceAll('.', ',') : '');
    _dia = p.salarioDiaRecebimento;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinancasProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 44)),
          const SizedBox(height: 24),
          TextFormField(controller: _nomeCtrl, decoration: const InputDecoration(labelText: 'Seu nome', border: OutlineInputBorder()), textCapitalization: TextCapitalization.words),
          const SizedBox(height: 16),
          TextFormField(
            controller: _salarioCtrl,
            decoration: const InputDecoration(labelText: 'Salário fixo mensal (R\$)', helperText: 'O salário entra no saldo somente quando chegar o dia de recebimento.', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) { final n = double.tryParse((v ?? '').replaceAll(',', '.')); return n == null || n < 0 ? 'Valor inválido' : null; },
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Data de recebimento do salário'),
            subtitle: Text('Todo mês, dia $_dia'),
            leading: const Icon(Icons.calendar_month),
            trailing: const Icon(Icons.edit_calendar),
            onTap: () async {
              final now = DateTime.now();
              final d = await showDatePicker(context: context, initialDate: DateTime(now.year, now.month, _dia.clamp(1, 28).toInt()), firstDate: DateTime(2000), lastDate: DateTime(2100), helpText: 'Escolha o dia do pagamento');
              if (d != null) setState(() => _dia = d.day);
            },
          ),
          if (p.salarioBase > 0) ...[
            const SizedBox(height: 8),
            Card(child: ListTile(
              leading: Icon(p.salarioRecebidoEsteMes ? Icons.check_circle : Icons.schedule, color: p.salarioRecebidoEsteMes ? Colors.green : Colors.orange),
              title: Text(p.salarioRecebidoEsteMes ? 'Salário deste mês já contabilizado' : 'Salário deste mês ainda não recebido'),
              subtitle: Text('Data prevista: ${Formatters.formatarData(p.dataSalarioEsteMes)}'),
            )),
          ],
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Aparência', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'sistema', icon: Icon(Icons.brightness_auto_outlined), label: Text('Sistema')),
                    ButtonSegment(value: 'claro', icon: Icon(Icons.light_mode_outlined), label: Text('Claro')),
                    ButtonSegment(value: 'escuro', icon: Icon(Icons.dark_mode_outlined), label: Text('Escuro')),
                  ],
                  selected: {p.tema},
                  onSelectionChanged: (v) => p.definirTema(v.first),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(child: ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Saldo atual'),
            subtitle: Text(Formatters.formatarMoeda(p.saldo)),
            trailing: const Icon(Icons.edit),
            onTap: () => _editarSaldo(context, p),
          )),
          Card(child: ListTile(
            leading: const Icon(Icons.calculate_outlined),
            title: const Text('Recalcular saldo pelos registros'),
            subtitle: Text('Saldo dos registros: ${Formatters.formatarMoeda(p.saldoBaseCalculado)}'),
            onTap: () async { await p.recalcularSaldo(); if (mounted) setState(() {}); },
          )),
          const SizedBox(height: 12),
          FilledButton(onPressed: _salvar, child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Salvar'))),
        ]),
      ),
    );
  }

  Future<void> _editarSaldo(BuildContext context, FinancasProvider p) async {
    final c = TextEditingController(text: p.saldo.toStringAsFixed(2).replaceAll('.', ','));
    await showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Editar saldo'),
      content: TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Saldo informado (R\$)')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), FilledButton(onPressed: () async { final v=double.tryParse(c.text.replaceAll(',','.')); if(v!=null){await p.editarSaldo(v);} if(ctx.mounted)Navigator.pop(ctx); }, child: const Text('Salvar'))],
    ));
    c.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final salario = double.tryParse(_salarioCtrl.text.replaceAll(',', '.')) ?? 0;
    await context.read<FinancasProvider>().salvarPerfil(nome: _nomeCtrl.text.trim(), salario: salario, diaRecebimento: _dia);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil salvo com sucesso!')));
    Navigator.pop(context);
  }
  @override void dispose() { _nomeCtrl.dispose(); _salarioCtrl.dispose(); super.dispose(); }
}
