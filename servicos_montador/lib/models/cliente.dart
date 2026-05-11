class Cliente {
  int? id;
  String nome;
  String sobrenome;
  String endereco;
  double valor;
  DateTime dataAgendada;
  bool concluido;
  DateTime? dataConclusao;

  Cliente({
    this.id,
    required this.nome,
    required this.sobrenome,
    required this.endereco,
    required this.valor,
    required this.dataAgendada,
    this.concluido = false,
    this.dataConclusao,
  });

  // Converter para Map (para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'sobrenome': sobrenome,
      'endereco': endereco,
      'valor': valor,
      'dataAgendada': dataAgendada.millisecondsSinceEpoch,
      'concluido': concluido ? 1 : 0,
      'dataConclusao': dataConclusao?.millisecondsSinceEpoch,
    };
  }

  // Criar Cliente a partir de Map (para ler do banco)
  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'],
      nome: map['nome'],
      sobrenome: map['sobrenome'],
      endereco: map['endereco'],
      valor: map['valor'].toDouble(),
      dataAgendada: DateTime.fromMillisecondsSinceEpoch(map['dataAgendada']),
      concluido: map['concluido'] == 1,
      dataConclusao: map['dataConclusao'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dataConclusao'])
          : null,
    );
  }

  // Getter para nome completo
  String get nomeCompleto => '$nome $sobrenome';

  // Método para marcar como concluído
  void marcarConcluido() {
    concluido = true;
    dataConclusao = DateTime.now();
  }

  @override
  String toString() {
    return 'Cliente{id: $id, nome: $nome, sobrenome: $sobrenome, endereco: $endereco, valor: $valor, dataAgendada: $dataAgendada, concluido: $concluido}';
  }
}
