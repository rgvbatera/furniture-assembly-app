import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cliente.dart';
import '../database/database_helper.dart';
import 'cadastro_cliente_screen.dart';
import '../services/pdf_service.dart';

class DetalhesClienteScreen extends StatefulWidget {
  final Cliente cliente;

  const DetalhesClienteScreen({super.key, required this.cliente});

  @override
  State<DetalhesClienteScreen> createState() => _DetalhesClienteScreenState();
}

class _DetalhesClienteScreenState extends State<DetalhesClienteScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  late Cliente _cliente;

  @override
  void initState() {
    super.initState();
    _cliente = widget.cliente;
  }

  Future<void> _marcarComoConcluido() async {
    try {
      await _databaseHelper.marcarClienteConcluido(_cliente.id!);
      final clienteAtualizado = await _databaseHelper.buscarClientePorId(_cliente.id!);
      if (clienteAtualizado != null) {
        setState(() {
          _cliente = clienteAtualizado;
        });
      }
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

  Future<void> _excluirCliente() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir o cliente ${_cliente.nomeCompleto}?'),
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
        await _databaseHelper.deletarCliente(_cliente.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cliente excluído com sucesso!')),
          );
          Navigator.pop(context, true);
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

  Future<void> _gerarNotaFiscal() async {
    try {
      final pdfService = PdfService();
      await pdfService.gerarNotaFiscal(_cliente);
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
    final isAtrasado = !_cliente.concluido && _cliente.dataAgendada.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(_cliente.nomeCompleto),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'editar':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CadastroClienteScreen(cliente: _cliente),
                    ),
                  ).then((resultado) async {
                    if (resultado == true) {
                      final clienteAtualizado = await _databaseHelper.buscarClientePorId(_cliente.id!);
                      if (clienteAtualizado != null) {
                        setState(() {
                          _cliente = clienteAtualizado;
                        });
                      }
                    }
                  });
                  break;
                case 'excluir':
                  _excluirCliente();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'editar',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excluir',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _cliente.concluido
                          ? Colors.green
                          : isAtrasado
                              ? Colors.red
                              : Colors.blue,
                      child: Icon(
                        _cliente.concluido
                            ? Icons.check
                            : isAtrasado
                                ? Icons.warning
                                : Icons.person,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _cliente.concluido
                                ? 'Serviço Concluído'
                                : isAtrasado
                                    ? 'Serviço Atrasado'
                                    : 'Serviço Pendente',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _cliente.concluido
                                  ? Colors.green
                                  : isAtrasado
                                      ? Colors.red
                                      : Colors.blue,
                            ),
                          ),
                          if (_cliente.concluido && _cliente.dataConclusao != null)
                            Text(
                              'Concluído em ${DateFormat('dd/MM/yyyy HH:mm').format(_cliente.dataConclusao!)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            )
                          else
                            Text(
                              'Agendado para ${DateFormat('dd/MM/yyyy HH:mm').format(_cliente.dataAgendada)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dados do Cliente
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dados do Cliente',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.person, 'Nome', _cliente.nome),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.person_outline, 'Sobrenome', _cliente.sobrenome),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.location_on, 'Endereço', _cliente.endereco),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Informações do Serviço
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informações do Serviço',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.attach_money,
                      'Valor',
                      'R\$ ${_cliente.valor.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Data Agendada',
                      DateFormat('dd/MM/yyyy').format(_cliente.dataAgendada),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.access_time,
                      'Horário',
                      DateFormat('HH:mm').format(_cliente.dataAgendada),
                    ),
                    if (_cliente.concluido && _cliente.dataConclusao != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.check_circle,
                        'Data de Conclusão',
                        DateFormat('dd/MM/yyyy HH:mm').format(_cliente.dataConclusao!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botões de Ação
            if (!_cliente.concluido) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _marcarComoConcluido,
                  icon: const Icon(Icons.check),
                  label: const Text('Marcar como Concluído'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (_cliente.concluido) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _gerarNotaFiscal,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Gerar Nota Fiscal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CadastroClienteScreen(cliente: _cliente),
                        ),
                      ).then((resultado) async {
                        if (resultado == true) {
                          final clienteAtualizado = await _databaseHelper.buscarClientePorId(_cliente.id!);
                          if (clienteAtualizado != null) {
                            setState(() {
                              _cliente = clienteAtualizado;
                            });
                          }
                        }
                      });
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _excluirCliente,
                    icon: const Icon(Icons.delete),
                    label: const Text('Excluir'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
