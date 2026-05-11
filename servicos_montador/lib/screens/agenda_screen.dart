import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cliente.dart';
import '../database/database_helper.dart';
import 'cadastro_cliente_screen.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  DateTime _dataSelecionada = DateTime.now();
  List<Cliente> _clientesDoDia = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarClientesDoDia();
  }

  Future<void> _carregarClientesDoDia() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final clientes = await _databaseHelper.buscarClientesPorData(_dataSelecionada);
      setState(() {
        _clientesDoDia = clientes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar agenda: $e')),
        );
      }
    }
  }

  Future<void> _selecionarData() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null && picked != _dataSelecionada) {
      setState(() {
        _dataSelecionada = picked;
      });
      _carregarClientesDoDia();
    }
  }

  Future<void> _marcarComoConcluido(Cliente cliente) async {
    try {
      await _databaseHelper.marcarClienteConcluido(cliente.id!);
      _carregarClientesDoDia();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serviço marcado como concluído!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao marcar como concluído: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final isHoje = _dataSelecionada.year == hoje.year &&
        _dataSelecionada.month == hoje.month &&
        _dataSelecionada.day == hoje.day;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          IconButton(
            onPressed: _selecionarData,
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Selecionar Data',
          ),
        ],
      ),
      body: Column(
        children: [
          // Cabeçalho da data
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(26),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('EEEE, dd \'de\' MMMM \'de\' yyyy', 'pt_BR')
                      .format(_dataSelecionada),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isHoje) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'HOJE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      '${_clientesDoDia.length} agendamento${_clientesDoDia.length != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Lista de agendamentos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _clientesDoDia.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _carregarClientesDoDia,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _clientesDoDia.length,
                          itemBuilder: (context, index) {
                            final cliente = _clientesDoDia[index];
                            return _buildAgendamentoCard(cliente);
                          },
                        ),
                      ),
          ),
        ],
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
            _carregarClientesDoDia();
          }
        },
        tooltip: 'Novo Agendamento',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum agendamento',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Não há agendamentos para esta data',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final resultado = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CadastroClienteScreen(),
                ),
              );
              if (resultado == true) {
                _carregarClientesDoDia();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Novo Agendamento'),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendamentoCard(Cliente cliente) {
    final agora = DateTime.now();
    final isAtrasado = !cliente.concluido && cliente.dataAgendada.isBefore(agora);
    final isProximo = !cliente.concluido &&
        cliente.dataAgendada.isAfter(agora) &&
        cliente.dataAgendada.difference(agora).inHours < 2;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: cliente.concluido
                        ? Colors.green
                        : isAtrasado
                            ? Colors.red
                            : isProximo
                                ? Colors.orange
                                : Colors.blue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            DateFormat('HH:mm').format(cliente.dataAgendada),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cliente.concluido
                                  ? Colors.green
                                  : isAtrasado
                                      ? Colors.red
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (cliente.concluido)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'CONCLUÍDO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            )
                          else if (isAtrasado)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'ATRASADO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            )
                          else if (isProximo)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'PRÓXIMO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cliente.nomeCompleto,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        cliente.endereco,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R\$ ${cliente.valor.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    if (!cliente.concluido) ...[
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _marcarComoConcluido(cliente),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(80, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text(
                          'Concluir',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}