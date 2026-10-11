import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/financas_provider.dart';
import '../utils/formatters.dart';

class AnaliseScreen extends StatefulWidget { const AnaliseScreen({super.key}); @override State<AnaliseScreen> createState()=>_AnaliseScreenState(); }
class _AnaliseScreenState extends State<AnaliseScreen> {
  DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);
  int _grafico = 0;
  final _meses = const ['Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'];

  @override Widget build(BuildContext context){
    final p=context.watch<FinancasProvider>();
    final receitas=p.receitasDoMes(_mes).fold(0.0,(s,t)=>s+t.valor);
    final despesasPagas=p.despesasDoMes(_mes).where((t)=>t.status.name=='paga').fold(0.0,(s,t)=>s+t.valor) + p.totalPagamentosDividasDoMes(_mes);
    final gastosTotais=despesasPagas;
    final dividas=p.dividasDoMes(_mes).where((d)=>d.valorRestante>0).fold(0.0,(s,d)=>s+d.valorRestante);
    final comprometimento=receitas>0?(gastosTotais/receitas)*100:0.0;
    final saldo=p.saldoMes(_mes);
    final categorias=p.despesasPorCategoriaDoMes(_mes);
    final problemas=p.problemasFinanceirosPara(_mes);

    return Scaffold(appBar:AppBar(title:const Text('Análise Financeira'),actions:[IconButton(icon:const Icon(Icons.calendar_month),tooltip:'Escolher mês',onPressed:_escolherMes)]),body:ListView(padding:const EdgeInsets.all(16),children:[
      Card(child:ListTile(leading:const Icon(Icons.calendar_month),title:Text('${_meses[_mes.month-1]} de ${_mes.year}',style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:const Text('A análise abaixo considera somente o mês selecionado.'),trailing:const Icon(Icons.chevron_right),onTap:_escolherMes)),
      const SizedBox(height:12),
      Row(children:[Expanded(child:_mini('Receitas',receitas,Colors.green)),const SizedBox(width:8),Expanded(child:_mini('Gastos',gastosTotais,Colors.red))]),
      Row(children:[Expanded(child:_mini('Dívidas abertas',dividas,Colors.orange)),const SizedBox(width:8),Expanded(child:_mini('Saldo previsto',p.saldoPrevisto(_mes),Colors.blue))]),
      Row(children:[Expanded(child:_mini('Saldo do mês',saldo,saldo>=0?Colors.green:Colors.red)),const SizedBox(width:8),Expanded(child:_mini('Saldo previsto',p.saldoPrevisto(_mes),Colors.blue))]),
      const SizedBox(height:12),
      Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Porcentagens',style:TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:10),Text('${comprometimento.toStringAsFixed(1)}% da renda foi comprometida por gastos, '),const SizedBox(height:8),Text('${(100-comprometimento).clamp(-100,100).toStringAsFixed(1)}% da renda ficou após as despesas'),const SizedBox(height:8),LinearProgressIndicator(value:(comprometimento/100).clamp(0,1).toDouble(),minHeight:10)]))),
      const SizedBox(height:20),
      Row(children:[const Expanded(child:Text('Gráficos',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold))),DropdownButton<int>(value:_grafico,items:const [DropdownMenuItem(value:0,child:Text('Categorias')),DropdownMenuItem(value:1,child:Text('Receitas x despesas'))],onChanged:(v){if(v!=null)setState(()=>_grafico=v);})]),
      const SizedBox(height:12),
      Card(child:Padding(padding:const EdgeInsets.all(12),child:_grafico==0?_pizza(categorias):_barras(receitas,gastosTotais))),
      const SizedBox(height:20),
      const Text('Pontos de atenção',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:8),
      ...problemas.map((x)=>Card(child:ListTile(leading:const Icon(Icons.insights,color:Colors.orange),title:Text(x)))),
    ]));
  }

  Widget _mini(String t,double v,Color c)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t,style:const TextStyle(fontSize:12,color:Colors.grey)),const SizedBox(height:4),Text(Formatters.formatarMoeda(v),style:TextStyle(fontWeight:FontWeight.bold,color:c))])));

  Widget _pizza(Map<String,double> dados){
    if(dados.isEmpty)return const SizedBox(height:220,child:Center(child:Text('Sem despesas para este mês.')));
    final total=dados.values.fold(0.0,(s,v)=>s+v);
    final entries=dados.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
    return Column(children:[
      SizedBox(height:230,child:PieChart(PieChartData(centerSpaceRadius:45,sectionsSpace:2,sections:List.generate(entries.length,(i){
        final e=entries[i];
        return PieChartSectionData(value:e.value,title:'${(e.value/total*100).toStringAsFixed(0)}%',radius:75,titleStyle:const TextStyle(fontWeight:FontWeight.bold,color:Colors.white));
      })))),
      const SizedBox(height:10),
      Wrap(spacing:12,runSpacing:8,children:entries.map((e)=>Text('${e.key}: ${Formatters.formatarMoeda(e.value)}')).toList()),
    ]);
  }
  Widget _barras(double r, double d) {
    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: r, width: 28)]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: d, width: 28)]),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(value == 0 ? 'Receitas' : 'Despesas'),
                ),
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }

  Future<void> _escolherMes()async{final d=await showDatePicker(context:context,initialDate:_mes,firstDate:DateTime(2000),lastDate:DateTime(2100),helpText:'Escolha um mês');if(d!=null)setState(()=>_mes=DateTime(d.year,d.month));}
}
