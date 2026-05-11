import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/cliente.dart';
import '../database/database_helper.dart';
import 'cadastro_cliente_screen.dart';
import 'lista_clientes_screen.dart';
import 'agenda_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Cliente> _clientesHoje = [];
  List<Cliente> _clientesPendentes = [];
  Map<int, double> _lucroSemanal = {};
  Map<int, double> _lucroMensal = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final hoje = DateTime.now();
      final clientesHoje = await _databaseHelper.buscarClientesPorData(hoje);
      final clientesPendentes = await _databaseHelper.buscarClientesPendentes();
      final lucroSemanal = await _calcularLucroSemanal();
      final lucroMensal = await _calcularLucroMensal();

      setState(() {
        _clientesHoje = clientesHoje;
        _clientesPendentes = clientesPendentes;
        _lucroSemanal = lucroSemanal;
        _lucroMensal = lucroMensal;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    }
  }

  Future<Map<int, double>> _calcularLucroSemanal() async {
    final hoje = DateTime.now();
    final inicioSemana = hoje.subtract(Duration(days: hoje.weekday - 1));
    final fimSemana = inicioSemana.add(const Duration(days: 6));

    final clientes = await _databaseHelper.buscarClientesConcluidosPorPeriodo(
      DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day),
      DateTime(fimSemana.year, fimSemana.month, fimSemana.day, 23, 59),
    );

    final Map<int, double> dados = {for (var i = 1; i <= 7; i++) i: 0.0};

    for (var cliente in clientes) {
      final diaDaSemana = cliente.dataConclusao!.weekday;
      dados[diaDaSemana] = (dados[diaDaSemana] ?? 0) + cliente.valor;
    }
    return dados;
  }

  Future<Map<int, double>> _calcularLucroMensal() async {
    final hoje = DateTime.now();
    final inicioMes = DateTime(hoje.year, hoje.month, 1);
    final fimMes = DateTime(hoje.year, hoje.month + 1, 0, 23, 59);

    final clientes = await _databaseHelper.buscarClientesConcluidosPorPeriodo(
      inicioMes,
      fimMes,
    );

    final Map<int, double> dados = {
      for (var i = 1; i <= fimMes.day; i++) i: 0.0,
    };

    for (var cliente in clientes) {
      final diaDoMes = cliente.dataConclusao!.day;
      dados[diaDoMes] = (dados[diaDoMes] ?? 0) + cliente.valor;
    }

    // Para simplificar, vamos agrupar por semanas do mês
    // Esta parte pode ser mais elaborada se necessário
    return dados;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Serviços de Montagem'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumo do dia
                    _buildResumoCard(),
                    const SizedBox(height: 20),

                    // Botões de ação
                    _buildBotoesAcao(),
                    const SizedBox(height: 20),

                    // Gráfico de Lucros
                    _buildGraficoLucros(),
                    const SizedBox(height: 20),

                    // Agendamentos de hoje
                    _buildAgendamentosHoje(),
                    const SizedBox(height: 20),

                    // Próximos agendamentos
                    _buildProximosAgendamentos(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CadastroClienteScreen(),
            ),
          );
          if (resultado == true) {
            _carregarDados();
          }
        },
        tooltip: 'Novo Cliente',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildResumoCard() {
    final totalPendentes = _clientesPendentes.length;
    final agendamentosHoje = _clientesHoje.length;
    final valorTotalHoje = _clientesHoje.fold<double>(
      0.0,
      (sum, cliente) => sum + cliente.valor,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildResumoItem(
                    'Hoje',
                    agendamentosHoje.toString(),
                    Icons.today,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildResumoItem(
                    'Pendentes',
                    totalPendentes.toString(),
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildResumoItem(
                    'Valor Hoje',
                    'R\$ ${valorTotalHoje.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoItem(
    String titulo,
    String valor,
    IconData icone,
    Color cor,
  ) {
    return Column(
      children: [
        Icon(icone, color: cor, size: 32),
        const SizedBox(height: 8),
        Text(
          valor,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
        Text(
          titulo,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBotoesAcao() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ListaClientesScreen(),
                ),
              ).then((_) => _carregarDados());
            },
            icon: const Icon(Icons.list),
            label: const Text('Ver Clientes'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AgendaScreen()),
              ).then((_) => _carregarDados());
            },
            icon: const Icon(Icons.calendar_today),
            label: const Text('Agenda'),
          ),
        ),
      ],
    );
  }

  Widget _buildGraficoLucros() {
    return Card(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Lucro Semanal'),
                Tab(text: 'Lucro Mensal'),
              ],
            ),
            SizedBox(
              height: 250,
              child: TabBarView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildGraficoBarra(_lucroSemanal, true),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildGraficoBarra(_lucroMensal, false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoBarra(Map<int, double> dados, bool isSemanal) {
    if (dados.values.every((v) => v == 0)) {
      return Center(
        child: Text(
          'Nenhum dado de lucro para este período.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    final maxY = dados.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final valor = rod.toY;
              return BarTooltipItem(
                'R\$ ${valor.toStringAsFixed(2)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) =>
                  _getTituloEixoX(value, isSemanal),
              reservedSize: 38,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == maxY) return const SizedBox.shrink();
                return Text(
                  '${(value / 1000).toStringAsFixed(0)}k',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: dados.entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: Colors.blue,
                width: isSemanal ? 16 : 5,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
      ),
    );
  }

  Widget _getTituloEixoX(double value, bool isSemanal) {
    const style = TextStyle(fontSize: 10);
    if (isSemanal) {
      switch (value.toInt()) {
        case 1:
          return const Text('Seg', style: style);
        case 2:
          return const Text('Ter', style: style);
        case 3:
          return const Text('Qua', style: style);
        case 4:
          return const Text('Qui', style: style);
        case 5:
          return const Text('Sex', style: style);
        case 6:
          return const Text('Sáb', style: style);
        case 7:
          return const Text('Dom', style: style);
        default:
          return const SizedBox.shrink();
      }
    } else {
      // Mostra apenas alguns dias do mês para não poluir
      if (value.toInt() % 5 == 1 || value.toInt() == 31) {
        return Text(value.toInt().toString(), style: style);
      }
      return const SizedBox.shrink();
    }
  }

  Widget _buildAgendamentosHoje() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Agendamentos de Hoje',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_clientesHoje.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  const Text('Nenhum agendamento para hoje'),
                ],
              ),
            ),
          )
        else
          ...(_clientesHoje
              .take(3)
              .map((cliente) => _buildClienteCard(cliente))),
        if (_clientesHoje.length > 3)
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AgendaScreen()),
              ).then((_) => _carregarDados());
            },
            child: Text('Ver todos (${_clientesHoje.length})'),
          ),
      ],
    );
  }

  Widget _buildProximosAgendamentos() {
    final proximosAgendamentos = _clientesPendentes
        .where((cliente) => !_isSameDay(cliente.dataAgendada, DateTime.now()))
        .take(3)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Próximos Agendamentos',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (proximosAgendamentos.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  const Text('Nenhum agendamento futuro'),
                ],
              ),
            ),
          )
        else
          ...(proximosAgendamentos.map(
            (cliente) => _buildClienteCard(cliente),
          )),
      ],
    );
  }

  Widget _buildClienteCard(Cliente cliente) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cliente.concluido ? Colors.green : Colors.blue,
          child: Icon(
            cliente.concluido ? Icons.check : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(cliente.nomeCompleto),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cliente.endereco),
            Text(
              'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(cliente.dataAgendada)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Text(
          'R\$ ${cliente.valor.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        onTap: () {
          // Navegar para detalhes do cliente
        },
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
