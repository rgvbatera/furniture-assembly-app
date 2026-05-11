import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cliente.dart';
import '../database/database_helper.dart';
import 'cadastro_cliente_screen.dart';
import 'detalhes_cliente_screen.dart';
import '../services/pdf_service.dart';

class ListaClientesScreen extends StatefulWidget {
  const ListaClientesScreen({super.key});

  @override
  State<ListaClientesScreen> createState() => _ListaClientesScreenState();
}

class _ListaClientesScreenState extends State<ListaClientesScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  late TabController _tabController;
  List<Cliente> _clientesPendentes = [];
  List<Cliente> _clientesConcluidos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarClientes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarClientes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pendentes = await _databaseHelper.buscarClientesPendentes();
      final concluidos = await _databaseHelper.buscarClientesConcluidos();

      setState(() {
        _clientesPendentes = pendentes;
        _clientesConcluidos = concluidos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar clientes: $e')),
        );
      }
    }
  }

  Future<void> _marcarComoConcluido(Cliente cliente) async {
    try {
      await _databaseHelper.marcarClienteConcluido(cliente.id!);
      _carregarClientes();
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

  Future<void> _excluirCliente(Cliente cliente) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Deseja realmente excluir o cliente ${cliente.nomeCompleto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _databaseHelper.deletarCliente(cliente.id!);
        _carregarClientes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cliente excluído com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir cliente: $e')),
          );
        }
      }
    }
  }

  Future<void> _gerarNotaFiscal(Cliente cliente) async {
    try {
      final pdfService = PdfService();
      await pdfService.gerarNotaFiscal(cliente);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota fiscal gerada com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar nota fiscal: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Pendentes (${_clientesPendentes.length})',
              icon: const Icon(Icons.pending_actions),
            ),
            Tab(
              text: 'Concluídos (${_clientesConcluidos.length})',
              icon: const Icon(Icons.check_circle),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListaClientes(_clientesPendentes, false),
                _buildListaClientes(_clientesConcluidos, true),
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
            _carregarClientes();
          }
        },
        tooltip: 'Novo Cliente',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListaClientes(List<Cliente> clientes, bool concluidos) {
    if (clientes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              concluidos ? Icons.check_circle_outline : Icons.pending_actions,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              concluidos
                  ? 'Nenhum serviço concluído'
                  : 'Nenhum serviço pendente',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              concluidos
                  ? 'Os serviços concluídos aparecerão aqui'
                  : 'Adicione um novo cliente para começar',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarClientes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: clientes.length,
        itemBuilder: (context, index) {
          final cliente = clientes[index];
          return _buildClienteCard(cliente, concluidos);
        },
      ),
    );
  }

  Widget _buildClienteCard(Cliente cliente, bool concluido) {
    final isAtrasado =
        !concluido && cliente.dataAgendada.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalhesClienteScreen(cliente: cliente),
            ),
          ).then((_) => _carregarClientes());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: concluido
                        ? Colors.green
                        : isAtrasado
                        ? Colors.red
                        : Colors.blue,
                    child: Icon(
                      concluido
                          ? Icons.check
                          : isAtrasado
                          ? Icons.warning
                          : Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.nomeCompleto,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          cliente.endereco,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'R\$ ${cliente.valor.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Agendado: ${DateFormat('dd/MM/yyyy HH:mm').format(cliente.dataAgendada)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isAtrasado ? Colors.red : Colors.grey[600],
                    ),
                  ),
                  if (isAtrasado) ...[
                    const SizedBox(width: 8),
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
                    ),
                  ],
                ],
              ),
              if (concluido && cliente.dataConclusao != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Concluído: ${DateFormat('dd/MM/yyyy HH:mm').format(cliente.dataConclusao!)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.green[600]),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!concluido) ...[
                    TextButton.icon(
                      onPressed: () => _marcarComoConcluido(cliente),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Concluir'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (concluido) ...[
                    TextButton.icon(
                      onPressed: () => _gerarNotaFiscal(cliente),
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('Nota Fiscal'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton.icon(
                    onPressed: () async {
                      final resultado = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CadastroClienteScreen(cliente: cliente),
                        ),
                      );
                      if (resultado == true) {
                        _carregarClientes();
                      }
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _excluirCliente(cliente),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Excluir'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
