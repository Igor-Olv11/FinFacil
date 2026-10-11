import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/financas_provider.dart';
import 'screens/home_screen.dart';
import 'screens/receitas_screen.dart';
import 'screens/despesas_screen.dart';
import 'screens/dividas_screen.dart';
import 'screens/analise_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FinancasProvider()..inicializar(),
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return Selector<FinancasProvider, ThemeMode>(
      selector: (_, p) => p.themeMode,
      builder: (_, mode, _) => MaterialApp(
        title: 'FinanFacil',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF00695C), brightness: Brightness.light, visualDensity: VisualDensity.adaptivePlatformDensity, inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder())),
        darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF42A5A5), brightness: Brightness.dark, visualDensity: VisualDensity.adaptivePlatformDensity, inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder())),
        home: const TelaPrincipal(),
      ),
    );
  }
}

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});
  @override State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int _indiceAtual = 0;
  final List<Widget> _telas = const [HomeScreen(), ReceitasScreen(), DespesasScreen(), DividasScreen(), AnaliseScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _indiceAtual, children: _telas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceAtual,
        onDestinationSelected: (i) => setState(() => _indiceAtual = i),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.trending_up_outlined), selectedIcon: Icon(Icons.trending_up), label: 'Receitas'),
          NavigationDestination(icon: Icon(Icons.trending_down_outlined), selectedIcon: Icon(Icons.trending_down), label: 'Despesas'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Dívidas'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Análise'),
        ],
      ),
    );
  }
}
