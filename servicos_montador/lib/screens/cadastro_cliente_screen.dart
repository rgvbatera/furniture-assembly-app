import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/cliente.dart';
import '../database/database_helper.dart';

class CadastroClienteScreen extends StatefulWidget {
  final Cliente? cliente;

  const CadastroClienteScreen({super.key, this.cliente});

  @override
  State<CadastroClienteScreen> createState() => _CadastroClienteScreenState();
}

class _CadastroClienteScreenState extends State<CadastroClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _sobrenomeController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _valorController = TextEditingController();
  final _dataController = TextEditingController();
  final _horaController = TextEditingController();

  DateTime? _dataSelecionada;
  TimeOfDay? _horaSelecionado;
  bool _isLoading = false;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    if (widget.cliente != null) {
      _preencherCampos();
    }
  }

  void _preencherCampos() {
    final cliente = widget.cliente!;
    _nomeController.text = cliente.nome;
    _sobrenomeController.text = cliente.sobrenome;
    _enderecoController.text = cliente.endereco;
    _valorController.text = cliente.valor.toStringAsFixed(2);
    _dataSelecionada = cliente.dataAgendada;
    _horaSelecionado = TimeOfDay.fromDateTime(cliente.dataAgendada);
    _dataController.text = DateFormat('dd/MM/yyyy').format(cliente.dataAgendada);
    _horaController.text = DateFormat('HH:mm').format(cliente.dataAgendada);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _sobrenomeController.dispose();
    _enderecoController.dispose();
    _valorController.dispose();
    _dataController.dispose();
    _horaController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null && picked != _dataSelecionada) {
      setState(() {
        _dataSelecionada = picked;
        _dataController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selecionarHora() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaSelecionado ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _horaSelecionado) {
      setState(() {
        _horaSelecionado = picked;
        _horaController.text = picked.format(context);
      });
    }
  }

  Future<void> _adicionarEventoCalendario(Cliente cliente) async {
    // Funcionalidade de calendário será implementada em versão futura
    // Por enquanto, apenas salva no banco de dados local
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agendamento salvo! Funcionalidade de calendário será adicionada em breve.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Silenciosamente ignora erros de calendário por enquanto
    }
  }

  Future<void> _salvarCliente() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dataSelecionada == null || _horaSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione data e hora')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dataAgendada = DateTime(
        _dataSelecionada!.year,
        _dataSelecionada!.month,
        _dataSelecionada!.day,
        _horaSelecionado!.hour,
        _horaSelecionado!.minute,
      );

      final cliente = Cliente(
        id: widget.cliente?.id,
        nome: _nomeController.text.trim(),
        sobrenome: _sobrenomeController.text.trim(),
        endereco: _enderecoController.text.trim(),
        valor: double.parse(_valorController.text.replaceAll(',', '.')),
        dataAgendada: dataAgendada,
        concluido: widget.cliente?.concluido ?? false,
        dataConclusao: widget.cliente?.dataConclusao,
      );

      if (widget.cliente == null) {
        await _databaseHelper.inserirCliente(cliente);
        // Adicionar ao calendário do dispositivo
        await _adicionarEventoCalendario(cliente);
      } else {
        await _databaseHelper.atualizarCliente(cliente);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.cliente == null
                  ? 'Cliente cadastrado com sucesso!'
                  : 'Cliente atualizado com sucesso!',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar cliente: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cliente == null ? 'Novo Cliente' : 'Editar Cliente'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _salvarCliente,
              icon: const Icon(Icons.save),
              tooltip: 'Salvar',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome *',
                          prefixIcon: Icon(Icons.person),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, informe o nome';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sobrenomeController,
                        decoration: const InputDecoration(
                          labelText: 'Sobrenome *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, informe o sobrenome';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _enderecoController,
                        decoration: const InputDecoration(
                          labelText: 'Endereço *',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        textCapitalization: TextCapitalization.words,
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, informe o endereço';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Agendamento',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _valorController,
                        decoration: const InputDecoration(
                          labelText: 'Valor do Serviço *',
                          prefixIcon: Icon(Icons.attach_money),
                          prefixText: 'R\$ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, informe o valor';
                          }
                          final valor = double.tryParse(value.replaceAll(',', '.'));
                          if (valor == null || valor <= 0) {
                            return 'Por favor, informe um valor válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _dataController,
                              decoration: const InputDecoration(
                                labelText: 'Data *',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              onTap: _selecionarData,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Selecione a data';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _horaController,
                              decoration: const InputDecoration(
                                labelText: 'Hora *',
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              readOnly: true,
                              onTap: _selecionarHora,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Selecione a hora';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _salvarCliente,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    widget.cliente == null ? 'Cadastrar Cliente' : 'Atualizar Cliente',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
