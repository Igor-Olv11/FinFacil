import 'package:flutter/material.dart';

const List<String> categoriasReceita = [
  'Salário',
  'Freelance',
  'Investimentos',
  'Vendas',
  'Outros',
];

const List<String> categoriasDespesa = [
  'Moradia',
  'Alimentação',
  'Transporte',
  'Saúde',
  'Lazer',
  'Educação',
  'Assinaturas',
  'Contas',
  'Outros',
];

const List<String> categoriasDivida = [
  'Cartão de Crédito',
  'Empréstimo',
  'Financiamento',
  'Cheque Especial',
  'Outros',
];

const String opcaoNovaCategoria = '__nova_categoria__';

final Map<String, IconData> iconesCategorias = {
  'Salário': Icons.work,
  'Freelance': Icons.laptop_mac,
  'Investimentos': Icons.trending_up,
  'Vendas': Icons.sell,
  'Moradia': Icons.home,
  'Alimentação': Icons.restaurant,
  'Transporte': Icons.directions_car,
  'Saúde': Icons.local_hospital,
  'Lazer': Icons.sports_esports,
  'Educação': Icons.school,
  'Assinaturas': Icons.subscriptions,
  'Contas': Icons.receipt_long,
  'Cartão de Crédito': Icons.credit_card,
  'Empréstimo': Icons.account_balance,
  'Financiamento': Icons.house,
  'Cheque Especial': Icons.warning_amber,
  'Outros': Icons.category,
};

/// Mostra um dialogo para o usuário digitar o nome de uma nova categoria.
/// Retorna o nome digitado (sem espaços nas pontas) ou null se cancelado.
Future<String?> mostrarDialogNovaCategoria(BuildContext context) async {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Nova categoria'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Nome da categoria',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final nome = ctrl.text.trim();
            if (nome.isNotEmpty) Navigator.pop(ctx, nome);
          },
          child: const Text('Adicionar'),
        ),
      ],
    ),
  );
}
