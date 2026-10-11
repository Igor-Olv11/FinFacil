import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class CardResumo extends StatelessWidget {
  final String titulo;
  final double valor;
  final Color cor;
  final IconData icone;
  final bool largo;

  const CardResumo({
    super.key,
    required this.titulo,
    required this.valor,
    required this.cor,
    required this.icone,
    this.largo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icone, color: cor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  Text(
                    Formatters.formatarMoeda(valor),
                    style: TextStyle(
                      fontSize: largo ? 20 : 16,
                      fontWeight: FontWeight.bold,
                      color: cor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
