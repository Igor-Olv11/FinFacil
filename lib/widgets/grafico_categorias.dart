import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/formatters.dart';

class GraficoCategorias extends StatelessWidget {
  final Map<String, double> dados;
  const GraficoCategorias({super.key, required this.dados});

  static const List<Color> _cores = [
    Colors.teal,
    Colors.orange,
    Colors.blue,
    Colors.purple,
    Colors.red,
    Colors.green,
    Colors.brown,
    Colors.indigo,
    Colors.pink,
  ];

  @override
  Widget build(BuildContext context) {
    final entradas = dados.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = dados.values.fold(0.0, (s, v) => s + v);

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sections: List.generate(entradas.length, (i) {
                final e = entradas[i];
                final pct = total > 0 ? (e.value / total) * 100 : 0.0;
                return PieChartSectionData(
                  value: e.value,
                  title: '${pct.toStringAsFixed(0)}%',
                  color: _cores[i % _cores.length],
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: List.generate(entradas.length, (i) {
            final e = entradas[i];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, color: _cores[i % _cores.length]),
                const SizedBox(width: 4),
                Text(
                  '${e.key}: ${Formatters.formatarMoeda(e.value)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
